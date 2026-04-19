import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:spectrum/core/db/schemas/track_schema.dart';

class SpectrumAudioHandler extends BaseAudioHandler with SeekHandler {
  mk.Player _player;
  mk.Player get player => _player;

  final List<StreamSubscription> _subscriptions = [];

  SpectrumAudioHandler(this._player) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    _subscriptions.add(_player.stream.playing.listen((playing) {
      _updatePlaybackState();
    }));

    _subscriptions.add(_player.stream.position.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      if (mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    }));

    _subscriptions.add(_player.stream.buffering.listen((buffering) {
      playbackState.add(playbackState.value.copyWith(
        processingState: buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
      ));
    }));

    _updatePlaybackState();
  }

  /// Switches the active player (used for Smart Crossfade)
  void updateActivePlayer(mk.Player nextPlayer) {
    _player = nextPlayer;
    _initSubscriptions();
  }

  void _updatePlaybackState() {
    final playing = _player.state.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToPrevious,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.rewind,
        MediaAction.fastForward,
      },
      androidCompactActionIndices: const [1, 3, 4],
      playing: playing,
      processingState: _player.state.buffering
          ? AudioProcessingState.buffering
          : AudioProcessingState.ready,
    ));
  }

  void updateFromTrack(Track track) {
    mediaItem.add(MediaItem(
      id: track.spotifyId ?? track.title,
      album: track.album ?? '',
      title: track.title,
      artist: track.artist,
      duration: _player.state.duration,
      artUri: track.albumArtUrl != null ? Uri.parse(track.albumArtUrl!) : null,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> rewind() =>
      _player.seek(_player.state.position - const Duration(seconds: 10));

  @override
  Future<void> fastForward() =>
      _player.seek(_player.state.position + const Duration(seconds: 10));

  @override
  Future<void> skipToNext() async => SpeedCommand.next();

  @override
  Future<void> skipToPrevious() async => SpeedCommand.prev();
}

class SpeedCommand {
  static Function()? onNext;
  static Function()? onPrev;

  static void next() => onNext?.call();
  static void prev() => onPrev?.call();
}
