use crate::api::models::SpectrumTrackMetadata;
use futures::stream::{self, StreamExt};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpotifyPlaylist {
    pub id: String,
    pub name: String,
    pub artwork_url: Option<String>,
    pub track_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpotifySyncResult {
    pub tracks: Vec<SpectrumTrackMetadata>,
    pub playlists: Vec<SpotifyPlaylist>,
    pub liked_track_ids: Vec<String>,
}

#[derive(Deserialize)]
struct SpotifyPlaylistResponse {
    items: Vec<serde_json::Value>,
    next: Option<String>,
}

#[derive(Deserialize)]
struct SpotifyTrackResponse {
    items: Vec<serde_json::Value>,
    next: Option<String>,
}

pub async fn sync_spotify_library(token: String) -> anyhow::Result<SpotifySyncResult> {
    let client = reqwest::Client::new();
    let auth_header = format!("Bearer {}", token);

    // 1. Fetch Liked Songs (Paginated)
    let mut all_tracks = Vec::new();
    let mut liked_track_ids = Vec::new();
    let mut next_url = Some("https://api.spotify.com/v1/me/tracks?limit=50&market=from_token".to_string());

    while let Some(url) = next_url {
        let resp = client
            .get(&url)
            .header("Authorization", &auth_header)
            .send()
            .await?
            .json::<SpotifyTrackResponse>()
            .await?;

        for item in resp.items {
            if let Some(track_data) = item.get("track") {
                if let Some(track) = parse_spotify_track(track_data) {
                    liked_track_ids.push(track.id.clone());
                    all_tracks.push(track);
                }
            }
        }
        next_url = resp.next;
    }

    // 2. Fetch User Playlists
    let mut playlists = Vec::new();
    let mut next_p_url = Some("https://api.spotify.com/v1/me/playlists?limit=50".to_string());

    while let Some(url) = next_p_url {
        let resp = client
            .get(&url)
            .header("Authorization", &auth_header)
            .send()
            .await?
            .json::<SpotifyPlaylistResponse>()
            .await?;

        for item in resp.items {
            let p_id = item["id"].as_str().unwrap_or_default().to_string();
            let p_name = item["name"].as_str().unwrap_or_default().to_string();
            let artwork = item["images"]
                .as_array()
                .and_then(|imgs| imgs.first())
                .and_then(|img| img["url"].as_str())
                .map(|s| s.to_string());

            playlists.push(SpotifyPlaylist {
                id: p_id,
                name: p_name,
                artwork_url: artwork,
                track_ids: Vec::new(),
            });
        }
        next_p_url = resp.next;
    }

    // 3. Fetch Tracks for all Playlists IN PARALLEL (Concurrency: 5)
    let mut playlist_tasks = stream::iter(playlists)
        .map(|mut playlist| {
            let client = client.clone();
            let auth_header = auth_header.clone();
            async move {
                let mut next_url = Some(format!(
                    "https://api.spotify.com/v1/playlists/{}/tracks?limit=50&market=from_token",
                    playlist.id
                ));
                let mut p_tracks = Vec::new();

                while let Some(url) = next_url {
                    let resp = match client
                        .get(&url)
                        .header("Authorization", &auth_header)
                        .send()
                        .await
                    {
                        Ok(r) => match r.json::<SpotifyTrackResponse>().await {
                            Ok(json) => json,
                            Err(_) => break,
                        },
                        Err(_) => break,
                    };

                    for item in resp.items {
                        if let Some(track_data) = item.get("track") {
                            if let Some(track) = parse_spotify_track(track_data) {
                                playlist.track_ids.push(track.id.clone());
                                p_tracks.push(track);
                            }
                        }
                    }
                    next_url = resp.next;
                }
                (playlist, p_tracks)
            }
        })
        .buffer_unordered(5);

    let mut final_playlists = Vec::new();
    while let Some((playlist, p_tracks)) = playlist_tasks.next().await {
        final_playlists.push(playlist);
        all_tracks.extend(p_tracks);
    }

    // 4. Deduplicate tracks by ID
    let mut seen = std::collections::HashSet::new();
    all_tracks.retain(|t| seen.insert(t.id.clone()));

    Ok(SpotifySyncResult {
        tracks: all_tracks,
        playlists: final_playlists,
        liked_track_ids,
    })
}

fn parse_spotify_track(data: &serde_json::Value) -> Option<SpectrumTrackMetadata> {
    let id = data["id"].as_str()?.to_string();
    let title = data["name"].as_str()?.to_string();
    let artist = data["artists"]
        .as_array()
        .and_then(|arr| arr.first())
        .and_then(|a| a["name"].as_str())
        .unwrap_or("Unknown Artist")
        .to_string();
    let duration_ms = data["duration_ms"].as_i64().unwrap_or(0);
    let artwork = data["album"]["images"]
        .as_array()
        .and_then(|imgs| imgs.first())
        .and_then(|img| img["url"].as_str())
        .map(|s| s.to_string());

    Some(SpectrumTrackMetadata {
        id,
        title,
        artist,
        duration_ms,
        artwork_url: artwork,
        source: "spotify".to_string(),
        local_path: None,
        dominant_color: None,
        blur_hash_path: None,
    })
}
