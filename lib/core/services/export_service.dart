import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

class ExportService {
  /// Fetches all transactions from the API and writes them to a CSV file.
  /// Returns the absolute path of the written file.
  static Future<String> exportTransactionsCsv() async {
    final response = await ApiClient.dio.get<Map<String, dynamic>>(
      '/api/transactions',
      queryParameters: {'limit': 10000},
    );

    final data = response.data?['data'];
    final List<dynamic> raw = data is List ? data : [];

    final rows = <List<dynamic>>[
      // Header row
      ['Date', 'Title', 'Type', 'Category', 'Sub Category', 'Amount', 'Wallet', 'Notes'],
    ];

    for (final item in raw) {
      if (item is! Map) continue;
      rows.add([
        item['transaction_date'] ?? '',
        item['description'] ?? '',
        item['type'] ?? '',
        item['category_name'] ?? '',
        item['sub_category_name'] ?? '',
        item['amount'] ?? '',
        item['wallet_name'] ?? '',
        item['notes'] ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/monex_export.csv');
    await file.writeAsString(csv);
    return file.path;
  }
}
