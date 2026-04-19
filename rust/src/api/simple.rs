use reqwest::Client;
use std::time::Duration;
use futures::future::{select_all, BoxFuture};
use regex::Regex;
use serde_json::Value;
use crate::api::models::SpectrumTrackMetadata;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub async fn resolve_youtube_stream(video_id: String) -> Option<String> {
    let client = Client::builder()
        .timeout(Duration::from_secs(10))
        .user_agent("Spectrum/1.0 (Rust-Core)")
        .build()
        .ok()?;

    let mut tasks: Vec<BoxFuture<Option<String>>> = Vec::new();

    // Strategy 1: VPS Proxy
    let v_id = video_id.clone();
    let cl = client.clone();
    tasks.push(Box::pin(async move {
        let url = format!("http://144.31.26.207:3001/api/stream/{}", v_id);
        match cl.get(&url).timeout(Duration::from_secs(5)).send().await {
            Ok(resp) if resp.status().is_success() => Some(url),
            _ => None,
        }
    }));

    // Strategy 2: Piped API (Parallelized)
    let v_id = video_id.clone();
    let cl = client.clone();
    tasks.push(Box::pin(async move {
        let instances = vec![
            "https://pipedapi.kavin.rocks",
            "https://pipedapi.adminforge.de",
            "https://api.piped.projectsegfau.lt",
            "https://pipedapi.leptons.xyz",
            "https://pipedapi.rivo.org",
        ];
        
        let mut sub_tasks = Vec::new();
        for instance in instances {
            let cl = cl.clone();
            let v_id = v_id.clone();
            sub_tasks.push(Box::pin(async move {
                let url = format!("{}/streams/{}", instance, v_id);
                if let Ok(resp) = cl.get(&url).send().await {
                    if let Ok(data) = resp.json::<Value>().await {
                        if let Some(audio_streams) = data.get("audioStreams").and_then(|v| v.as_array()) {
                            if let Some(best) = audio_streams.first().and_then(|s| s.get("url")).and_then(|u| u.as_str()) {
                                return Some(best.to_string());
                            }
                        }
                    }
                }
                None
            }) as BoxFuture<Option<String>>);
        }

        let mut remaining = sub_tasks;
        while !remaining.is_empty() {
            let (result, _, next) = select_all(remaining).await;
            if let Some(url) = result {
                return Some(url);
            }
            remaining = next;
        }
        None
    }));
    
    let mut remaining_tasks = tasks;
    while !remaining_tasks.is_empty() {
        let (result, _index, next_tasks) = select_all(remaining_tasks).await;
        if let Some(url) = result {
            return Some(url);
        }
        remaining_tasks = next_tasks;
    }

    None
}

pub async fn resolve_soundcloud_stream(query: String, expected_duration_ms: Option<i64>) -> Option<String> {
    let client = Client::builder()
        .timeout(Duration::from_secs(15))
        .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        .build()
        .ok()?;

    // 1. Extract client_id
    let client_id = match get_sc_client_id(&client).await {
        Some(id) => id,
        None => "tkIWLs4MIowq7bCXP80TOwx6DnDa7UPc".to_string(), // Fallback
    };

    // 2. Search tracks
    let url = "https://api-v2.soundcloud.com/search/tracks";
    let resp = client.get(url)
        .query(&[
            ("q", query.as_str()),
            ("client_id", client_id.as_str()),
            ("limit", "10")
        ])
        .send()
        .await
        .ok()?;

    let data: Value = resp.json().await.ok()?;
    let collection = data.get("collection")?.as_array()?;

    let mut candidates: Vec<(i32, String)> = Vec::new();

    for item in collection {
        let title = item.get("title").and_then(|v| v.as_str()).unwrap_or("");
        let artist = item.get("user").and_then(|u| u.get("username")).and_then(|v| v.as_str()).unwrap_or("");
        let duration = item.get("duration").and_then(|d| d.as_i64()).unwrap_or(0);
        
        // Duration filter (within 15s)
        if let Some(expected) = expected_duration_ms {
            if (duration - expected).abs() > 15000 {
                continue;
            }
        }

        // Scoring Logic
        let mut score = 0;
        let q_lower = query.to_lowercase();
        let t_lower = title.to_lowercase();
        let a_lower = artist.to_lowercase();

        // Penalize remixes/edits if not specifically requested
        let penalties = ["remix", "edit", "sped up", "speed up", "slowed", "reverb", "cover", "bootleg", "nightcore"];
        for p in penalties {
            if t_lower.contains(p) && !q_lower.contains(p) {
                score -= 100;
            }
        }

        // Boost score if artist matches
        if q_lower.contains(&a_lower) || a_lower.contains(&q_lower) {
            score += 50;
        }

        let transcodings = item.get("media").and_then(|m| m.get("transcodings")).and_then(|t| t.as_array());
        if let Some(transcodings) = transcodings {
            // Prefer progressive mp3
            let best_transcoding = transcodings.iter()
                .find(|t| {
                    t.get("format")
                        .and_then(|f| f.get("protocol"))
                        .and_then(|p| p.as_str()) == Some("progressive")
                })
                .or_else(|| transcodings.first());

            if let Some(bt) = best_transcoding {
                if let Some(media_url) = bt.get("url").and_then(|u| u.as_str()) {
                    // 3. Get actual stream URL
                    if let Ok(stream_resp) = client.get(media_url)
                        .query(&[("client_id", client_id.as_str())])
                        .send()
                        .await 
                    {
                        if let Ok(stream_data) = stream_resp.json::<Value>().await {
                            if let Some(final_url) = stream_data.get("url").and_then(|u| u.as_str()) {
                                candidates.push((score, final_url.to_string()));
                                if score >= 0 { break; } // Optimal match found, stop early to save time
                            }
                        }
                    }
                }
            }
        }
    }

    // Sort by score (descending)
    candidates.sort_by(|a, b| b.0.cmp(&a.0));
    candidates.into_iter().next().map(|(_, url)| url)
}

async fn get_sc_client_id(client: &Client) -> Option<String> {
    let resp = client.get("https://soundcloud.com/").send().await.ok()?.text().await.ok()?;
    
    let re_js = Regex::new(r#"src="([^"]+/app-[^"]+\.js)""#).ok()?;
    let js_urls: Vec<_> = re_js.captures_iter(&resp)
        .filter_map(|cap| cap.get(1))
        .map(|m| m.as_str().to_string())
        .collect();

    let re_id = Regex::new(r#"client_id:"([a-zA-Z0-9]{32})""#).ok()?;
    
    for js_url in js_urls {
        if let Ok(js_resp) = client.get(&js_url).send().await {
            if let Ok(js_text) = js_resp.text().await {
                if let Some(cap) = re_id.captures(&js_text) {
                    return Some(cap.get(1)?.as_str().to_string());
                }
            }
        }
    }
    
    None
}

fn score_youtube_match(query: &str, title: &str, author: &str) -> i32 {
    let q = query.to_lowercase();
    let t = title.to_lowercase();
    let a = author.to_lowercase();
    
    let mut score = 0;
    
    // Penalize remixes/edits
    let penalties = ["remix", "edit", "sped up", "speed up", "slowed", "reverb", "cover", "bootleg", "nightcore"];
    for p in penalties {
        if t.contains(p) && !q.contains(p) {
            score -= 100;
        }
    }
    
    // Boost if artist matches author
    if t.contains(&a) || q.contains(&a) {
        score += 50;
    }
    
    score
}

pub async fn search_tracks(query: String, source: String) -> Vec<SpectrumTrackMetadata> {
    let client = Client::builder()
        .timeout(Duration::from_secs(10))
        .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        .build()
        .unwrap_or_default();

    let mut results = Vec::new();

    if source == "youtube" || source == "auto" {
        let instances = [
            "https://pipedapi.adminforge.de",
            "https://pipedapi.kavin.rocks",
            "https://pipedapi.leptons.xyz",
            "https://piped-api.garudalinux.org",
            "https://api.piped.projectsegfau.lt",
            "https://invidious.flokinet.to/api/v1",
            "https://yewtu.be/api/v1",
            "https://invidious.lunar.icu/api/v1",
        ];
        
        'instance_loop: for instance in instances {
            let is_invidious = instance.contains("invidious") || instance.contains("yewtu.be") || instance.contains("lunar.icu");
            let url = format!("{}/search", instance);

            // Try with filter first, then without
            let filters = if is_invidious { vec![None] } else { vec![Some("videos"), None] };

            for filter in filters {
                let mut query_params = vec![("q", query.as_str())];
                if let Some(f) = filter {
                    query_params.push(("filter", f));
                }

                if let Ok(resp) = client.get(&url)
                    .query(&query_params)
                    .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                    .timeout(Duration::from_secs(4))
                    .send()
                    .await 
                {
                    if let Ok(data) = resp.json::<Value>().await {
                        let items = if is_invidious {
                            data.as_array()
                        } else {
                            data.get("content")
                                .or_else(|| data.get("items"))
                                .or_else(|| if data.is_array() { Some(&data) } else { None })
                                .and_then(|v| v.as_array())
                        };

                        if let Some(items) = items {
                            if items.is_empty() { continue; }
                            for item in items.iter().take(20) {
                                let item_type = item.get("type").and_then(|v| v.as_str()).unwrap_or("");
                                if !item_type.is_empty() && item_type != "stream" && item_type != "video" { continue; }

                                let video_id = if is_invidious {
                                    item.get("videoId").and_then(|v| v.as_str()).map(|s| s.to_string())
                                } else {
                                    item.get("url").and_then(|u| u.as_str()).and_then(|s| s.split('=').last()).map(|s| s.to_string())
                                        .or_else(|| item.get("videoId").and_then(|v| v.as_str()).map(|s| s.to_string()))
                                };

                                if video_id.is_none() { continue; }

                                let artist_name = if is_invidious {
                                    item.get("author").and_then(|v| v.as_str())
                                } else {
                                    item.get("uploaderName").and_then(|v| v.as_str())
                                        .or_else(|| item.get("author").and_then(|v| v.as_str()))
                                };

                                results.push(SpectrumTrackMetadata {
                                    id: video_id.unwrap(),
                                    title: item.get("title").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                                    artist: artist_name.unwrap_or("").to_string(),
                                    duration_ms: item.get("duration").and_then(|v| v.as_i64()).unwrap_or(0) * 1000,
                                    artwork_url: item.get("thumbnail").and_then(|v| v.as_str())
                                        .or_else(|| item.get("thumbnails").and_then(|t| t.as_array()).and_then(|a| a.first()).and_then(|v| v.get("url")).and_then(|u| u.as_str()))
                                        .map(|s| s.to_string()),
                                    source: "youtube".to_string(),
                                    local_path: None,
                                    dominant_color: None,
                                    blur_hash_path: None,
                                });
                            }
                            if !results.is_empty() { break 'instance_loop; } 
                        }
                    }
                }
            }
        }
    }

    if source == "soundcloud" || source == "auto" {
        let client_id = match get_sc_client_id(&client).await {
            Some(id) => id,
            None => "tkIWLs4MIowq7bCXP80TOwx6DnDa7UPc".to_string(), // Fallback
        };
            let url = "https://api-v2.soundcloud.com/search/tracks";
            if let Ok(resp) = client.get(url)
                .query(&[("q", query.as_str()), ("client_id", client_id.as_str()), ("limit", "15")])
                .send()
                .await 
            {
                if let Ok(data) = resp.json::<Value>().await {
                    if let Some(collection) = data.get("collection").and_then(|v| v.as_array()) {
                        for item in collection {
                            results.push(SpectrumTrackMetadata {
                                id: item.get("permalink_url").and_then(|u| u.as_str()).unwrap_or("").to_string(),
                                title: item.get("title").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                                artist: item.get("user").and_then(|u| u.get("username")).and_then(|v| v.as_str()).unwrap_or("").to_string(),
                                duration_ms: item.get("duration").and_then(|v| v.as_i64()).unwrap_or(0),
                                artwork_url: item.get("artwork_url").and_then(|v| v.as_str()).map(|s| s.to_string()),
                                source: "soundcloud".to_string(),
                                local_path: None,
                                dominant_color: None,
                                blur_hash_path: None,
                            });
                        }
                    }
                }
            }
    }

    results
}
