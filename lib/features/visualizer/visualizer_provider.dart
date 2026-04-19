import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/src/rust/api/visualizer.dart';
import 'dart:typed_data';

/// Provider for the processed visualizer bands (16 logarithmic bands)
/// Now powered by high-performance Rust-native audio capture.
final visualizerBandsProvider = StreamProvider<List<double>>((ref) {
  // Listen to the FFT stream directly from Rust.
  // Rust handles capture, Hann windowing, and band mapping.
  return startFftStream().map((Float32List bands) {
    return bands.map((e) => e.toDouble()).toList();
  });
});

/// Provider for visualizer play state (legacy, kept for UI compatibility)
final isVisualizerActiveProvider = StateProvider<bool>((ref) => true);
