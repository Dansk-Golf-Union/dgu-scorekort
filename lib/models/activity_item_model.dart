import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity types for the feed
enum ActivityType {
  milestone,     // Major HCP milestones (scratch, single-digit, sub-20, sub-30)
  improvement,   // Significant improvement (≥1.0 slag)
  personalBest,  // New personal best HCP
  eagle,         // Eagle scored
  albatross,     // Albatross scored
}

/// Milestone types (for ActivityType.milestone)
enum MilestoneType {
  scratch,      // HCP 0.0
  singleDigit,  // HCP < 10.0
  sub20,        // HCP < 20.0
  sub30,        // HCP < 30.0
}

/// Activity item for the feed
/// Similar structure to FriendProfile and ScoreRecord
class ActivityItem {
  final String id;
  final String userId;
  final String userName;
  final ActivityType type;
  final DateTime timestamp;
  final DateTime createdAt;
  final bool isDismissed;
  final Map<String, dynamic> data;

  ActivityItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.timestamp,
    required this.createdAt,
    this.isDismissed = false,
    required this.data,
  });

  /// Parse from Firestore document
  /// Similar to ScoreRecord.fromJson()
  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityItem(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.improvement,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isDismissed: data['isDismissed'] as bool? ?? false,
      data: data['data'] as Map<String, dynamic>,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'isDismissed': isDismissed,
      'data': data,
    };
  }

  // Getters for type-specific data (similar to FriendProfile getters)
  
  MilestoneType? get milestoneType {
    if (type != ActivityType.milestone) return null;
    return MilestoneType.values.firstWhere(
      (e) => e.name == data['milestoneType'],
      orElse: () => MilestoneType.sub30,
    );
  }

  double? get newHcp => data['newHcp'] as double?;
  double? get oldHcp => data['oldHcp'] as double?;
  double? get delta => data['delta'] as double?;
  double? get previousBest => data['previousBest'] as double?;
  String? get courseName => data['courseName'] as String?;
  int? get holeNumber => data['holeNumber'] as int?;
  int? get par => data['par'] as int?;
  int? get strokes => data['strokes'] as int?;

  /// Get display title for activity
  String getTitle() {
    switch (type) {
      case ActivityType.milestone:
        switch (milestoneType) {
          case MilestoneType.scratch:
            return '🏆 Scratch Handicap!';
          case MilestoneType.singleDigit:
            return '🎯 Single-Digit Handicap!';
          case MilestoneType.sub20:
            return '⭐ Under 20 Handicap!';
          case MilestoneType.sub30:
            return '🌟 Under 30 Handicap!';
          default:
            return '🎉 Milestone!';
        }
      case ActivityType.improvement:
        return '📉 Stor forbedring!';
      case ActivityType.personalBest:
        return '🏅 Ny personlig rekord!';
      case ActivityType.eagle:
        return '🦅 Eagle!';
      case ActivityType.albatross:
        return '🦅🦅 Albatross!';
    }
  }

  /// Get display message for activity
  String getMessage() {
    switch (type) {
      case ActivityType.milestone:
        return '$userName nåede HCP ${newHcp?.toStringAsFixed(1)} på $courseName';
      case ActivityType.improvement:
        return '$userName forbedrede sig med ${delta?.abs().toStringAsFixed(1)} slag til HCP ${newHcp?.toStringAsFixed(1)}';
      case ActivityType.personalBest:
        return '$userName satte ny personlig rekord: HCP ${newHcp?.toStringAsFixed(1)}';
      case ActivityType.eagle:
        return '$userName scorede eagle på hul $holeNumber (par $par) på $courseName';
      case ActivityType.albatross:
        return '$userName scorede albatross på hul $holeNumber (par $par) på $courseName!';
    }
  }

  @override
  String toString() {
    return 'ActivityItem(id: $id, user: $userName, type: $type, timestamp: $timestamp)';
  }
}

