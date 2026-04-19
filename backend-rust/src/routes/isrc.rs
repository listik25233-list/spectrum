use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use sqlx::{Pool, Postgres};
use crate::models::{IsrcMapping, CreateIsrcMapping};

pub async fn get_isrc(
    Path(isrc): Path<String>,
    State(pool): State<Pool<Postgres>>,
) -> Result<Json<IsrcMapping>, StatusCode> {
    let result = sqlx::query_as::<_, IsrcMapping>(
        "SELECT * FROM isrc_mappings WHERE isrc = $1"
    )
    .bind(isrc.to_uppercase())
    .fetch_optional(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    match result {
        Some(mapping) => {
            // Increment hit count asynchronously
            let pool_clone = pool.clone();
            let isrc_clone = isrc.clone();
            tokio::spawn(async move {
                let _ = sqlx::query(
                    "UPDATE isrc_mappings SET hit_count = hit_count + 1 WHERE isrc = $1"
                )
                .bind(isrc_clone.to_uppercase())
                .execute(&pool_clone)
                .await;
            });

            Ok(Json(mapping))
        }
        None => Err(StatusCode::NOT_FOUND),
    }
}

pub async fn upsert_isrc(
    Path(isrc): Path<String>,
    State(pool): State<Pool<Postgres>>,
    Json(payload): Json<CreateIsrcMapping>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    sqlx::query(
        "INSERT INTO isrc_mappings (isrc, title, artist, spotify_id, apple_id, youtube_id, deezer_id, tidal_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (isrc) DO UPDATE SET
           spotify_id  = COALESCE($4, isrc_mappings.spotify_id),
           apple_id    = COALESCE($5, isrc_mappings.apple_id),
           youtube_id  = COALESCE($6, isrc_mappings.youtube_id),
           deezer_id   = COALESCE($7, isrc_mappings.deezer_id),
           tidal_id    = COALESCE($8, isrc_mappings.tidal_id),
           hit_count   = isrc_mappings.hit_count + 1,
           verified_at = NOW()"
    )
    .bind(isrc.to_uppercase())
    .bind(payload.title)
    .bind(payload.artist)
    .bind(payload.spotify_id)
    .bind(payload.apple_id)
    .bind(payload.youtube_id)
    .bind(payload.deezer_id)
    .bind(payload.tidal_id)
    .execute(&pool)
    .await
    .map_err(|e| {
        eprintln!("Upsert error: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    Ok(Json(serde_json::json!({ "success": true })))
}
