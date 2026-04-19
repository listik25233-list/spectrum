import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/core/db/isar_service.dart';
import 'package:spectrum/core/db/schemas/theme_settings.dart';
import 'package:spectrum/core/db/schemas/cache_settings.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/settings/storage_service.dart';

/// Manage full theme state and persistence
class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(ThemeSettings()) {
    _load();
  }

  Future<void> _load() async {
    final isar = IsarService.instance;
    final settings = await isar.themeSettings.get(0);
    if (settings != null) {
      state = settings;
      _sync();
    }
  }

  void _sync() {
    SpectrumColors.applyTheme(
      bg: Color(state.backgroundColor),
      surf: Color(state.surfaceColor),
      crd: Color(state.cardColor),
      primary: Color(state.accentColor),
      textP: Color(state.textPrimaryColor),
      textS: Color(state.textSecondaryColor),
      brdr: Color(state.borderColor),
    );
  }

  Future<void> updateColor(String key, Color color) async {
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final settings = await isar.themeSettings.get(0) ?? ThemeSettings();

      switch (key) {
        case 'bg':
          settings.backgroundColor = color.value;
          break;
        case 'surf':
          settings.surfaceColor = color.value;
          break;
        case 'crd':
          settings.cardColor = color.value;
          break;
        case 'accent':
          settings.accentColor = color.value;
          break;
        case 'textP':
          settings.textPrimaryColor = color.value;
          break;
        case 'textS':
          settings.textSecondaryColor = color.value;
          break;
        case 'border':
          settings.borderColor = color.value;
          break;
      }

      await isar.themeSettings.put(settings);
      state = settings;
      _sync();
    });
  }

  Future<void> reset() async {
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final settings = ThemeSettings();
      await isar.themeSettings.put(settings);
      state = settings;
      _sync();
    });
  }
}

final spectrumThemeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  return ThemeNotifier();
});

/// Legacy compatibility
final accentColorProvider = Provider<Color>((ref) {
  return Color(ref.watch(spectrumThemeProvider).accentColor);
});

class GenericPersistentNotifier<T> extends StateNotifier<T> {
  final String storageKey;
  final PersistentSettingsService _storage;
  final T Function(String) parser;
  final String Function(T) serializer;

  GenericPersistentNotifier(
    this._storage,
    this.storageKey,
    T defaultValue,
    this.parser,
    this.serializer,
  ) : super(defaultValue) {
    _init();
  }

  Future<void> _init() async {
    final saved = await _storage.load(storageKey);
    if (saved != null) {
      try {
        state = parser(saved);
      } catch (_) {}
    }
  }

  void updateValue(T newValue) {
    state = newValue;
    _storage.save(storageKey, serializer(newValue));
  }
}

final highQualityAudioProvider =
    StateNotifierProvider<GenericPersistentNotifier<bool>, bool>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'high_quality_audio',
    true,
    (s) => s == 'true',
    (v) => v.toString(),
  );
});

final tidalEnhancementProvider =
    StateNotifierProvider<GenericPersistentNotifier<bool>, bool>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'tidal_enhancement',
    false,
    (s) => s == 'true',
    (v) => v.toString(),
  );
});

final pcOfflineSuperResEnabledProvider =
    StateNotifierProvider<GenericPersistentNotifier<bool>, bool>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'pc_super_res',
    false,
    (s) => s == 'true',
    (v) => v.toString(),
  );
});

final audioSourceProvider =
    StateNotifierProvider<GenericPersistentNotifier<String>, String>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'audio_source',
    'youtube',
    (s) => s,
    (v) => v,
  );
});

final smartCrossfadeEnabledProvider =
    StateNotifierProvider<GenericPersistentNotifier<bool>, bool>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'crossfade_enabled',
    false,
    (s) => s == 'true',
    (v) => v.toString(),
  );
});

final crossfadeDurationProvider =
    StateNotifierProvider<GenericPersistentNotifier<int>, int>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'crossfade_duration',
    6,
    (s) => int.tryParse(s) ?? 6,
    (v) => v.toString(),
  );
});

final volumeProvider =
    StateNotifierProvider<GenericPersistentNotifier<double>, double>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'master_volume',
    1.0,
    (s) => double.tryParse(s) ?? 1.0,
    (v) => v.toString(),
  );
});

final replayGainEnabledProvider =
    StateNotifierProvider<GenericPersistentNotifier<bool>, bool>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'replay_gain',
    true,
    (s) => s == 'true',
    (v) => v.toString(),
  );
});

/// Manage cache limits and notifications
class CacheNotifier extends StateNotifier<CacheSettings> {
  final Ref _ref;
  CacheNotifier(this._ref) : super(CacheSettings()) {
    _load();
  }

  Future<void> _load() async {
    final isar = IsarService.instance;
    final settings = await isar.cacheSettings.get(1); // Single settings object
    if (settings != null) {
      state = settings;
    } else {
      // Create default
      await isar.writeTxn(() async {
        await isar.cacheSettings.put(state);
      });
    }
  }

  Future<void> updateLimit(double gb) async {
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      state.maxCacheSizeGb = gb;
      await isar.cacheSettings.put(state);
    });
    state = state; // Trigger UI update (Isar objects are mutable but we need a new state ref or manual trigger)
    
    // Check if we need to clean up immediately
    _ref.read(storageServiceProvider).autoCleanupCache();
  }

  Future<void> toggleNotifications(bool enabled) async {
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      state.notificationsEnabled = enabled;
      await isar.cacheSettings.put(state);
    });
    state = state;
  }
}

final cacheSettingsProvider =
    StateNotifierProvider<CacheNotifier, CacheSettings>((ref) {
  return CacheNotifier(ref);
});
final miniPlayerVisibilityProvider = StateProvider<bool>((ref) => true);
final fullPlayerOpenProvider = StateProvider<bool>((ref) => false);

final neuralRadioEnabledProvider =
    StateNotifierProvider<GenericPersistentNotifier<bool>, bool>((ref) {
  return GenericPersistentNotifier(
    ref.read(persistentSettingsProvider),
    'neural_radio_enabled',
    true,
    (s) => s == 'true',
    (v) => v.toString(),
  );
});
