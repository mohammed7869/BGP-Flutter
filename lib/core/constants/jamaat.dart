/// Jamaat constants for different Jamaats in Poona
/// This enum is shared with the API to ensure consistency
class Jamaat {
  static const int baramati = 1;
  static const int fakhriMohalla = 2;
  static const int zainiMohalla = 3;
  static const int kalimiMohalla = 4;
  static const int ahmednagar = 5;
  static const int imadiMohalla = 6;
  static const int kasarwadi = 7;
  static const int khadki = 8;
  static const int lonavala = 9;
  static const int mufaddalMohalla = 10;
  static const int poona = 11;
  static const int saifeeMohallah = 12;
  static const int taiyebiMohalla = 13;
  static const int fatemiMohalla = 14;

  /// Jamaat text list for display
  static const List<JamaatItem> jamaatList = [
    JamaatItem(text: 'BARAMATI', id: 1),
    JamaatItem(text: 'FAKHRI MOHALLA (POONA)', id: 2),
    JamaatItem(text: 'ZAINI MOHALLA (POONA)', id: 3),
    JamaatItem(text: 'KALIMI MOHALLA (POONA)', id: 4),
    JamaatItem(text: 'AHMEDNAGAR', id: 5),
    JamaatItem(text: 'IMADI MOHALLA (POONA)', id: 6),
    JamaatItem(text: 'KASARWADI', id: 7),
    JamaatItem(text: 'KHADKI (POONA)', id: 8),
    JamaatItem(text: 'LONAVALA', id: 9),
    JamaatItem(text: 'MUFADDAL MOHALLA (POONA)', id: 10),
    JamaatItem(text: 'POONA', id: 11),
    JamaatItem(text: 'SAIFEE MOHALLAH (POONA)', id: 12),
    JamaatItem(text: 'TAIYEBI MOHALLA (POONA)', id: 13),
    JamaatItem(text: 'FATEMI MOHALLA (POONA)', id: 14),
  ];

  /// Gets jamaat text from ID
  static String getJamaatText(int? jamaatId) {
    switch (jamaatId) {
      case baramati:
        return 'BARAMATI';
      case fakhriMohalla:
        return 'FAKHRI MOHALLA (POONA)';
      case zainiMohalla:
        return 'ZAINI MOHALLA (POONA)';
      case kalimiMohalla:
        return 'KALIMI MOHALLA (POONA)';
      case ahmednagar:
        return 'AHMEDNAGAR';
      case imadiMohalla:
        return 'IMADI MOHALLA (POONA)';
      case kasarwadi:
        return 'KASARWADI';
      case khadki:
        return 'KHADKI (POONA)';
      case lonavala:
        return 'LONAVALA';
      case mufaddalMohalla:
        return 'MUFADDAL MOHALLA (POONA)';
      case poona:
        return 'POONA';
      case saifeeMohallah:
        return 'SAIFEE MOHALLAH (POONA)';
      case taiyebiMohalla:
        return 'TAIYEBI MOHALLA (POONA)';
      case fatemiMohalla:
        return 'FATEMI MOHALLA (POONA)';
      default:
        return 'Unknown';
    }
  }

  /// Gets jamaat ID from text
  static int? getJamaatId(String? jamaatText) {
    switch (jamaatText?.trim()) {
      case 'BARAMATI':
        return baramati;
      case 'FAKHRI MOHALLA (POONA)':
        return fakhriMohalla;
      case 'ZAINI MOHALLA (POONA)':
        return zainiMohalla;
      case 'KALIMI MOHALLA (POONA)':
        return kalimiMohalla;
      case 'AHMEDNAGAR':
        return ahmednagar;
      case 'IMADI MOHALLA (POONA)':
        return imadiMohalla;
      case 'KASARWADI':
        return kasarwadi;
      case 'KHADKI (POONA)':
        return khadki;
      case 'LONAVALA':
        return lonavala;
      case 'MUFADDAL MOHALLA (POONA)':
        return mufaddalMohalla;
      case 'POONA':
        return poona;
      case 'SAIFEE MOHALLAH (POONA)':
        return saifeeMohallah;
      case 'TAIYEBI MOHALLA (POONA)':
        return taiyebiMohalla;
      case 'FATEMI MOHALLA (POONA)':
        return fatemiMohalla;
      default:
        return null;
    }
  }
}

/// Jamaat item model for UI display
class JamaatItem {
  final String text;
  final int id;

  const JamaatItem({
    required this.text,
    required this.id,
  });
}

