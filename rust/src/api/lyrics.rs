use serde::{Deserialize, Serialize};
use reqwest::Client;
use std::time::Duration;
use regex::Regex;
use futures::future::{join_all, BoxFuture};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpectrumLyrics {
    pub content: String,
    pub lines: Vec<LyricsLine>,
    pub source: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LyricsLine {
    pub time_ms: i64,
    pub text: String,
}

pub async fn get_lyrics(
    title: String,
    artist: String,
    album: Option<String>,
    duration_ms: i64,
) -> Option<SpectrumLyrics> {
    let results = get_all_lyrics(title, artist, album, duration_ms).await;
    
    // Sort results by "quality" (Synced > Plain)
    let mut candidates = results.clone();
    candidates.sort_by_key(|l| if l.lines.is_empty() { 1 } else { 0 });

    candidates.into_iter().next()
}

pub async fn get_all_lyrics(
    title: String,
    artist: String,
    album: Option<String>,
    duration_ms: i64,
) -> Vec<SpectrumLyrics> {
    let client = Client::builder()
        .timeout(Duration::from_secs(10))
        .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        .build()
        .unwrap_or_default();

    let title_clean = clean_query(&title);
    let artist_clean = clean_query(&artist);

    // Boxed futures of the same type for join_all
    let futures: Vec<BoxFuture<Option<SpectrumLyrics>>> = vec![
        Box::pin(fetch_lrclib(&client, &title, &artist, album.as_deref(), duration_ms)),
        Box::pin(fetch_lrclib_search(&client, &title, &artist)),
        Box::pin(fetch_netease(&client, &title, &artist)),
        Box::pin(fetch_genius(&client, &title_clean, &artist_clean)),
        Box::pin(fetch_lyrics_ovh(&client, &title, &artist)),
    ];

    join_all(futures).await.into_iter().flatten().collect()
}

async fn fetch_lrclib_search(client: &Client, title: &str, artist: &str) -> Option<SpectrumLyrics> {
    let query = format!("{} {}", artist, title);
    let url = "https://lrclib.net/api/search";
    let resp = client.get(url).query(&[("q", &query)]).send().await.ok()?;
    let data: serde_json::Value = resp.json().await.ok()?;

    let results = data.as_array()?;
    for entry in results {
        let synced = entry.get("syncedLyrics").and_then(|v| v.as_str()).unwrap_or("");
        let plain = entry.get("plainLyrics").and_then(|v| v.as_str()).unwrap_or("");

        if !synced.is_empty() && has_lrc_timestamps(synced) {
            return Some(SpectrumLyrics {
                content: synced.to_string(),
                lines: parse_lrc(synced),
                source: "LRCLIB (Search-Synced)".to_string(),
            });
        }
        if !plain.is_empty() {
            return Some(SpectrumLyrics {
                content: plain.to_string(),
                lines: vec![],
                source: "LRCLIB (Search-Plain)".to_string(),
            });
        }
    }
    None
}

async fn fetch_netease(client: &Client, title: &str, artist: &str) -> Option<SpectrumLyrics> {
    let query = format!("{} {}", artist, title);
    let search_url = "https://music.163.com/api/search/get";
    let resp = client.get(search_url)
        .query(&[("s", query.as_str()), ("type", "1"), ("limit", "1")])
        .send().await.ok()?;
    let data: serde_json::Value = resp.json().await.ok()?;
    
    let song_id = data.get("result")?.get("songs")?.as_array()?.first()?.get("id")?.as_i64()?;
    
    let lyrics_url = format!("https://music.163.com/api/song/lyric?id={}&lv=1&kv=1&tv=-1", song_id);
    let resp = client.get(lyrics_url).send().await.ok()?;
    let lrc_data: serde_json::Value = resp.json().await.ok()?;
    
    let lrc = lrc_data.get("lrc")?.get("lyric")?.as_str()?;
    if !lrc.is_empty() {
        return Some(SpectrumLyrics {
            content: lrc.to_string(),
            lines: parse_lrc(lrc),
            source: "NetEase".to_string(),
        });
    }
    None
}

async fn fetch_lrclib(
    client: &Client,
    title: &str,
    artist: &str,
    album: Option<&str>,
    duration_ms: i64,
) -> Option<SpectrumLyrics> {
    let url = "https://lrclib.net/api/get";
    
    // First try: match with duration
    let mut resp = client.get(url)
        .query(&[
            ("artist_name", artist),
            ("track_name", title),
            ("album_name", album.unwrap_or("")),
            ("duration", &(duration_ms / 1000).to_string())
        ])
        .send().await.ok();

    // Second try: without extra constraints if first failed
    if resp.as_ref().map(|r| !r.status().is_success()).unwrap_or(true) {
        resp = client.get(url)
            .query(&[
                ("artist_name", artist),
                ("track_name", title),
            ])
            .send().await.ok();
    }

    let r = resp?;
    if !r.status().is_success() { return None; }

    let data: serde_json::Value = r.json().await.ok()?;
    let synced = data.get("syncedLyrics").and_then(|v| v.as_str()).unwrap_or("");
    let plain = data.get("plainLyrics").and_then(|v| v.as_str()).unwrap_or("");

    if !synced.is_empty() && has_lrc_timestamps(synced) {
        return Some(SpectrumLyrics {
            content: synced.to_string(),
            lines: parse_lrc(synced),
            source: "LRCLIB (Synced)".to_string(),
        });
    }

    if !plain.is_empty() {
        return Some(SpectrumLyrics {
            content: plain.to_string(),
            lines: vec![],
            source: "LRCLIB (Plain)".to_string(),
        });
    }

    None
}

async fn fetch_genius(client: &Client, title: &str, artist: &str) -> Option<SpectrumLyrics> {
    // 1. Search for track on Genius
    let query = format!("{} {}", artist, title);
    let url = "https://genius.com/api/search/multi";
    let resp = client.get(url).query(&[("q", &query)]).send().await.ok()?;
    let data: serde_json::Value = resp.json().await.ok()?;

    let hit = data.get("response")?
        .get("sections")?
        .as_array()?
        .iter()
        .find(|s| s.get("type").and_then(|v| v.as_str()) == Some("song"))?
        .get("hits")?
        .as_array()?
        .first()?;

    let path = hit.get("result")?.get("path")?.as_str()?;
    let lyrics_url = format!("https://genius.com{}", path);

    // 2. Fetch lyrics page
    let html = client.get(&lyrics_url).send().await.ok()?.text().await.ok()?;
    
    let mut lyrics = Vec::new();
    let container_marker = "data-lyrics-container=\"true\"";
    
    let mut search_pos = 0;
    while let Some(start_idx) = html[search_pos..].find(container_marker) {
        let abs_start = search_pos + start_idx;
        // Find the actual start of the tag: <div ... data-lyrics-container="true">
        let tag_start = html[..abs_start].rfind('<').unwrap_or(abs_start);
        let content_start = html[abs_start..].find('>').map(|i| abs_start + i + 1).unwrap_or(abs_start);
        
        // Count nested divs to find matching </div>
        let mut depth = 1;
        let mut current_pos = content_start;
        let mut end_idx = content_start;
        
        while depth > 0 && current_pos < html.len() {
            let next_open = html[current_pos..].find("<div");
            let next_close = html[current_pos..].find("</div>");
            
            match (next_open, next_close) {
                (Some(o), Some(c)) if o < c => {
                    depth += 1;
                    current_pos += o + 4;
                }
                (_, Some(c)) => {
                    depth -= 1;
                    end_idx = current_pos + c;
                    current_pos += c + 6;
                }
                _ => break,
            }
        }
        
        if end_idx > content_start {
            let mut content = html[content_start..end_idx].to_string();
            // 1. Convert <br/> and <br> to newlines
            content = Regex::new(r"(?i)<br\s*/?>").unwrap().replace_all(&content, "\n").to_string();
            // 2. Remove all other HTML tags
            content = Regex::new(r"<[^>]*>").unwrap().replace_all(&content, "").to_string();
            // 3. Decode entities
            let unescaped = htmlescape::decode_html(&content).unwrap_or(content);
            lyrics.push(unescaped);
        }
        
        search_pos = current_pos;
    }

    if !lyrics.is_empty() {
        let full_content = lyrics.join("\n");
        // Strip Genius page noise: "X Contributors...", "Lyrics", "[Текст песни ...]"
        let stripped = Regex::new(r"(?i)^\d+\s*Contributors?[^\n]*\n*").unwrap().replace(&full_content, "");
        let stripped = Regex::new(r"(?i)[^\n]*Lyrics\s*\n*").unwrap().replace(&stripped, "");
        let stripped = Regex::new(r"\[Текст песни[^\]]*\]\s*\n*").unwrap().replace(&stripped, "");
        // Collapse any sequence of 3+ newlines into just 2
        let collapsed = Regex::new(r"\n{3,}").unwrap().replace_all(&stripped, "\n\n");
        let cleaned = collapsed.replace("&nbsp;", " ").trim().to_string();
        
        if cleaned.is_empty() { return None; }
        
        return Some(SpectrumLyrics {
            content: cleaned,
            lines: vec![],
            source: "Genius".to_string(),
        });
    }

    None
}

async fn fetch_lyrics_ovh(client: &Client, title: &str, artist: &str) -> Option<SpectrumLyrics> {
    let url = format!("https://api.lyrics.ovh/v1/{}/{}", artist, title);
    let resp = client.get(url).send().await.ok()?;
    let data: serde_json::Value = resp.json().await.ok()?;

    let content = data.get("lyrics")?.as_str()?.trim().to_string();
    if !content.is_empty() {
        return Some(SpectrumLyrics {
            content,
            lines: vec![],
            source: "Lyrics.ovh".to_string(),
        });
    }
    None
}

fn clean_query(text: &str) -> String {
    let re_feat = Regex::new(r"(?i)\(feat\..*?\)").unwrap();
    let re_bracket = Regex::new(r"(?i)\[feat\..*?\]").unwrap();
    let re_explicit = Regex::new(r"(?i)\(explicit\)").unwrap();
    let re_official = Regex::new(r"(?i)\(official.*?\)").unwrap();
    let re_video = Regex::new(r"(?i)\(video.*?\)").unwrap();
    let re_dash = Regex::new(r"(?i)- .*?ost").unwrap();

    let clean = re_feat.replace_all(text, "");
    let clean = re_bracket.replace_all(&clean, "");
    let clean = re_explicit.replace_all(&clean, "");
    let clean = re_official.replace_all(&clean, "");
    let clean = re_video.replace_all(&clean, "");
    let clean = re_dash.replace_all(&clean, "");
    clean.trim().to_string()
}

fn has_lrc_timestamps(value: &str) -> bool {
    let re = Regex::new(r"(?m)^\[\d{1,2}:\d{2}(?:[.:]\d{1,3})?\]").unwrap();
    re.is_match(value)
}

fn parse_lrc(lrc: &str) -> Vec<LyricsLine> {
    let mut lines = Vec::new();
    let re = Regex::new(r"\[(\d{1,2}):(\d{1,2}(?:\.\d+)?)\](.*)").unwrap();

    for raw_line in lrc.lines() {
        if let Some(caps) = re.captures(raw_line) {
            let min: i64 = caps[1].parse().unwrap_or(0);
            let sec: f64 = caps[2].parse().unwrap_or(0.0);
            let text = caps[3].trim().to_string();

            if !text.is_empty() {
                let time_ms = (min * 60 * 1000) + (sec * 1000.0) as i64;
                lines.push(LyricsLine { time_ms, text });
            }
        }
    }
    lines.sort_by_key(|l| l.time_ms);
    lines
}

pub mod htmlescape {
    pub fn decode_html(s: &str) -> Option<String> {
        let mut result = s.to_string();
        result = result.replace("&quot;", "\"");
        result = result.replace("&apos;", "'");
        result = result.replace("&lt;", "<");
        result = result.replace("&gt;", ">");
        result = result.replace("&amp;", "&");
        result = result.replace("&#39;", "'");
        result = result.replace("&nbsp;", " ");
        Some(result)
    }
}
