import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:spectrum/core/db/schemas/track_schema.dart';
import 'package:spectrum/features/jam/jam_models.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

final jamNetworkServiceProvider = Provider((ref) => JamNetworkService());

class JamNetworkService {
  // Replace with your real production IP or domain when ready
  static const _baseUrl = 'http://144.31.26.207:3001/api/jam';
  static const _socketUrl = 'http://144.31.26.207:3001';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 5),
  ));
  final _log = Logger();

  IO.Socket? _socket;
  final _sessionUpdateController = StreamController<JamSession>.broadcast();
  final _sessionDeltaController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<JamSession> get sessionUpdates => _sessionUpdateController.stream;
  Stream<Map<String, dynamic>> get sessionDeltas => _sessionDeltaController.stream;

  void initSocket(String roomId) {
    _socket?.dispose();
    _socket = IO.io(
        _socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) 
            .enableAutoConnect()
            .setExtraHeaders({'Connection': 'upgrade'})
            .build());

    _socket!.onConnect((_) {
      _log.i('JamSocket: Connected to room $roomId');
      _socket!.emit('join-room', roomId);
    });

    _socket!.onConnectError((data) {
      _log.w('JamSocket: Connection error: $data');
    });

    _socket!.onDisconnect((_) {
      _log.i('JamSocket: Disconnected');
    });

    _socket!.on('session-updated', (data) {
      final size = data.toString().length;
      if (data is Map) {
        _log.d('JamSocket: Received full update ($size bytes). Keys: ${data.keys.toList()}');
      }
      try {
        final session = JamSession.fromJson(data);
        _sessionUpdateController.add(session);
      } catch (e, stack) {
        _log.e('JamSocket: Error parsing full update: $e', error: e, stackTrace: stack);
      }
    });

    _socket!.on('session-delta', (data) {
      final size = data.toString().length;
      if (data is Map) {
        _log.d('JamSocket: Received DELTA ($size bytes). Keys: ${data.keys.toList()}');
        _sessionDeltaController.add(data as Map<String, dynamic>);
      }
    });

    _socket!.connect();
  }

  void disposeSocket() {
    _socket?.dispose();
    _socket = null;
  }

  /// Creates a new session on the server
  Future<void> createSession(JamSession session) async {
    try {
      await _dio.post('$_baseUrl/create', data: session.toJson());
      _log.i('JamNetwork: Created session ${session.id}');
      initSocket(session.id);
    } catch (e) {
      _log.e('JamNetwork: Error creating session: $e');
    }
  }

  /// Updates the server with current host state
  Future<bool> updateSessionState(
      String sessionId, Map<String, dynamic> state) async {
    try {
      final response =
          await _dio.post('$_baseUrl/update/$sessionId', data: state);
      if (response.statusCode != 200) {
        _log.w('JamNetwork: Update failed for $sessionId. Status: ${response.statusCode}, Data: ${response.data}');
      }
      return response.statusCode == 200;
    } catch (e) {
      _log.w('JamNetwork: Exception updating session $sessionId: $e');
      return false;
    }
  }

  /// Fetches the current session state from the server
  Future<JamSession?> fetchSession(String sessionId) async {
    try {
      final response = await _dio.get('$_baseUrl/session/$sessionId');
      if (response.statusCode == 200) {
        return JamSession.fromJson(response.data);
      } else {
        _log.w('JamNetwork: Fetch failed for $sessionId. Status: ${response.statusCode}, Data: ${response.data}');
      }
    } catch (e) {
      _log.e('JamNetwork: Exception fetching session $sessionId: $e');
    }
    return null;
  }

  /// Fetches all active sessions from the server
  Future<List<Map<String, dynamic>>> fetchActiveSessions() async {
    try {
      final response = await _dio.get('$_baseUrl/list');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        _log.w('JamNetwork: List failed. Status: ${response.statusCode}, Data: ${response.data}');
      }
    } catch (e) {
      _log.w('JamNetwork: Exception listing sessions: $e');
    }
    return [];
  }

  /// Sends a track to be added to the shared queue
  Future<void> addTrackToQueue(String sessionId, Track track) async {
    try {
      await _dio.post('$_baseUrl/add-track/$sessionId',
          data: {'track': track.toJson()});
    } catch (e) {
      _log.w('JamNetwork: Error adding track to queue: $e');
    }
  }
}
