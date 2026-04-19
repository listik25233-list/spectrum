import 'package:equatable/equatable.dart';

class JamSession extends Equatable {
  final String? sessionId;
  final bool isHost;
  final String? currentTrackId;
  final double playbackPosition; // в секундах
  final bool isPlaying;
  final List<String> participants;
  final String? hostName;

  const JamSession({
    this.sessionId,
    this.isHost = false,
    this.currentTrackId,
    this.playbackPosition = 0.0,
    this.isPlaying = false,
    this.participants = const [],
    this.hostName,
  });

  JamSession copyWith({
    String? sessionId,
    bool? isHost,
    String? currentTrackId,
    double? playbackPosition,
    bool? isPlaying,
    List<String>? participants,
    String? hostName,
  }) {
    return JamSession(
      sessionId: sessionId ?? this.sessionId,
      isHost: isHost ?? this.isHost,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      isPlaying: isPlaying ?? this.isPlaying,
      participants: participants ?? this.participants,
      hostName: hostName ?? this.hostName,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        isHost,
        currentTrackId,
        playbackPosition,
        isPlaying,
        participants,
        hostName,
      ];
}
