use crate::api::models::SpectrumTrackMetadata;
use crate::api::simple::search_tracks;
use strsim::levenshtein;
use rayon::prelude::*;

/// The Matrix Search Engine.
/// Unifies local library, YouTube, and SoundCloud into a single ranked stream.
pub async fn unified_search(
    query: String, 
    local_tracks: Vec<SpectrumTrackMetadata>,
    source: String,
) -> Vec<SpectrumTrackMetadata> {
    let query_lower = query.to_lowercase();
    
    // 1. Search in Network (Async)
    let network_results = search_tracks(query.clone(), source).await;
    
    // 2. Score Network Results
    let mut scored_all: Vec<(i32, SpectrumTrackMetadata)> = network_results.into_iter()
        .map(|track| {
            let score = calculate_relevance_score(&query_lower, &track);
            (score, track)
        })
        .collect();
    
    // 3. Score Local (Using Rayon for massive libraries)
    let scored_local: Vec<(i32, SpectrumTrackMetadata)> = local_tracks.into_par_iter()
        .map(|track| {
            let mut score = calculate_relevance_score(&query_lower, &track);
            // Boost local results slightly to prefer offline playback
            if score > 0 { score += 20; }
            (score, track)
        })
        .filter(|(score, _)| *score > 0)
        .collect();
    
    scored_all.extend(scored_local);
    
    // 4. Merge and Deduplicate
    let mut final_results = Vec::new();
    let mut seen_signatures = std::collections::HashSet::new();
    
    // Sort everything by relevance
    scored_all.sort_by(|a, b| b.0.cmp(&a.0));
    
    for (score, track) in scored_all {
        // Only filter local garbage, allow network results to pass through for discovery
        if track.source == "local" && score < 1 { continue; }
        
        let sig = format!("{}-{}", track.title.to_lowercase(), track.artist.to_lowercase());
        if !seen_signatures.contains(&sig) {
            seen_signatures.insert(sig);
            final_results.push(track);
        }
    }
    
    final_results.truncate(50);
    final_results
}

fn calculate_relevance_score(query: &str, track: &SpectrumTrackMetadata) -> i32 {
    let t_lower = track.title.to_lowercase();
    let a_lower = track.artist.to_lowercase();
    
    let mut score = 0;
    
    // Exact match
    if t_lower == query || a_lower == query {
        score += 100;
    }
    
    // Starts with
    if t_lower.starts_with(query) || a_lower.starts_with(query) {
        score += 60;
    }
    
    // Contains
    if t_lower.contains(query) || a_lower.contains(query) {
        score += 30;
    }
    
    // Fuzzy match (expensive but powerful)
    let dist = levenshtein(query, &t_lower);
    if dist < 3 {
        score += 40 - (dist as i32 * 10);
    }
    
    score
}
