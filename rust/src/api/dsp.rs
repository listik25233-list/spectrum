pub struct AudioProcessor {
    pub restoration_enabled: bool,
    pub volume_db: f64,
}

impl AudioProcessor {
    pub fn generate_mpv_af_string(&self) -> String {
        let mut filters = Vec::new();

        if self.restoration_enabled {
            filters.push("bass=gain=1.2:frequency=100".to_string());
            filters.push("treble=gain=0.3:frequency=12000".to_string());
            filters.push("lowpass=f=20000".to_string());
            filters.push("alimiter=limit=0.95:level_out=0.9".to_string());
        }

        if self.volume_db != 0.0 {
            filters.push(format!("volume={:.2}dB", self.volume_db));
        }

        filters.join(",")
    }
}

pub fn get_restoration_preset() -> String {
    "bass=gain=1.2:frequency=100,treble=gain=0.3:frequency=12000,lowpass=f=20000,alimiter=limit=0.95:level_out=0.9".to_string()
}
