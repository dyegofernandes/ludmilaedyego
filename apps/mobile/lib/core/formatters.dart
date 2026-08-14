import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
final _dateTime = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');

String formatMoney(num value) => _currency.format(value);

String formatDate(DateTime? d) => d == null ? '—' : _date.format(d);

String formatDateTime(DateTime? d) => d == null ? '—' : _dateTime.format(d);
