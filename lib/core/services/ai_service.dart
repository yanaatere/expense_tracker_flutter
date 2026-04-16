import '../services/api_client.dart';

class AiService {
  // ── Chat ────────────────────────────────────────────────────────────────────

  /// Send a chat message with conversation history.
  /// Returns the AI reply text.
  static Future<String> chat(
    String message,
    List<Map<String, String>> history,
  ) async {
    final response = await ApiClient.dio.post<Map<String, dynamic>>(
      '/api/ai/chat',
      data: {'message': message, 'history': history},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return data?['reply'] as String? ?? '';
  }

  // ── Monthly report ──────────────────────────────────────────────────────────

  /// Generate an AI narrative for the current month's spending.
  /// Returns the report text.
  static Future<String> monthlyReport() async {
    final response = await ApiClient.dio.post<Map<String, dynamic>>(
      '/api/ai/monthly-report',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return data?['report'] as String? ?? '';
  }

  // ── Budget suggestions ──────────────────────────────────────────────────────

  /// Ask AI to suggest monthly budget limits based on spending history.
  /// Returns a list of `{category: String, limit: double}` maps.
  static Future<List<Map<String, dynamic>>> budgetSuggestions() async {
    final response = await ApiClient.dio.post<Map<String, dynamic>>(
      '/api/ai/budget-suggestions',
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final list = data?['suggestions'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  // ── Receipt scan ────────────────────────────────────────────────────────────

  /// Extract transaction details from a base64-encoded receipt image.
  /// Returns `{amount: double?, title: String?, category: String?, date: String?}`.
  static Future<Map<String, dynamic>> scanReceipt(String base64Image) async {
    final response = await ApiClient.dio.post<Map<String, dynamic>>(
      '/api/ai/scan-receipt',
      data: {'image': base64Image},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return data ?? {};
  }
}
