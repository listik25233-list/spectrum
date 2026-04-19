use image::{DynamicImage, GenericImageView, ImageFormat};
use std::path::Path;
use serde::{Serialize, Deserialize};
use lofty::probe::Probe;
use lofty::prelude::*;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ProcessedImage {
    pub dominant_color_hex: String,
    pub thumbnail_path: String,
    pub blur_hash_subset: String, // Path to 16x16 blurred webp
}

/// Generalized image processing logic
fn process_dynamic_image(img: DynamicImage, base_name: &str, cache_dir: &str) -> anyhow::Result<ProcessedImage> {
    let (width, height) = img.dimensions();

    // 1. Dominant Color Extraction (Sampling 10x10)
    let mut r_sum = 0u64;
    let mut g_sum = 0u64;
    let mut b_sum = 0u64;
    let sample_points = 100;
    
    let step_y = (height / 10).max(1);
    let step_x = (width / 10).max(1);
    
    for y in (0..height).step_by(step_y as usize).take(10) {
        for x in (0..width).step_by(step_x as usize).take(10) {
            let pixel = img.get_pixel(x, y);
            r_sum += pixel[0] as u64;
            g_sum += pixel[1] as u64;
            b_sum += pixel[2] as u64;
        }
    }
    
    let avg_r = (r_sum / sample_points) as u8;
    let avg_g = (g_sum / sample_points) as u8;
    let avg_b = (b_sum / sample_points) as u8;
    
    let hex = format!("#{:02x}{:02x}{:02x}", avg_r, avg_g, avg_b);

    // 2. Generate Thumbnail (200x200)
    let thumb = img.thumbnail(200, 200);
    let thumb_path = format!("{}/{}_thumb.webp", cache_dir, base_name);
    thumb.save_with_format(&thumb_path, ImageFormat::WebP)?;

    // 3. Generate tiny blurred placeholder (16x16)
    let tiny = img.thumbnail(16, 16).blur(2.0);
    let blur_path = format!("{}/{}_blur.webp", cache_dir, base_name);
    tiny.save_with_format(&blur_path, ImageFormat::WebP)?;

    Ok(ProcessedImage {
        dominant_color_hex: hex,
        thumbnail_path: thumb_path,
        blur_hash_subset: blur_path,
    })
}

pub fn process_image(input_path: String, cache_dir: String) -> anyhow::Result<ProcessedImage> {
    let img = image::open(&input_path)?;
    let base_name = Path::new(&input_path).file_stem().unwrap().to_str().unwrap();
    process_dynamic_image(img, base_name, &cache_dir)
}

pub fn extract_and_process_cover(audio_path: String, cache_dir: String) -> anyhow::Result<ProcessedImage> {
    let path = Path::new(&audio_path);
    let prob = Probe::open(path)?;
    let tagged_file = prob.read()?;
    
    let tag = tagged_file.primary_tag()
        .or_else(|| tagged_file.first_tag())
        .ok_or_else(|| anyhow::anyhow!("No tags found"))?;
        
    let picture = tag.pictures().first()
        .ok_or_else(|| anyhow::anyhow!("No cover art found"))?;
        
    let img = image::load_from_memory(picture.data())?;
    let base_name = path.file_stem().unwrap().to_str().unwrap();
    
    process_dynamic_image(img, base_name, &cache_dir)
}
