import 'package:http/http.dart' as http;

enum CardVerificationResult { valid, expired, notFound, error }

class PressCardVerificationService {
  static Future<({CardVerificationResult result, String message, String? validUntil})>
      verifyCard(String username) async {
    final trimmed = username.trim().toLowerCase().replaceAll(' ', '-');

    if (trimmed.isEmpty) {
      return (
        result: CardVerificationResult.error,
        message: 'Nom d\'utilisateur requis',
        validUntil: null,
      );
    }

    try {
      final profileUrl = 'https://camerapixopress.com/members/$trimmed/';
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404 ||
          response.body.contains('Page not found')) {
        return (
          result: CardVerificationResult.notFound,
          message: 'Profil "$trimmed" non trouvé sur Camerapixo Press (IVJA)',
          validUntil: null,
        );
      }

      final body = response.body;
      final lower = body.toLowerCase();

      final validMatch = RegExp(
        r'press\s+id\s+card\s+valid\s+until\s+([A-Za-z]+\s+\d{4})',
        caseSensitive: false,
      ).firstMatch(body);

      final isActive = lower.contains('active') && lower.contains('member');
      final isCertified = lower.contains('certified-journalist') ||
          lower.contains('certified journalist');

      if (validMatch != null) {
        final validUntilStr = validMatch.group(1)!;
        final isStillValid = _isDateInFuture(validUntilStr);

        if (isStillValid) {
          return (
            result: CardVerificationResult.valid,
            message:
                'Carte vérifiée - IVJA${isCertified ? " (Journaliste Certifié)" : ""} - Valide jusqu\'à $validUntilStr',
            validUntil: validUntilStr,
          );
        } else {
          return (
            result: CardVerificationResult.expired,
            message: 'Carte expirée depuis $validUntilStr',
            validUntil: validUntilStr,
          );
        }
      }

      if (isActive) {
        return (
          result: CardVerificationResult.valid,
          message:
              'Membre actif IVJA${isCertified ? " (Journaliste Certifié)" : ""} - Date d\'expiration non trouvée',
          validUntil: null,
        );
      }

      return (
        result: CardVerificationResult.notFound,
        message: 'Profil trouvé mais aucune carte de presse active détectée',
        validUntil: null,
      );
    } catch (e) {
      return (
        result: CardVerificationResult.error,
        message: 'Erreur de connexion: ${e.toString().split(':').first}',
        validUntil: null,
      );
    }
  }

  static bool _isDateInFuture(String dateStr) {
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final parts = dateStr.trim().split(' ');
    if (parts.length != 2) return false;

    final month = months[parts[0].toLowerCase().substring(0, 3)];
    final year = int.tryParse(parts[1]);
    if (month == null || year == null) return false;

    final expiryDate = DateTime(year, month + 1, 0);
    return expiryDate.isAfter(DateTime.now());
  }
}
