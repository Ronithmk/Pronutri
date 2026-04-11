import 'package:flutter/material.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum SessionStatus { scheduled, live, ended }

enum UserRole { trainer, viewer }

/// Maps to Agora's NetworkQuality enum (0-6).
enum NetworkQuality { unknown, excellent, good, fair, poor, veryBad, down }

enum MessageType { text, reaction, system, raisedHand }

// ── LiveSession ────────────────────────────────────────────────────────────

class LiveSession {
  final String id;
  final String trainerId;
  final String trainerName;
  final String? trainerAvatar;
  final String title;
  final String description;
  final String category; // 'Nutrition', 'Workout', 'Yoga', 'Mindfulness', etc.
  final SessionStatus status;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int viewerCount;
  final bool isRecorded;
  final String? thumbnailUrl;
  final String? agoraChannelName; // Set when session goes live
  final String? agoraToken;       // Short-lived RTC token from backend
  final List<String> tags;

  const LiveSession({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    this.trainerAvatar,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.viewerCount = 0,
    this.isRecorded = false,
    this.thumbnailUrl,
    this.agoraChannelName,
    this.agoraToken,
    this.tags = const [],
  });

  bool get isLive      => status == SessionStatus.live;
  bool get isScheduled => status == SessionStatus.scheduled;
  bool get isEnded     => status == SessionStatus.ended;

  Duration get liveDuration {
    if (startedAt == null) return Duration.zero;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  String get formattedDuration {
    final d = liveDuration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'nutrition':  return const Color(0xFF2ECC71);
      case 'workout':    return const Color(0xFFFF6B6B);
      case 'yoga':       return const Color(0xFF9B6DFF);
      case 'mindfulness':return const Color(0xFF1E6EBD);
      case 'cardio':     return const Color(0xFFFFB830);
      default:           return const Color(0xFF5A6A7E);
    }
  }

  LiveSession copyWith({
    SessionStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? viewerCount,
    String? agoraChannelName,
    String? agoraToken,
  }) => LiveSession(
    id:                id,
    trainerId:         trainerId,
    trainerName:       trainerName,
    trainerAvatar:     trainerAvatar,
    title:             title,
    description:       description,
    category:          category,
    status:            status       ?? this.status,
    scheduledAt:       scheduledAt,
    startedAt:         startedAt    ?? this.startedAt,
    endedAt:           endedAt      ?? this.endedAt,
    viewerCount:       viewerCount  ?? this.viewerCount,
    isRecorded:        isRecorded,
    thumbnailUrl:      thumbnailUrl,
    agoraChannelName:  agoraChannelName ?? this.agoraChannelName,
    agoraToken:        agoraToken       ?? this.agoraToken,
    tags:              tags,
  );

  factory LiveSession.fromJson(Map<String, dynamic> j) => LiveSession(
    id:               j['id']            as String,
    trainerId:        j['trainer_id']    as String,
    trainerName:      j['trainer_name']  as String,
    trainerAvatar:    j['trainer_avatar'] as String?,
    title:            j['title']         as String,
    description:      j['description']   as String,
    category:         j['category']      as String,
    status: SessionStatus.values.firstWhere(
      (e) => e.name == (j['status'] as String),
      orElse: () => SessionStatus.scheduled,
    ),
    scheduledAt:      j['scheduled_at'] != null
        ? DateTime.parse(j['scheduled_at'] as String)
        : DateTime.now(),
    startedAt:        j['started_at'] != null ? DateTime.parse(j['started_at'] as String) : null,
    endedAt:          j['ended_at']   != null ? DateTime.parse(j['ended_at']   as String) : null,
    viewerCount:      j['viewer_count'] as int? ?? 0,
    isRecorded:       j['is_recorded']  as bool? ?? false,
    thumbnailUrl:     j['thumbnail_url'] as String?,
    agoraChannelName: j['agora_channel'] as String?,
    agoraToken:       j['agora_token']   as String?,
    tags:             (j['tags'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'trainer_id':     trainerId,
    'trainer_name':   trainerName,
    'trainer_avatar': trainerAvatar,
    'title':          title,
    'description':    description,
    'category':       category,
    'status':         status.name,
    'scheduled_at':   scheduledAt.toIso8601String(),
    'started_at':     startedAt?.toIso8601String(),
    'ended_at':       endedAt?.toIso8601String(),
    'viewer_count':   viewerCount,
    'is_recorded':    isRecorded,
    'thumbnail_url':  thumbnailUrl,
    'agora_channel':  agoraChannelName,
    'agora_token':    agoraToken,
    'tags':           tags,
  };
}

// ── ChatMessage ────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final bool isTrainer;
  final bool isPinned;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.isTrainer = false,
    this.isPinned = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id:          j['id']         as String,
    sessionId:   j['session_id'] as String,
    userId:      j['user_id']    as String,
    userName:    j['user_name']  as String,
    userAvatar:  j['user_avatar'] as String?,
    text:        j['text']       as String,
    timestamp:   DateTime.parse(j['timestamp'] as String),
    type: MessageType.values.firstWhere(
      (e) => e.name == (j['type'] as String? ?? 'text'),
      orElse: () => MessageType.text,
    ),
    isTrainer:   j['is_trainer'] as bool? ?? false,
    isPinned:    j['is_pinned']  as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id':          id,
    'session_id':  sessionId,
    'user_id':     userId,
    'user_name':   userName,
    'user_avatar': userAvatar,
    'text':        text,
    'timestamp':   timestamp.toIso8601String(),
    'type':        type.name,
    'is_trainer':  isTrainer,
    'is_pinned':   isPinned,
  };
}

// ── FloatingReaction ───────────────────────────────────────────────────────

class FloatingReaction {
  final String emoji;
  final String userId;
  final DateTime timestamp;
  final double startX; // 0.0–1.0 relative position

  const FloatingReaction({
    required this.emoji,
    required this.userId,
    required this.timestamp,
    required this.startX,
  });
}

// ── RaisedHand ────────────────────────────────────────────────────────────

class RaisedHand {
  final String userId;
  final String userName;
  final DateTime raisedAt;

  const RaisedHand({
    required this.userId,
    required this.userName,
    required this.raisedAt,
  });
}
