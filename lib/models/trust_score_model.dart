import 'dart:convert';

class TrustScoreEntry {
  final DateTime timestamp;
  final String changeReason;
  final int pointChange;

  TrustScoreEntry({
    required this.timestamp,
    required this.changeReason,
    required this.pointChange,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'changeReason': changeReason,
      'pointChange': pointChange,
    };
  }

  factory TrustScoreEntry.fromJson(Map<String, dynamic> json) {
    return TrustScoreEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      changeReason: json['changeReason'] as String,
      pointChange: json['pointChange'] as int,
    );
  }
}

class TrustScore {
  final String id; // Can be userId
  final String userId;
  final int score; // 0-100
  final List<TrustScoreEntry> history;

  TrustScore({
    required this.id,
    required this.userId,
    required this.score,
    List<TrustScoreEntry>? history,
  }) : history = history ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'score': score,
      'history': history.map((entry) => entry.toJson()).toList(),
    };
  }

  factory TrustScore.fromJson(Map<String, dynamic> json) {
    return TrustScore(
      id: json['id'] as String,
      userId: json['userId'] as String,
      score: json['score'] as int,
      history: (json['history'] as List<dynamic>)
          .map((entryJson) => TrustScoreEntry.fromJson(entryJson as Map<String, dynamic>))
          .toList(),
    );
  }

  TrustScore copyWith({
    String? id,
    String? userId,
    int? score,
    List<TrustScoreEntry>? history,
  }) {
    return TrustScore(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      history: history ?? this.history,
    );
  }
}
