import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _qtyFormat = NumberFormat('#,##0.##', 'en_US');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd', 'en_US');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm', 'en_US');

  /// Formats currency with commas and 2 decimals, e.g. 150,000.00
  static String formatCurrency(num? value) {
    if (value == null) return '0.00';
    return _currencyFormat.format(value);
  }

  /// Formats quantity with up to 2 decimals
  static String formatQuantity(num? value) {
    if (value == null) return '0';
    return _qtyFormat.format(value);
  }

  /// Formats date as YYYY-MM-DD
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  /// Formats date and time
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  /// Parses string into double safely
  static double parseDouble(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final cleaned = text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
