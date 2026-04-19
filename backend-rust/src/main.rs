mod db;
mod jam;
mod models;
mod routes;

use axum::{
    routing::{get, put},
    Router,
    Json,
};
use socketioxide::SocketIo;
use tower_http::cors::CorsLayer;
use std::net::SocketAddr;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();
    
    // Initialize tracing
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| "backend_rust=debug,tower_http=debug".into()))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let pool = db::init_pool().await;
    db::run_migrations(&pool).await;

    let jam_state = jam::init_state();
    
    // Socket.io setup with increased payload limit (2MB) for large queues
    let (layer, io) = SocketIo::builder()
        .with_state(jam_state.clone())
        .max_payload(2 * 1024 * 1024)
        .build_layer();

    // Use explicit paths for extractors to avoid confusion with Axum
    io.ns("/", |s: socketioxide::extract::SocketRef, socketioxide::extract::State(state): socketioxide::extract::State<jam::AppState>| {
        jam::on_connect(s, socketioxide::extract::State(state));
    });

    let app_state = jam::AppState {
        jam: jam_state.clone(),
        io: io.clone(),
    };

    // Routes
    let isrc_router = Router::new()
        .route("/:isrc", get(routes::isrc::get_isrc))
        .route("/:isrc", put(routes::isrc::upsert_isrc))
        .with_state(pool.clone());

    let app = Router::new()
        .nest("/api/isrc", isrc_router)
        .nest("/api/jam", jam::jam_router(app_state.clone()))
        .route("/api/stream/:video_id", get(routes::stream::get_stream))
        .route("/health", get(|| async { Json(serde_json::json!({ "status": "ok" })) }))
        .layer(layer)
        .layer(CorsLayer::permissive())
        .layer(tower_http::limit::RequestBodyLimitLayer::new(2 * 1024 * 1024));

    let addr = SocketAddr::from(([0, 0, 0, 0], 3001));
    println!("Spectrum Rust backend running on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();

    Ok(())
}
