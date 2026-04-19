import 'package:flutter/foundation.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';

@immutable
class JamMember {
  final String id;
  final String name;
  final bool isHost;
  final String? avatarUrl;

  const JamMember({
    required this.id,
    required this.name,
    this.isHost = false,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isHost': isHost,
        'avatarUrl': avatarUrl,
      };

  factory JamMember.fromJson(Map<String, dynamic> json) => JamMember(
        id: json['id'] as String,
        name: json['name'] as String,
        isHost: (json['isHost'] ?? json['is_host']) as bool? ?? false,
        avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      );
}

@immutable
class JamSession {
  final String id; // Room code
  final String hostId;
  final List<JamMember> members;
  final Track? currentTrack;
  final List<Track> sharedQueue;
  final int positionMs;
  final bool isPlaying;
  final DateTime lastUpdate;

  const JamSession({
    required this.id,
    required this.hostId,
    required this.members,
    this.currentTrack,
    this.sharedQueue = const [],
    this.positionMs = 0,
    this.isPlaying = false,
    required this.lastUpdate,
  });

  JamSession copyWith({
    String? id,
    String? hostId,
    List<JamMember>? members,
    Track? currentTrack,
    List<Track>? sharedQueue,
    int? positionMs,
    bool? isPlaying,
    DateTime? lastUpdate,
  }) {
    return JamSession(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      members: members ?? this.members,
      currentTrack: currentTrack ?? this.currentTrack,
      sharedQueue: sharedQueue ?? this.sharedQueue,
      positionMs: positionMs ?? this.positionMs,
      isPlaying: isPlaying ?? this.isPlaying,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hostId': hostId,
        'members': members.map((m) => m.toJson()).toList(),
        'currentTrack': currentTrack?.toJson(),
        'sharedQueue': sharedQueue.map((t) => t.toJson()).toList(),
        'positionMs': positionMs,
        'isPlaying': isPlaying,
        'lastUpdate': lastUpdate.toUtc().toIso8601String(),
      };

  factory JamSession.fromJson(Map<String, dynamic> json) {
    try {
      final members = (json['members'] as List?)
              ?.map((m) => JamMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [];
      
      // Accept both camelCase and snake_case for hostId
      final hostId = (json['hostId'] ?? json['host_id']) as String? ??
          (members.isNotEmpty
              ? members
                  .firstWhere((m) => m.isHost,
                      orElse: () => members.first)
                  .id
              : '');

      DateTime lastUpdate;
      final raw = json['lastUpdate'] ?? json['last_update'];
      if (raw is String) {
        lastUpdate = DateTime.tryParse(raw) ?? DateTime.now();
      } else if (raw is int) {
        lastUpdate = DateTime.fromMillisecondsSinceEpoch(raw);
      } else {
        lastUpdate = DateTime.now();
      }

      final currentTrackRaw = json['currentTrack'] ?? json['current_track'];
      final sharedQueueRaw = json['sharedQueue'] ?? json['shared_queue'] ?? json['current_queue'];

      return JamSession(
        id: json['id'] as String? ?? '',
        hostId: hostId,
        members: members,
        currentTrack: currentTrackRaw != null
            ? Track.fromJson(currentTrackRaw as Map<String, dynamic>)
            : null,
        sharedQueue: (sharedQueueRaw as List?)
                ?.map((t) {
                   try {
                     return Track.fromJson(t as Map<String, dynamic>);
                   } catch (e) {
                     debugPrint('JamSync: Error parsing individual track: $e');
                     return null;
                   }
                })
                .whereType<Track>()
                .toList() ??
            [],
        positionMs: (json['positionMs'] ?? json['position_ms'] as num?)?.toInt() ?? 0,
        isPlaying: (json['isPlaying'] ?? json['is_playing']) as bool? ?? false,
        lastUpdate: lastUpdate,
      );
    } catch (e, stack) {
      debugPrint('JamSync: CRITICAL Error parsing JamSession: $e\n$stack');
      debugPrint('JamSync: Raw JSON keys were: ${json.keys.toList()}');
      rethrow;
    }
  }

  JamSession mergeWithDelta(Map<String, dynamic> delta) {
    final membersRaw = delta['members'];
    final currentTrackRaw = delta['currentTrack'] ?? delta['current_track'];
    final sharedQueueRaw = delta['sharedQueue'] ?? delta['shared_queue'];
    final positionRaw = delta['positionMs'] ?? delta['position_ms'];
    final playingRaw = delta['isPlaying'] ?? delta['is_playing'];
    final updateRaw = delta['lastUpdate'] ?? delta['last_update'];

    return copyWith(
      members: membersRaw != null 
        ? (membersRaw as List).map((m) => JamMember.fromJson(m)).toList()
        : null,
      currentTrack: currentTrackRaw != null 
        ? Track.fromJson(currentTrackRaw)
        : null, // Note: if currentTrack is explicitly null in JSON, this stays null. Handle if needed.
      sharedQueue: sharedQueueRaw != null
        ? (sharedQueueRaw as List).map((t) => Track.fromJson(t)).toList()
        : null,
      positionMs: (positionRaw as num?)?.toInt(),
      isPlaying: playingRaw as bool?,
      lastUpdate: updateRaw != null ? DateTime.tryParse(updateRaw) : null,
    );
  }
}
