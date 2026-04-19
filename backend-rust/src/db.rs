use sqlx::postgres::PgPoolOptions;
use sqlx::{Pool, Postgres};
use std::env;

pub async fn init_pool() -> Pool<Postgres> {
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    
    PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to create pool")
}

pub async fn run_migrations(pool: &Pool<Postgres>) {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS isrc_mappings (
          isrc        VARCHAR(12) PRIMARY KEY,
          title       TEXT        NOT NULL,
          artist      TEXT        NOT NULL,
          spotify_id  VARCHAR(30),
          apple_id    VARCHAR(30),
          youtube_id  VARCHAR(30),
          deezer_id   VARCHAR(20),
          tidal_id    VARCHAR(20),
          hit_count   INTEGER     DEFAULT 1,
          verified_at TIMESTAMP   DEFAULT NOW()
        );"
    )
    .execute(pool)
    .await
    .expect("Failed to run migrations");
    
    println!("Database initialized");
}
