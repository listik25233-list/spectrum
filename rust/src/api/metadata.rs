use crate::api::models::SpectrumTrackMetadata;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResolvedMapping {
    pub isrc: String,
    pub spotify_id: Option<String>,
    pub youtube_id: Option<String>,
    pub soundcloud_id: Option<String>,
}

pub fn score_match(original: SpectrumTrackMetadata, candidate: SpectrumTrackMetadata) -> f64 {
    let mut score = 0.0;

    let duration_diff = (original.duration_ms - candidate.duration_ms).abs();
    if duration_diff < 5000 {
        score += 50.0;
    } else if duration_diff < 15000 {
        score += 30.0;
    } else if duration_diff > 30000 {
        score -= 50.0;
    }

    let original_title = original.title.to_lowercase();
    let candidate_title = candidate.title.to_lowercase();
    
    if original_title == candidate_title {
        score += 40.0;
    } else if original_title.contains(&candidate_title) || candidate_title.contains(&original_title) {
        score += 20.0;
    }

    let original_artist = original.artist.to_lowercase();
    let candidate_artist = candidate.artist.to_lowercase();
    if original_artist == candidate_artist {
        score += 10.0;
    }

    score
}

pub fn normalize_metadata(mut track: SpectrumTrackMetadata) -> SpectrumTrackMetadata {
    let clean_patterns = [
        "(Official Video)", "(Official Audio)", "[Official]", 
        "(Lyric Video)", "(Audio)", "(Lyrics)", "- Topic",
        "(HD)", "(HQ)", "Official Music Video", "Official Video",
        "Official Audio", "Lyrics Video", "Music Video",
        "| Official", "[HD]", "[HQ]", "(Extended Mix)",
        "(Original Mix)"
    ];

    for pattern in clean_patterns {
        track.title = track.title.replace(pattern, "").trim().to_string();
    }
    
    // Also clean artist if it contains - Topic
    track.artist = track.artist.replace("- Topic", "").trim().to_string();
    
    track
}

pub fn normalize_metadata_bulk(tracks: Vec<SpectrumTrackMetadata>) -> Vec<SpectrumTrackMetadata> {
    tracks.into_iter().map(normalize_metadata).collect()
}
