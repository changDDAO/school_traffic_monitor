import 'package:intl/intl.dart';

final _timeFormat = DateFormat('HH:mm:ss.SSS');
final _countFormat = NumberFormat.decimalPattern();

String formatTime(DateTime time) => _timeFormat.format(time);

String formatCount(num value) => _countFormat.format(value);

/// 12.0 → "12", 3.5 → "3.5"
String formatRate(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
