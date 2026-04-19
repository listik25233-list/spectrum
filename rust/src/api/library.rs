use crate::api::models::SpectrumTrackMetadata;
use strsim::levenshtein;
use walkdir::WalkDir;
use rayon::prelude::*;
use lofty::prelude::*;
use crate::frb_generated::StreamSink;
use lofty::probe::Probe;
use std::sync::Arc;

pub fn search_in_tracks(query: String, tracks: Vec<SpectrumTrackMetadata>) -> Vec<SpectrumTrackMetadata> {
    let query_lower = query.to_lowercase();
    let mut scored_tracks: Vec<(i32, SpectrumTrackMetadata)> = tracks.into_iter()
        .map(|track| {
            let mut score = 0;
            let title_lower = track.title.to_lowercase();
            let artist_lower = track.artist.to_lowercase();
            
            if title_lower == query_lower {
                score += 100;
            } else if title_lower.starts_with(&query_lower) {
                score += 50;
            } else if title_lower.contains(&query_lower) {
                score += 20;
            }
            
            if artist_lower.contains(&query_lower) {
                score += 10;
            }
            
            (score, track)
        })
        .filter(|(score, _)| *score > 0)
        .collect();
        
    scored_tracks.sort_by(|a, b| b.0.cmp(&a.0));
    scored_tracks.into_iter().map(|(_, t)| t).take(20).collect()
}

pub fn find_duplicates(tracks: Vec<SpectrumTrackMetadata>) -> Vec<Vec<String>> {
    let mut duplicates = Vec::new();
    let mut handled = std::collections::HashSet::new();
    
    for i in 0..tracks.len() {
        if handled.contains(&tracks[i].id) { continue; }
        let mut group = vec![tracks[i].id.clone()];
        
        for j in i+1..tracks.len() {
            if handled.contains(&tracks[j].id) { continue; }
            
            let dist = levenshtein(&tracks[i].title.to_lowercase(), &tracks[j].title.to_lowercase());
            if dist <= 2 && tracks[i].artist.to_lowercase() == tracks[j].artist.to_lowercase() {
                group.push(tracks[j].id.clone());
                handled.insert(tracks[j].id.clone());
            }
        }
        
        if group.len() > 1 {
            duplicates.push(group);
        }
        handled.insert(tracks[i].id.clone());
    }
    
    duplicates
}

pub fn scan_local_directory(path: String, cache_dir: String, sink: StreamSink<SpectrumTrackMetadata>) -> anyhow::Result<()> {
    let entries: Vec<_> = WalkDir::new(path)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| {
            let path = e.path();
            path.is_file() && 
            matches!(path.extension().and_then(|s| s.to_str()), Some("mp3") | Some("flac") | Some("m4a") | Some("wav") | Some("ogg"))
        })
        .collect();

    let cache_dir_arc = std::sync::Arc::new(cache_dir);

    entries.into_par_iter().for_each(|entry| {
        let path = entry.path();
        let cache_dir = Arc::clone(&cache_dir_arc);
        
        if let Ok(prob) = Probe::open(path) {
            if let Ok(tagged_file) = prob.read() {
                let properties = tagged_file.properties();
                let duration_ms = properties.duration().as_millis() as i64;
                
                let (title, artist, album) = if let Some(tag) = tagged_file.primary_tag() {
                    (
                        tag.title().map(|s| s.to_string()).unwrap_or_else(|| path.file_stem().unwrap().to_string_lossy().to_string()),
                        tag.artist().map(|s| s.to_string()).unwrap_or_else(|| "Unknown Artist".to_string()),
                        tag.album().map(|s| s.to_string()),
                    )
                } else {
                    (
                        path.file_stem().unwrap().to_string_lossy().to_string(),
                        "Unknown Artist".to_string(),
                        None,
                    )
                };

                let id = path.to_string_lossy().to_string();

                // 1. Send METADATA immediately for fast UI response
                let metadata = SpectrumTrackMetadata {
                    id: id.clone(),
                    title,
                    artist,
                    duration_ms,
                    artwork_url: None,
                    source: "local".to_string(),
                    local_path: Some(id.clone()),
                    dominant_color: None,
                    blur_hash_path: None,
                };
                let _ = sink.add(metadata);

                // 2. Process ASSETS (cover, color, blur) in background
                let audio_path = id.clone();
                let sink_clone = sink.clone();
                
                // We use Rayon's thread pool via into_par_iter already, 
                // but we can spawn nested if we want totally "decoupled" asset streams.
                // However, doing it right here is fine since we already sent metadata.
                if let Ok(assets) = crate::api::image_processor::extract_and_process_cover(audio_path, cache_dir.to_string()) {
                    let updated_metadata = SpectrumTrackMetadata {
                        id,
                        title: "".to_string(), // Flutter should only update existing based on ID
                        artist: "".to_string(),
                        duration_ms: 0,
                        artwork_url: Some(assets.thumbnail_path),
                        source: "local".to_string(),
                        local_path: None,
                        dominant_color: Some(assets.dominant_color_hex),
                        blur_hash_path: Some(assets.blur_hash_subset),
                    };
                    let _ = sink_clone.add(updated_metadata);
                }
            }
        }
    });

    Ok(())
}
