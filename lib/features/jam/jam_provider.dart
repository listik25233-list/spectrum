import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:spectrum/features/jam/jam_models.dart';
import 'package:spectrum/features/jam/jam_network_service.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:uuid/uuid.dart';

final jamProvider = StateNotifierProvider<JamNotifier, JamSession?>((ref) {
  return JamNotifier(ref);
});

final activeJamSessionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(jamNetworkServiceProvider);
  // Auto-refresh periodically
  final timer = Timer.periodic(const Duration(seconds: 10), (t) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  return service.fetchActiveSessions();
});

class JamNotifier extends StateNotifier<JamSession?> {
  final Ref _ref;
  final _log = Logger();
  Timer? _syncTimer;
  StreamSubscription<JamSession>? _socketSub;
  StreamSubscription<Map<String, dynamic>>? _deltaSub;
  bool _isConnecting = false;
  String? _myMemberId; // Track our identity across sessions
  
  // Local subscriptions to player changes for the host
  ProviderSubscription? _playingSub;
  ProviderSubscription? _trackSub;

  int? _lastSyncedQueueHash; // Optimized sync: only send queue when it changes

  JamNotifier(this._ref) : super(null);

  String? get myMemberId => _myMemberId;
  bool get isConnecting => _isConnecting;
  JamNetworkService get _network => _ref.read(jamNetworkServiceProvider);

  /// Generate a short room code for the Jam session
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = DateTime.now().millisecondsSinceEpoch;
    return List.generate(5, (index) => chars[(rnd + index) % chars.length])
        .join();
  }

  /// Create a new Jam session
  Future<void> createSession() async {
    _isConnecting = true;

    final roomCode = _generateRoomCode();
    _myMemberId = const Uuid().v4();
    final me = JamMember(id: _myMemberId!, name: 'Spectral User', isHost: true);

    final currentTrack = _ref.read(currentTrackProvider);
    final position = _ref.read(playbackPositionProvider);
    final isPlaying = _ref.read(isPlayingProvider);
    final queue = _ref.read(currentQueueProvider);

    final newSession = JamSession(
      id: roomCode,
      hostId: _myMemberId!,
      members: [me],
      currentTrack: currentTrack,
      sharedQueue: queue,
      positionMs: position.inMilliseconds,
      isPlaying: isPlaying,
      lastUpdate: DateTime.now().toUtc(),
    );

    await _network.createSession(newSession);
    state = newSession;

    _isConnecting = false;
    _network.initSocket(newSession.id);
    _startSyncLoop();
  }

  /// Join an existing session
  Future<void> joinSession(String code) async {
    _isConnecting = true;
    state = null; // Clear previous state if any

    _myMemberId = const Uuid().v4();
    final me = JamMember(id: _myMemberId!, name: 'Listener', isHost: false);

    final session = await _network.fetchSession(code.toUpperCase());
    if (session == null) {
      _log.e('JamSync: Failed to fetch session $code via HTTP during join');
    } else {
      _log.i('JamSync: Fetched session $code via HTTP. Queue length: ${session.sharedQueue.length}');
    }

    if (session != null) {
      final updatedMembers = [...session.members, me];
      final joinedSession = session.copyWith(members: updatedMembers);

      // IMPORTANT: When joining as a guest, ONLY update the membership list.
      // Do NOT include currentTrack, sharedQueue, etc., to avoid overwriting host's state.
      final success = await _network.updateSessionState(
          joinedSession.id, 
          {'members': updatedMembers.map((m) => m.toJson()).toList()}
      );
      
      if (success) {
        _log.i('JamSync: Successfully joined room $code as guest. Initializing state.');
        state = joinedSession;
        
        // Aggressively fetch latest full state via HTTP to ensure we have the queue
        unawaited(_syncState());

        _network.initSocket(joinedSession.id);
        _startSyncLoop();
      } else {
        _log.e('JamSync: Failed to update session state (membership) on server.');
      }
    }

    _isConnecting = false;
  }

  void addToQueue(Track track) {
    if (state == null) return;

    // Add to shared state
    final updatedQueue = [...state!.sharedQueue, track];
    state = state!.copyWith(sharedQueue: updatedQueue);

    // If I'm the host, also update the actual audio player
    if (state!.hostId == _myMemberId) {
      _ref.read(audioPlayerServiceProvider).addToQueue(track);
    } else {
      // If I'm a guest, notify the server so the host gets it
      _network.addTrackToQueue(state!.id, track);
    }
  }

  void leaveSession() {
    _syncTimer?.cancel();
    _socketSub?.cancel();
    _deltaSub?.cancel();
    _playingSub?.close();
    _trackSub?.close();
    _network.disposeSocket();
    state = null;
    _myMemberId = null;
  }
  void _startSyncLoop() {
    _syncTimer?.cancel();
    _socketSub?.cancel();
    _deltaSub?.cancel();

    // 1. WebSocket Listener for REAL-TIME updates
    _socketSub = _network.sessionUpdates.listen((serverSession) {
      // Only guests apply sync from server pushes
      if (state != null && state!.hostId != _myMemberId) {
        _applyGuestSync(serverSession);
      }
    });

    _deltaSub = _network.sessionDeltas.listen((delta) {
      if (state != null && state!.hostId != _myMemberId) {
        _log.d('JamSync: Received delta update. Keys: ${delta.keys}');
        final updatedSession = state!.mergeWithDelta(delta);
        _applyGuestSync(updatedSession);
      }
    });

    // 2. Real-time Push for HOST only (listen to player changes)
    if (state != null && state!.hostId == _myMemberId) {
      _playingSub?.close();
      _trackSub?.close();

      _playingSub = _ref.listen(isPlayingProvider, (prev, next) {
        if (state != null && state!.hostId == _myMemberId) {
          _syncState();
        }
      });
      _trackSub = _ref.listen(currentTrackProvider, (prev, next) {
        if (state != null && state!.hostId == _myMemberId) {
          _syncState();
        }
      });
    }

    // 3. Periodic state push for HOST only (heartbeat/pos sync)
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (state == null) {
        timer.cancel();
        return;
      }
      if (state!.hostId == _myMemberId) {
        _syncState();
      }
    });
  }

  /// Force a manual sync with the server
  Future<void> forceRefresh() async {
    _log.i('JamSync: Manual refresh requested.');
    await _syncState();
  }

  Future<void> _syncState() async {
    if (state == null || _myMemberId == null) return;

    final isHost = state!.hostId == _myMemberId;

    if (!isHost) {
       _log.d('JamSync: Guest fetching state via HTTP (Manual/Fallback)');
       final serverSession = await _network.fetchSession(state!.id);
       if (serverSession != null) {
         _log.d('JamSync: HTTP fetch received ${serverSession.sharedQueue.length} tracks');
         _applyGuestSync(serverSession);
       } else {
         _log.w('JamSync: HTTP fetch returned null session');
       }
       return;
    }

    if (isHost) {
      final currentTrack = _ref.read(currentTrackProvider);
      final position = _ref.read(playbackPositionProvider);
      final isPlaying = _ref.read(isPlayingProvider);
      final queue = _ref.read(currentQueueProvider);

      // Detect if we need to send the full queue (optimization)
      final currentQueueHash = Object.hashAll(queue.map((t) => t.spotifyId ?? t.title));
      final bool includeQueue = _lastSyncedQueueHash != currentQueueHash;

      if (includeQueue) {
        _lastSyncedQueueHash = currentQueueHash;
        _log.i('JamSync: Sending FULL queue (${queue.length} tracks)');
      }

      final updatePayload = _buildUpdatePayload(
        currentTrack: currentTrack,
        queue: queue,
        positionMs: position.inMilliseconds,
        isPlaying: isPlaying,
        includeQueue: includeQueue,
      );

      try {
        await _network.updateSessionState(state!.id, updatePayload);
        
        // Fetch current members to see if anyone joined
        final serverSession = await _network.fetchSession(state!.id);
        
        // Update local state to reflect what's on the server
        state = state!.copyWith(
          members: serverSession?.members ?? state!.members,
          currentTrack: currentTrack,
          sharedQueue: queue,
          positionMs: position.inMilliseconds,
          isPlaying: isPlaying,
        );
      } catch (e) {
        _log.w('JamNetwork: Host sync failed: $e');
      }
    }
  }

  /// Build update payload with camelCase keys for the server's update endpoint
  Map<String, dynamic> _buildUpdatePayload({
    Track? currentTrack,
    required List<Track> queue,
    required int positionMs,
    required bool isPlaying,
    required bool includeQueue,
  }) {
    final Map<String, dynamic> payload = {
      'currentTrack': currentTrack?.toJson(),
      'positionMs': positionMs,
      'isPlaying': isPlaying,
      'hostId': _myMemberId,
    };

    if (includeQueue) {
      payload['sharedQueue'] = queue.map((t) => t.toJson()).toList();
    }

    return payload;
  }

  void _applyGuestSync(JamSession serverState) {
    if (state == null) return;
    
    _log.d('JamSync: Applying guest sync from server. Queue: ${serverState.sharedQueue.length} tracks');

    final player = _ref.read(audioPlayerServiceProvider);

    // 1. Sync the Queue
    final currentLocalQueue = _ref.read(currentQueueProvider);
    final serverQueue = serverState.sharedQueue;
    
    // Robust check: don't overwrite with empty if we already had tracks, 
    // unless the server explicitly has a different non-empty queue or we are in a fallback poll
    if (serverQueue.isNotEmpty || currentLocalQueue.isEmpty) {
      if (!_isSameQueue(currentLocalQueue, serverQueue)) {
        _log.i('JamSync: Queue updated to ${serverQueue.length} tracks');
        _ref.read(currentQueueProvider.notifier).state = serverQueue;
      }
    } else {
      _log.d('JamSync: Ignoring potential empty queue overwrite from partial update');
    }

    // 2. Sync active track
    if (serverState.currentTrack != null) {
      final currentLocalTrack = _ref.read(currentTrackProvider);
      if (currentLocalTrack?.spotifyId != serverState.currentTrack?.spotifyId) {
        _log.i('JamSync: Switching track to ${serverState.currentTrack?.title}');
        player.playTrack(serverState.currentTrack!);
      }
    }

    // 3. Playback state sync (Absolute)
    player.ensurePlayingStatus(serverState.isPlaying);

    // 4. Position sync (allow 3s drift)
    final myPos = _ref.read(playbackPositionProvider).inMilliseconds;
    if ((myPos - serverState.positionMs).abs() > 3000) {
      _log.d('JamSync: Seeking to ${serverState.positionMs}ms (diff: ${(myPos - serverState.positionMs).abs()}ms)');
      player.seek(Duration(milliseconds: serverState.positionMs));
    }

    state = serverState;
  }

  bool _isSameQueue(List<Track> q1, List<Track> q2) {
    if (q1.length != q2.length) return false;
    for (var i = 0; i < q1.length; i++) {
      if (q1[i].spotifyId != q2[i].spotifyId) return false;
    }
    return true;
  }
}
