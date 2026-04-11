import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/live_session.dart';
import 'agora_service.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiveSessionProvider
//
// Architecture:
//   • Session list & metadata  → REST backend  (ApiService)
//   • Real-time chat & viewer count → Firebase Firestore
//   • Video / Audio transport  → Agora RTC Engine (plug in via LiveStreamService)
//
// Agora integration points are marked with TODO(agora) comments.
// Install agora_rtc_engine and replace the mock stubs below.
// ─────────────────────────────────────────────────────────────────────────────

class LiveSessionProvider extends ChangeNotifier {
  // ── Firestore ──────────────────────────────────────────────────────────────
  final _db = FirebaseFirestore.instance;
  static const _col = 'live_sessions';

  // ── State ──────────────────────────────────────────────────────────────────
  List<LiveSession> _sessions       = [];
  LiveSession?      _activeSession;
  List<ChatMessage> _messages       = [];
  final List<RaisedHand>  _raisedHands    = [];
  final List<FloatingReaction> _reactions = [];

  bool _isLoading    = false;
  bool _isGoingLive  = false;
  bool _isAudioMuted = false;
  bool _isVideoOff   = false;
  bool _hasRaisedHand = false;

  NetworkQuality _networkQuality = NetworkQuality.unknown;
  String? _error;

  // ── Subscriptions ──────────────────────────────────────────────────────────
  StreamSubscription? _chatSub;
  StreamSubscription? _metaSub;
  StreamSubscription? _sessionListSub; // real-time session list
  Timer? _durationTimer;
  Timer? _reactionCleanupTimer;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<LiveSession>      get sessions        => _sessions;
  List<LiveSession>      get liveSessions    => _sessions.where((s) => s.isLive).toList();
  List<LiveSession>      get upcomingSessions => _sessions.where((s) => s.isScheduled).toList();
  LiveSession?           get activeSession   => _activeSession;
  List<ChatMessage>      get messages        => _messages;
  List<RaisedHand>       get raisedHands     => _raisedHands;
  List<FloatingReaction> get reactions       => _reactions;

  bool           get isLoading       => _isLoading;
  bool           get isGoingLive     => _isGoingLive;
  bool           get isAudioMuted    => _isAudioMuted;
  bool           get isVideoOff      => _isVideoOff;
  bool           get hasRaisedHand   => _hasRaisedHand;
  NetworkQuality get networkQuality  => _networkQuality;
  String?        get error           => _error;

  // ── Session List — Firestore real-time listener ────────────────────────────
  // Called once on startup. Firestore pushes updates the instant a trainer
  // creates, goes live, or ends a session — no polling needed.
  Future<void> fetchSessions() async {
    if (_sessionListSub != null) return; // already listening
    _isLoading = true;
    _error = null;
    notifyListeners();

    _sessionListSub = _db
        .collection(_col)
        .where('status', whereIn: ['live', 'scheduled'])
        .orderBy('scheduled_at', descending: false)
        .snapshots()
        .listen(
          (snap) {
            _sessions = snap.docs.map((doc) {
              final data = {...doc.data(), 'id': doc.id};
              // Firestore Timestamps → ISO strings for fromJson
              for (final key in ['scheduled_at', 'started_at', 'ended_at', 'created_at']) {
                final v = data[key];
                if (v is Timestamp) data[key] = v.toDate().toIso8601String();
              }
              return LiveSession.fromJson(Map<String, dynamic>.from(data));
            }).toList();
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Failed to load sessions.';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // ── Trainer: Schedule a Session ────────────────────────────────────────────
  Future<String?> scheduleSession({
    required String trainerId,
    required String trainerName,
    required String title,
    required String description,
    required String category,
    required DateTime scheduledAt,
    required bool isRecorded,
    required List<String> tags,
  }) async {
    try {
      final res = await ApiService.post('/live/sessions', {
        'trainer_name': trainerName,
        'title':        title,
        'description':  description,
        'category':     category,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_recorded':  isRecorded,
        'tags':         tags,
      });

      final id = res['id'] as String? ?? const Uuid().v4();
      final session = LiveSession(
        id:          id,
        trainerId:   trainerId,
        trainerName: trainerName,
        title:       title,
        description: description,
        category:    category,
        status:      SessionStatus.scheduled,
        scheduledAt: scheduledAt,
        isRecorded:  isRecorded,
        tags:        tags,
      );
      _sessions.insert(0, session);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to schedule session: $e';
    }
  }

  // ── Trainer: Go Live ───────────────────────────────────────────────────────
  Future<String?> goLive({
    required String trainerId,
    required String trainerName,
    String? sessionId, // null = instant go-live (no pre-scheduled session)
    String title = 'Live Session',
    String category = 'Workout',
  }) async {
    _isGoingLive = true;
    _error = null;
    notifyListeners();

    try {
      // Get Agora token + channel name from backend
      final res = await ApiService.post('/live/start', {
        'session_id': sessionId ?? 'instant',
      });

      final channelName = res['channel'] as String? ??
          'pn_${const Uuid().v4().substring(0, 8)}';
      final agoraToken = res['agora_token'] as String?;
      final agoraAppId = res['app_id'] as String? ?? '';

      // Agora broadcaster join (runs only when agora_rtc_engine is installed):
      await AgoraService.joinAsBroadcaster(channelName, agoraToken, agoraAppId);
      AgoraService.onNetworkQuality = (q) => setNetworkQuality(q);

      LiveSession session;
      if (sessionId != null) {
        final idx = _sessions.indexWhere((s) => s.id == sessionId);
        session = _sessions[idx].copyWith(
          status:           SessionStatus.live,
          startedAt:        DateTime.now(),
          agoraChannelName: channelName,
        );
        _sessions[idx] = session;
      } else {
        session = LiveSession(
          id:               const Uuid().v4(),
          trainerId:        trainerId,
          trainerName:      trainerName,
          title:            title,
          description:      '',
          category:         category,
          status:           SessionStatus.live,
          scheduledAt:      DateTime.now(),
          startedAt:        DateTime.now(),
          agoraChannelName: channelName,
        );
        _sessions.insert(0, session);
      }

      _activeSession = session;
      _isAudioMuted  = false;
      _isVideoOff    = false;
      _messages.clear();
      _raisedHands.clear();

      // Firestore: update session doc for real-time watchers
      await _db.collection(_col).doc(session.id).set({
        ...session.toJson(),
        'started_at':    FieldValue.serverTimestamp(),
        'agora_channel': channelName,
      }, SetOptions(merge: true));

      _subscribeChatStream(session.id);
      _subscribeMetaStream(session.id);
      _startViewerCountSimulation(session.id);

      _isGoingLive = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isGoingLive = false;
      _error = 'Failed to go live: $e';
      notifyListeners();
      return _error;
    }
  }

  // ── Trainer: End Session ───────────────────────────────────────────────────
  Future<void> endSession() async {
    if (_activeSession == null) return;

    await AgoraService.leaveChannel();

    final ended = _activeSession!.copyWith(
      status:  SessionStatus.ended,
      endedAt: DateTime.now(),
    );

    final idx = _sessions.indexWhere((s) => s.id == ended.id);
    if (idx >= 0) _sessions[idx] = ended;

    await _db.collection(_col).doc(ended.id).update({
      'status':   'ended',
      'ended_at': FieldValue.serverTimestamp(),
    });

    await ApiService.post('/live/end/${ended.id}', {});

    _cleanup();
    notifyListeners();
  }

  // ── Viewer: Join Session ───────────────────────────────────────────────────
  Future<String?> joinSession(LiveSession session, String userId) async {
    try {
      // Get Agora audience token from backend
      if (session.agoraChannelName != null) {
        final res = await ApiService.post('/live/join', {
          'session_id': session.id,
          'channel':    session.agoraChannelName,
        });
        final agoraToken = res['agora_token'] as String?;
        final appId      = res['app_id']      as String? ?? '';
        final uid        = res['uid']         as int?    ?? 0;
        await AgoraService.joinAsAudience(
          session.agoraChannelName!, agoraToken, appId, uid,
        );
      }

      _activeSession  = session;
      _messages.clear();
      _hasRaisedHand  = false;

      // Increment viewer count in Firestore
      await _db.collection(_col).doc(session.id).update({
        'viewer_count': FieldValue.increment(1),
      });

      _subscribeChatStream(session.id);
      _subscribeMetaStream(session.id);

      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to join session: $e';
    }
  }

  // ── Viewer: Leave Session ──────────────────────────────────────────────────
  Future<void> leaveSession() async {
    if (_activeSession == null) return;

    await AgoraService.leaveChannel();

    try {
      await _db.collection(_col).doc(_activeSession!.id).update({
        'viewer_count': FieldValue.increment(-1),
      });
    } catch (_) {}

    _cleanup();
    notifyListeners();
  }

  // ── Send Chat Message ──────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String sessionId,
    required String userId,
    required String userName,
    required String text,
    bool isTrainer = false,
  }) async {
    if (text.trim().isEmpty) return;

    final msg = ChatMessage(
      id:        const Uuid().v4(),
      sessionId: sessionId,
      userId:    userId,
      userName:  userName,
      text:      text.trim(),
      timestamp: DateTime.now(),
      type:      MessageType.text,
      isTrainer: isTrainer,
    );

    // Optimistic update
    _messages.add(msg);
    notifyListeners();

    // Persist to Firestore sub-collection
    await _db
        .collection(_col)
        .doc(sessionId)
        .collection('messages')
        .doc(msg.id)
        .set(msg.toJson());
  }

  // ── Send Reaction ──────────────────────────────────────────────────────────
  void sendReaction(String emoji, String userId) {
    final reaction = FloatingReaction(
      emoji:     emoji,
      userId:    userId,
      timestamp: DateTime.now(),
      startX:    Random().nextDouble() * 0.6 + 0.2,
    );
    _reactions.add(reaction);
    notifyListeners();

    // Auto-remove after animation completes (3s)
    Future.delayed(const Duration(seconds: 3), () {
      _reactions.removeWhere((r) =>
          r.userId == reaction.userId && r.timestamp == reaction.timestamp);
      notifyListeners();
    });

    // Broadcast reaction via Firestore (ephemeral, not stored permanently)
    if (_activeSession != null) {
      _db.collection(_col).doc(_activeSession!.id)
          .collection('reactions')
          .add({'emoji': emoji, 'user_id': userId, 'ts': FieldValue.serverTimestamp()});
    }
  }

  // ── Raise / Lower Hand ────────────────────────────────────────────────────
  Future<void> raiseHand(String userId, String userName) async {
    _hasRaisedHand = !_hasRaisedHand;
    notifyListeners();

    if (_activeSession == null) return;

    if (_hasRaisedHand) {
      await _db.collection(_col).doc(_activeSession!.id)
          .collection('raised_hands')
          .doc(userId)
          .set({'user_id': userId, 'user_name': userName, 'raised_at': FieldValue.serverTimestamp()});
    } else {
      await _db.collection(_col).doc(_activeSession!.id)
          .collection('raised_hands')
          .doc(userId)
          .delete();
    }
  }

  // ── Trainer: Dismiss Raised Hand ──────────────────────────────────────────
  Future<void> dismissRaisedHand(String userId) async {
    _raisedHands.removeWhere((h) => h.userId == userId);
    notifyListeners();
    if (_activeSession != null) {
      await _db.collection(_col).doc(_activeSession!.id)
          .collection('raised_hands').doc(userId).delete();
    }
  }

  // ── Trainer: Toggle Audio ──────────────────────────────────────────────────
  void toggleAudio() {
    _isAudioMuted = !_isAudioMuted;
    AgoraService.muteLocalAudio(_isAudioMuted);
    notifyListeners();
  }

  // ── Trainer: Toggle Video ──────────────────────────────────────────────────
  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    AgoraService.muteLocalVideo(_isVideoOff);
    notifyListeners();
  }

  // ── Network Quality ───────────────────────────────────────────────────────
  // Called by Agora SDK callback. Map SDK quality (0-6) to our enum.
  void setNetworkQuality(int quality) {
    _networkQuality = NetworkQuality.values[quality.clamp(0, 6)];
    notifyListeners();
  }

  // ── Firestore Subscriptions ───────────────────────────────────────────────
  void _subscribeChatStream(String sessionId) {
    _chatSub?.cancel();
    _chatSub = _db
        .collection(_col)
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(200)
        .snapshots()
        .listen((snap) {
      _messages = snap.docs.map((d) {
        final data = d.data();
        return ChatMessage.fromJson({...data, 'id': d.id});
      }).toList();
      notifyListeners();
    });
  }

  void _subscribeMetaStream(String sessionId) {
    _metaSub?.cancel();
    _metaSub = _db.collection(_col).doc(sessionId).snapshots().listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      final data = snap.data()!;

      // Update viewer count from Firestore
      final viewers = data['viewer_count'] as int? ?? 0;
      if (_activeSession != null && _activeSession!.viewerCount != viewers) {
        _activeSession = _activeSession!.copyWith(viewerCount: viewers);
        notifyListeners();
      }

      // Update session status if trainer ends session
      final status = data['status'] as String?;
      if (status == 'ended' && _activeSession?.isLive == true) {
        _activeSession = _activeSession!.copyWith(status: SessionStatus.ended);
        notifyListeners();
      }
    });
  }

  // ── Mock: Simulate viewer count growing ───────────────────────────────────
  void _startViewerCountSimulation(String sessionId) {
    _durationTimer?.cancel();
    int viewers = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_activeSession?.isLive != true) {
        _durationTimer?.cancel();
        return;
      }
      viewers += Random().nextInt(5) + 1;
      _db.collection(_col).doc(sessionId).update({
        'viewer_count': viewers,
      }).catchError((_) {});
    });
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  void _cleanup() {
    _chatSub?.cancel();
    _metaSub?.cancel();
    _sessionListSub?.cancel();
    _sessionListSub = null;
    _durationTimer?.cancel();
    _reactionCleanupTimer?.cancel();
    _activeSession  = null;
    _messages.clear();
    _raisedHands.clear();
    _reactions.clear();
    _hasRaisedHand  = false;
    _isAudioMuted   = false;
    _isVideoOff     = false;
    _networkQuality = NetworkQuality.unknown;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

}
