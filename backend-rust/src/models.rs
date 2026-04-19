use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use chrono::NaiveDateTime;

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct IsrcMapping {
    pub isrc: String,
    pub title: String,
    pub artist: String,
    pub spotify_id: Option<String>,
    pub apple_id: Option<String>,
    pub youtube_id: Option<String>,
    pub deezer_id: Option<String>,
    pub tidal_id: Option<String>,
    pub hit_count: Option<i32>,
    pub verified_at: Option<NaiveDateTime>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateIsrcMapping {
    pub title: String,
    pub artist: String,
    pub spotify_id: Option<String>,
    pub apple_id: Option<String>,
    pub youtube_id: Option<String>,
    pub deezer_id: Option<String>,
    pub tidal_id: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct JamSessionMember {
    pub id: String,
    pub name: String,
    pub is_host: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub avatar_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct JamSession {
    pub id: String,
    #[serde(default)]
    pub host_id: Option<String>,
    pub members: Vec<JamSessionMember>,
    pub current_track: Option<serde_json::Value>,
    pub shared_queue: Vec<serde_json::Value>,
    pub is_playing: bool,
    pub position_ms: i64,
    pub last_update: String,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ActiveSessionInfo {
    pub id: String,
    pub host_name: String,
    pub member_count: usize,
    pub current_track: Option<serde_json::Value>,
    pub last_update: String,
}
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct JamSessionUpdate {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub current_track: Option<Option<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub members: Option<Vec<JamSessionMember>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub shared_queue: Option<Vec<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub is_playing: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub position_ms: Option<i64>,
}
