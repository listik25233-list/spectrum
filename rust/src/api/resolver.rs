use crate::api::models::SpectrumTrackMetadata;
use crate::api::simple::search_tracks;
use crate::api::metadata::score_match;

pub async fn find_best_match(original: SpectrumTrackMetadata, source: String) -> Option<SpectrumTrackMetadata> {
    let query = format!("{} {}", original.title, original.artist);
    
    let mut candidates = search_tracks(query, source).await;
    
    if candidates.is_empty() {
        return None;
    }

    candidates.sort_by(|a, b| {
        let score_a = score_match(original.clone(), a.clone());
        let score_b = score_match(original.clone(), b.clone());
        score_b.partial_cmp(&score_a).unwrap_or(std::cmp::Ordering::Equal)
    });

    let best = candidates.first().cloned()?;
    if score_match(original, best.clone()) >= 60.0 {
        Some(best)
    } else {
        None
    }
}
