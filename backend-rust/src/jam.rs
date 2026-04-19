use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::time::{Duration, SystemTime};
use serde_json::Value;
use socketioxide::extract::{Data, SocketRef, State};
use axum::{extract::{State as AxumState, Path, Json}, http::StatusCode};
use crate::models::{JamSession, ActiveSessionInfo};

pub type SharedState = Arc<RwLock<HashMap<String, JamSession>>>;

#[derive(Clone)]
pub struct AppState {
    pub jam: SharedState,
    pub io: socketioxide::SocketIo,
}

impl axum::extract::FromRef<AppState> for SharedState {
    fn from_ref(state: &AppState) -> Self {
        state.jam.clone()
    }
}

impl axum::extract::FromRef<AppState> for socketioxide::SocketIo {
    fn from_ref(state: &AppState) -> Self {
        state.io.clone()
    }
}

pub fn init_state() -> SharedState {
    let state: SharedState = Arc::new(RwLock::new(HashMap::new()));
    
    // Inactivity cleanup task
    let state_clone = state.clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(60));
        loop {
            interval.tick().await;
            let now = SystemTime::now()
                .duration_since(SystemTime::UNIX_EPOCH)
                .unwrap()
                .as_secs();
            
            let mut sessions = state_clone.write().unwrap();
            sessions.retain(|id, session| {
                let last_update_ts = chrono::DateTime::parse_from_rfc3339(&session.last_update)
                    .map(|dt| dt.timestamp() as u64)
                    .unwrap_or_else(|e| {
                        eprintln!("[Cleanup] Failed to parse timestamp for session {}: {}. Raw: '{}'", id, e, session.last_update);
                        0
                    });
                
                let is_active = now - last_update_ts < 300; // 5 minutes
                if !is_active {
                    println!("[Cleanup] Deleting expired session: {} (Last update was {}s ago)", id, now - last_update_ts);
                }
                is_active
            });
        }
    });

    state
}

pub fn on_connect(socket: SocketRef, State(_state): State<AppState>) {
    println!("Socket connected: {}", socket.id);

    socket.on("join-room", |socket: SocketRef, Data(room_id): Data<String>| {
        let _ = socket.leave_all();
        let _ = socket.join(room_id.clone());
        println!("User {} joined room: {}", socket.id, room_id);
    });
}

pub async fn create_session(
    AxumState(state): AxumState<SharedState>,
    Json(session): Json<JamSession>,
) -> Json<Value> {
    println!("[Jam] Creating new session: {} (Host: {})", session.id, session.host_id.as_deref().unwrap_or("unknown"));
    let mut sessions = state.write().unwrap();
    let mut session = session;
    session.last_update = chrono::Utc::now().to_rfc3339();
    session.is_playing = false;
    session.position_ms = 0;
    sessions.insert(session.id.clone(), session);
    Json(serde_json::json!({ "status": "ok" }))
}

pub async fn get_session_http(
    Path(id): Path<String>,
    AxumState(state): AxumState<SharedState>,
) -> Result<Json<JamSession>, StatusCode> {
    let sessions = state.read().unwrap();
    match sessions.get(&id) {
        Some(session) => Ok(Json(session.clone())),
        None => Err(StatusCode::NOT_FOUND),
    }
}

pub async fn list_sessions(
    AxumState(state): AxumState<SharedState>,
) -> Json<Vec<ActiveSessionInfo>> {
    let sessions = state.read().unwrap();
    let infos = sessions.values()
        .map(|s| {
            let host_name = s.members.iter()
                .find(|m| m.is_host)
                .map(|m| m.name.clone())
                .unwrap_or_else(|| "Unknown".to_string());
            
            ActiveSessionInfo {
                id: s.id.clone(),
                host_name,
                member_count: s.members.len(),
                current_track: s.current_track.clone(),
                last_update: s.last_update.clone(),
            }
        })
        .collect();
    Json(infos)
}

pub async fn update_session(
    Path(id): Path<String>,
    AxumState(state): AxumState<SharedState>,
    AxumState(io): AxumState<socketioxide::SocketIo>,
    Json(update_data): Json<serde_json::Map<String, Value>>,
) -> Result<Json<Value>, StatusCode> {
    let mut sessions = state.write().unwrap();
    if let Some(session) = sessions.get_mut(&id) {
        println!("[Jam] Updating session: {} (Members: {}, Queue: {})", id, session.members.len(), session.shared_queue.len());
        // Accept both camelCase and snake_case keys from clients
        if let Some(current_track) = update_data.get("currentTrack").or_else(|| update_data.get("current_track")) {
            session.current_track = serde_json::from_value(current_track.clone()).ok();
        }
        if let Some(is_playing) = update_data.get("isPlaying").or_else(|| update_data.get("is_playing")) {
            session.is_playing = is_playing.as_bool().unwrap_or(false);
        }
        if let Some(position_ms) = update_data.get("positionMs").or_else(|| update_data.get("position_ms")) {
            session.position_ms = position_ms.as_i64().unwrap_or(0);
        }
        if let Some(members) = update_data.get("members") {
            session.members = serde_json::from_value(members.clone()).unwrap_or_default();
        }
        if let Some(shared_queue) = update_data.get("sharedQueue").or_else(|| update_data.get("shared_queue")) {
            session.shared_queue = serde_json::from_value(shared_queue.clone()).unwrap_or_default();
        }
        if let Some(host_id) = update_data.get("hostId").or_else(|| update_data.get("host_id")) {
            session.host_id = host_id.as_str().map(|s| s.to_string());
        }
        
        session.last_update = chrono::Utc::now().to_rfc3339();
        
        // Broadcast delta via Socket.io
        println!("[Jam] Broadcasting delta to room: {}", id);
        let mut delta = update_data.clone();
        delta.insert("lastUpdate".to_string(), serde_json::Value::String(session.last_update.clone()));
        let _ = io.to(id).emit("session-delta", &delta);
        
        Ok(Json(serde_json::json!({ "status": "ok" })))
    } else {
        Err(StatusCode::NOT_FOUND)
    }
}

pub async fn add_track(
    Path(id): Path<String>,
    AxumState(state): AxumState<SharedState>,
    AxumState(io): AxumState<socketioxide::SocketIo>,
    Json(data): Json<Value>,
) -> Result<Json<Value>, StatusCode> {
    let mut sessions = state.write().unwrap();
    if let Some(session) = sessions.get_mut(&id) {
        if let Some(track_val) = data.get("track") {
            if let Ok(track) = serde_json::from_value::<serde_json::Value>(track_val.clone()) {
                session.shared_queue.push(track.clone());
                session.last_update = chrono::Utc::now().to_rfc3339();
                
                println!("[Jam] Track added. Broadcasting delta to room: {}", id);
                let mut delta = serde_json::Map::new();
                delta.insert("sharedQueue".to_string(), serde_json::Value::Array(session.shared_queue.clone()));
                delta.insert("lastUpdate".to_string(), serde_json::Value::String(session.last_update.clone()));
                let _ = io.to(id).emit("session-delta", &delta);
                
                return Ok(Json(serde_json::json!({ "status": "ok" })));
            }
        }
        Err(StatusCode::BAD_REQUEST)
    } else {
        Err(StatusCode::NOT_FOUND)
    }
}

pub fn jam_router(state: AppState) -> axum::Router {
    axum::Router::new()
        .route("/create", axum::routing::post(create_session))
        .route("/session/:id", axum::routing::get(get_session_http))
        .route("/list", axum::routing::get(list_sessions))
        .route("/update/:id", axum::routing::post(update_session))
        .route("/add-track/:id", axum::routing::post(add_track))
        .with_state(state)
}
