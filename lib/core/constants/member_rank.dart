/// Member rank constants matching the roles in the database
/// This enum is shared with the API to ensure consistency
class MemberRank {
  static const int member = 1;
  static const int captain = 2;
  static const int viceCaptain = 3;
  static const int asstGroupLeader = 4;
  static const int groupLeader = 5;
  static const int majorCaptain = 6;
  static const int resourceAdmin = 7;
  static const int assistantCommander = 8;

  /// Rank text list for display
  static const List<RankItem> rankList = [
    RankItem(text: 'Member', id: 1),
    RankItem(text: 'Captain', id: 2),
    RankItem(text: 'Vice Captain', id: 3),
    RankItem(text: 'Asst. Group Leader', id: 4),
    RankItem(text: 'Group Leader', id: 5),
    RankItem(text: 'Major (Captain)', id: 6),
    RankItem(text: 'Resource Admin', id: 7),
    RankItem(text: 'Assistant Commander', id: 8),
  ];

  /// Gets rank text from role ID
  static String getRankText(int? roleId) {
    switch (roleId) {
      case member:
        return 'Member';
      case captain:
        return 'Captain';
      case viceCaptain:
        return 'Vice Captain';
      case asstGroupLeader:
        return 'Asst. Group Leader';
      case groupLeader:
        return 'Group Leader';
      case majorCaptain:
        return 'Major (Captain)';
      case resourceAdmin:
        return 'Resource Admin';
      case assistantCommander:
        return 'Assistant Commander';
      default:
        return 'Member';
    }
  }

  /// Gets role ID from rank text
  static int? getRoleId(String? rankText) {
    switch (rankText?.trim()) {
      case 'Member':
        return member;
      case 'Captain':
        return captain;
      case 'Vice Captain':
        return viceCaptain;
      case 'Asst. Group Leader':
        return asstGroupLeader;
      case 'Group Leader':
        return groupLeader;
      case 'Major (Captain)':
        return majorCaptain;
      case 'Resource Admin':
        return resourceAdmin;
      case 'Assistant Commander':
        return assistantCommander;
      default:
        return null;
    }
  }
}

/// Rank item model for UI display
class RankItem {
  final String text;
  final int id;

  const RankItem({
    required this.text,
    required this.id,
  });
}


