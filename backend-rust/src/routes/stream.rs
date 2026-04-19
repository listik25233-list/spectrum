use axum::{
    body::Body,
    extract::Path,
    http::{header, Response, StatusCode},
    response::IntoResponse,
};
use tokio::process::Command;
use tokio_util::io::ReaderStream;
use std::process::Stdio;

pub async fn get_stream(Path(video_id): Path<String>) -> impl IntoResponse {
    println!("[Stream] Request for video: {}", video_id);
    // Sanity check video_id
    if video_id.len() != 11 {
        return (StatusCode::BAD_REQUEST, "Invalid video ID").into_response();
    }

    let url = format!("https://www.youtube.com/watch?v={}", video_id);
    
    let child = Command::new("yt-dlp")
        .args([
            "-f", "bestaudio[ext=m4a]/bestaudio",
            "-o", "-",
            "--quiet",
            "--no-warnings",
            "--no-playlist",
            "--extractor-args", "youtube:player_client=android,web",
            "--force-overwrites",
            &url,
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn();

    let mut child = match child {
        Ok(c) => c,
        Err(e) => {
            eprintln!("[Stream] Failed to spawn yt-dlp: {}", e);
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };

    let stdout = child.stdout.take().expect("Failed to capture stdout");
    
    // Create a stream from the stdout
    let stream = ReaderStream::new(stdout);
    let body = Body::from_stream(stream);

    println!("[Stream] Proxying stream for {}", video_id);

    Response::builder()
        .header(header::CONTENT_TYPE, "audio/mp4")
        .header(header::ACCEPT_RANGES, "bytes")
        .header("X-Video-ID", video_id)
        .body(body)
        .unwrap()
        .into_response()
}
