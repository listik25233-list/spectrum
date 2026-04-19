use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[flutter_rust_bridge::frb(non_opaque)]
pub struct SpectrumTrackMetadata {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub duration_ms: i64,
    pub artwork_url: Option<String>,
    pub source: String, // "youtube" or "soundcloud" or "local"
    pub local_path: Option<String>,
    pub dominant_color: Option<String>,
    pub blur_hash_path: Option<String>,
}
