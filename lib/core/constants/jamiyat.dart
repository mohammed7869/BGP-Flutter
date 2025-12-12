/// Jamiyat constants - Currently only Poona exists
/// This enum is shared with the API to ensure consistency
class Jamiyat {
  static const int poona = 1;

  /// Jamiyat text list for display
  static const List<JamiyatItem> jamiyatList = [
    JamiyatItem(text: 'Poona', id: 1),
  ];

  /// Gets jamiyat text from ID
  static String getJamiyatText(int? jamiyatId) {
    switch (jamiyatId) {
      case poona:
        return 'Poona';
      default:
        return 'Unknown';
    }
  }

  /// Gets jamiyat ID from text
  static int? getJamiyatId(String? jamiyatText) {
    switch (jamiyatText?.trim()) {
      case 'Poona':
        return poona;
      default:
        return null;
    }
  }
}

/// Jamiyat item model for UI display
class JamiyatItem {
  final String text;
  final int id;

  const JamiyatItem({
    required this.text,
    required this.id,
  });
}


