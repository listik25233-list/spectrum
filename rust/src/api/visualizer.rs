// Visualizer logic
use parking_lot::RwLock;
use once_cell::sync::Lazy;
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use rustfft::{FftPlanner, num_complex::Complex};
use crate::frb_generated::StreamSink;

static PERSISTENCE: Lazy<RwLock<Vec<f32>>> = Lazy::new(|| RwLock::new(vec![0.0; 16]));
static ADAPTIVE_GAIN: Lazy<RwLock<f32>> = Lazy::new(|| RwLock::new(1.0));

fn _process_fft_data_internal(raw: Vec<f32>, rms: f32) -> Vec<f32> {
    if rms < 0.00001f32 {
        let mut persistence = PERSISTENCE.write();
        for i in 0..16 {
            persistence[i] *= 0.8;
        }
        return persistence.clone();
    }

    // Slow Adaptive Gain Control (Volume Independence)
    // Tracks the master volume slider over a ~1.5 second window to avoid "beat pumping"
    {
        let mut gain = ADAPTIVE_GAIN.write();
        let target_gain = if rms > 0.00001 {
             (0.04 / rms).clamp(1.0, 400.0) 
        } else {
             1.0
        };
        // Alpha 0.01 provides very slow adjustment. 
        // It won't react to individual drum beats, but will smoothly adjust if you lower the volume.
        *gain = *gain * 0.99 + target_gain * 0.01;
    }
    
    let current_gain = *ADAPTIVE_GAIN.read();

    let mut bands = vec![0.0f32; 16];
    let num_bins = raw.len(); 
    let hz_per_bin = 48000.0 / 512.0;

    for i in 0..16 {
        // Logarithmic frequency bounds: 60 Hz to 14,000 Hz
        let freq_start = 60.0 * (14000.0 / 60.0_f32).powf(i as f32 / 16.0);
        let freq_end = 60.0 * (14000.0 / 60.0_f32).powf((i + 1) as f32 / 16.0);

        let bin_start = (freq_start / hz_per_bin) as usize;
        let bin_end = (freq_end / hz_per_bin) as usize;

        let bin_start = bin_start.clamp(1, num_bins - 1);
        let bin_end = bin_end.max(bin_start + 1).clamp(1, num_bins);

        let mut sum = 0.0;
        for b in bin_start..bin_end {
            sum += raw[b];
        }
        
        // Average magnitude for the band
        let mut mag = sum / (bin_end - bin_start) as f32;
        
        // Normalize against player volume using the Slow AGC
        mag *= current_gain;
        
        // Emphasize higher frequencies so treble is visible
        mag *= 1.0 + (i as f32 * 0.4); 
        
        // Convert to decibels with a noise floor of -55dB
        let db = 20.0 * (mag + 1e-9).log10();
        let mut val = (db + 55.0) / 55.0;
        
        // Soft dampening curve for a natural look
        val = val.clamp(0.0, 1.0);
        bands[i] = val * val; // Quadratic easing makes waves look sharper and more precise
    }

    // Individual bar smoothing
    let mut persistence = PERSISTENCE.write();
    for i in 0..16 {
        let val = bands[i];
        if val > persistence[i] {
            persistence[i] = persistence[i] * 0.4 + val * 0.6; // Responsive rise
        } else {
            persistence[i] = persistence[i] * 0.85 + val * 0.15; // Smooth fall
        }
    }
    persistence.clone()
}

// Bridge compatibility - MUST match the signature in frb_generated.rs
pub fn process_fft_data(raw: Vec<f32>) -> Vec<f32> {
    _process_fft_data_internal(raw, 0.1)
}

use std::io::Write;
use std::fs::OpenOptions;

fn log_audit(msg: &str) {
    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .append(true)
        .open("/tmp/audio_audit.log") 
    {
        let _ = writeln!(file, "[{}] {}", chrono::Local::now().format("%H:%M:%S"), msg);
    }
}

use std::process::Command;

fn find_bluetooth_monitor() -> Option<String> {
    // Run pactl to find the active bluez monitor
    let output = Command::new("pactl")
        .args(&["list", "sources", "short"])
        .output()
        .ok()?;
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    for line in stdout.lines() {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 2 {
            let name = parts[1];
            // Look for bluez output monitor (actual music)
            if name.contains("bluez_output") && name.contains(".monitor") {
                return Some(name.to_string());
            }
        }
    }
    None
}

fn hard_patch_isolation() {
    // Ultimate "Null-Sink Daemon" Architecture
    // 1. We create a silent 'black hole' sink for the visualizer.
    // 2. We continuously pipe the player's output into this black hole so the visualizer can see it.
    let script = r#"
        # Ensure the null sink exists
        if ! pactl list sinks short | grep -q "SpectrumVis"; then
            pactl load-module module-null-sink sink_name=SpectrumVis sink_properties=device.description="Spectrum_Internal" > /dev/null 2>&1
        fi

        # Daemon Loop
        while true; do
            sleep 1.0
            # Quietly fan-out the mpv/ALSA player audio to our visualizer sink. 
            # Note: PipeWire renames Flutter's mpv ALSA output to "ALSA plug-in [spectrum]"
            pw-link "ALSA plug-in [spectrum]:output_FL" SpectrumVis:playback_FL > /dev/null 2>&1
            pw-link "ALSA plug-in [spectrum]:output_FR" SpectrumVis:playback_FR > /dev/null 2>&1
            
            # Fallback just in case media_kit natively registers as mpv
            pw-link mpv:output_FL SpectrumVis:playback_FL > /dev/null 2>&1
            pw-link mpv:output_FR SpectrumVis:playback_FR > /dev/null 2>&1
        done
    "#;
    
    let _ = Command::new("sh").arg("-c").arg(script).spawn();
    println!("[Rust Visualizer] Null-Sink Isolation Daemon started (ALSA patch).");
}

pub fn start_fft_stream(sink: StreamSink<Vec<f32>>) -> anyhow::Result<()> {
    // 1. Point the engine firmly at the isolated black-hole monitor.
    std::env::set_var("PULSE_SOURCE", "SpectrumVis.monitor");

    let host = cpal::default_host();
    let mut devices = host.input_devices()?.collect::<Vec<_>>();
    
    // CRITICAL FIX: We MUST select "pulse" explicitly. 
    let device_idx = devices.iter().position(|d| {
        let name = d.name().unwrap_or_default().to_lowercase();
        name == "pulse"
    }).or_else(|| {
        devices.iter().position(|d| {
            let name = d.name().unwrap_or_default().to_lowercase();
            name == "default"
        })
    });

    let device = match device_idx {
        Some(idx) => devices.remove(idx),
        None => host.default_input_device().ok_or_else(|| anyhow::anyhow!("No capture source"))?,
    };

    println!("[Rust Visualizer] Base Capture: {}", device.name().unwrap_or_default());
    
    // Trigger the Hard Patch in the background after we start
    std::thread::spawn(|| {
        std::thread::sleep(std::time::Duration::from_millis(1500));
        hard_patch_isolation();
    });

    let device_name = device.name().unwrap_or_default().to_lowercase();
    let is_virtual = device_name.contains("pulse") || device_name.contains("pipewire") || device_name.contains("default");

    let config: cpal::StreamConfig = device.default_input_config()?.into();
    let channels = config.channels as usize;
    
    let fft_size = 512;
    let mut samples_buffer = vec![0.0; fft_size];
    let mut buffer_idx = 0;
    
    let mut planner = FftPlanner::new();
    let fft = planner.plan_fft_forward(fft_size);
    let window: Vec<f32> = (0..fft_size)
        .map(|i| 0.5 * (1.0 - (2.0 * std::f32::consts::PI * i as f32 / (fft_size - 1) as f32).cos()))
        .collect();

    let stream = device.build_input_stream(
        &config,
        move |data: &[f32], _: &cpal::InputCallbackInfo| {
            // Sensitivity Boost for virtual devices
            let multiplier = if is_virtual { 5.0f32 } else { 1.0f32 };
            
            let mut rms = 0.0;
            if !data.is_empty() {
                for &s in data { 
                    let boosted = s * multiplier;
                    rms += boosted * boosted; 
                }
                rms = (rms / data.len() as f32).sqrt();
            }

            for frame in data.chunks(channels) {
                let mono_sample = (frame.iter().sum::<f32>() / channels as f32) * multiplier;
                samples_buffer[buffer_idx] = mono_sample;
                buffer_idx = (buffer_idx + 1) % fft_size;
                
                if buffer_idx % 256 == 0 {
                    let mut input: Vec<Complex<f32>> = (0..fft_size)
                        .map(|i| {
                            let idx = (buffer_idx + i) % fft_size;
                            Complex { re: samples_buffer[idx] * window[i], im: 0.0 }
                        }).collect();
                    fft.process(&mut input);
                    let magnitudes: Vec<f32> = input.iter().take(fft_size / 2)
                        .map(|c| (c.re * c.re + c.im * c.im).sqrt() / (fft_size as f32).sqrt()).collect();
                    let bands = _process_fft_data_internal(magnitudes, rms);
                    let _ = sink.add(bands);
                }
            }
        },
        |err| eprintln!("Audio error: {}", err),
        None
    )?;

    stream.play()?;
    std::mem::forget(stream);
    Ok(())
}

fn name_match(name: &str) -> bool {
    let n = name.to_lowercase();
    n.contains(".monitor") || n.contains("loopback")
}
