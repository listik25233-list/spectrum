use std::fs::File;
use symphonia::core::audio::Signal;
use symphonia::core::codecs::{DecoderOptions, CODEC_TYPE_NULL};
use symphonia::core::errors::Error;
use symphonia::core::formats::FormatOptions;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

pub fn calculate_replay_gain(path: String) -> anyhow::Result<f64> {
    let src = File::open(&path)?;
    let hint = Hint::new();

    let mss = symphonia::core::io::MediaSourceStream::new(Box::new(src), Default::default());

    let mut probed = symphonia::default::get_probe().format(&hint, mss, &FormatOptions::default(), &MetadataOptions::default())?;

    let track = probed.format.tracks()
        .iter()
        .find(|t| t.codec_params.codec != CODEC_TYPE_NULL)
        .ok_or_else(|| anyhow::anyhow!("No supported audio tracks found"))?;

    let mut decoder = symphonia::default::get_codecs().make(&track.codec_params, &DecoderOptions::default())?;

    let track_id = track.id;

    // Target loudness is -14 LUFS (Industry standard for streaming)
    let target_lufs = -14.0;
    
    // Initialize the BS.1770 meter
    // We need to know the sample rate
    let sample_rate = track.codec_params.sample_rate.unwrap_or(44100);
    let mut meter = bs1770::ChannelLoudnessMeter::new(sample_rate);
    
    // Note: bs1770 crate might handle only single channel or requires interleaved.
    // Usually we measure all channels. For simplicity, we'll process samples from all channels.
    
    while let Ok(packet) = probed.format.next_packet() {
        if packet.track_id() != track_id {
            continue;
        }

        match decoder.decode(&packet) {
            Ok(decoded) => {
                let spec = *decoded.spec();
                let duration = decoded.capacity() as u64;

                // For ReplayGain, we usually analyze the full track.
                // We'll push samples into the meter.
                // bs1770::ChannelLoudnessMeter expects slices of f32 samples.
                
                match decoded {
                    symphonia::core::audio::AudioBufferRef::F32(buf) => {
                       meter.push(buf.chan(0).iter().cloned());
                    }
                    symphonia::core::audio::AudioBufferRef::S16(buf) => {
                        let f32_samples = buf.chan(0).iter().map(|&s| s as f32 / 32768.0);
                        meter.push(f32_samples);
                    }
                    _ => {
                        // Handle other bit depths if necessary, or skip
                    }
                }
            }
            Err(Error::IoError(_)) => break,
            Err(Error::DecodeError(_)) => continue,
            Err(e) => return Err(anyhow::anyhow!(e)),
        }
    }

    let windows = meter.as_100ms_windows();
    let lufs = bs1770::gated_mean(windows).loudness_lkfs();
    
    // ReplayGain = Target - Measured
    let target_lufs = -14.0;
    let gain = target_lufs - lufs;
    
    Ok(gain as f64)
}
