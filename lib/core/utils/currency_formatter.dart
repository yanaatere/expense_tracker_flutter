import 'package:intl/intl.dart';

/// Formats [amount] according to [currency] into a human-readable string.
/// Supported currencies: IDR, EUR, USD (default).
String formatCurrency(double amount, String currency) {
  switch (currency) {
    case 'IDR':
      return 'Rp. ${NumberFormat('#,##0', 'en_US').format(amount)}';
    case 'EUR':
      return '€ ${NumberFormat('#,##0.##').format(amount)}';
    default:
      return '\$ ${NumberFormat('#,##0.##').format(amount)}';
  }
}
