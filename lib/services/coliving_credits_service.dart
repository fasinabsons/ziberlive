import 'package:flutter/material.dart';

class ColivingCreditsService {
  int _credits = 0;
  final List<Map<String, dynamic>> _history = [];
  final Map<String, int> _leaderboard = {};

  int get credits => _credits;
  List<Map<String, dynamic>> get history => _history;
  Map<String, int> get leaderboard => _leaderboard;

  void earn(String userId, int amount, String reason) {
    _credits += amount;
    _history.add({'userId': userId, 'amount': amount, 'reason': reason, 'timestamp': DateTime.now().millisecondsSinceEpoch});
    _leaderboard[userId] = (_leaderboard[userId] ?? 0) + amount;
  }

  void redeem(String userId, int amount, String reason, {bool adminApproved = false}) {
    if (_credits >= amount && adminApproved) {
      _credits -= amount;
      _history.add({'userId': userId, 'amount': -amount, 'reason': reason, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'approved': adminApproved});
      _leaderboard[userId] = (_leaderboard[userId] ?? 0) - amount;
    }
  }
}

class CreditsLeaderboardWidget extends StatelessWidget {
  final Map<String, int> leaderboard;
  const CreditsLeaderboardWidget({required this.leaderboard, super.key});
  @override
  Widget build(BuildContext context) {
    final sorted = leaderboard.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, idx) {
        final entry = sorted[idx];
        return ListTile(
          leading: CircleAvatar(child: Text('#${idx + 1}')),
          title: Text(entry.key),
          trailing: Text('${entry.value} pts'),
        );
      },
    );
  }
}

class ColivingCreditsLeaderboard {
  final Map<String, int> _userCredits = {};

  void updateCredits(String userId, int credits) {
    _userCredits[userId] = credits;
  }

  List<MapEntry<String, int>> getLeaderboard() {
    final entries = _userCredits.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
