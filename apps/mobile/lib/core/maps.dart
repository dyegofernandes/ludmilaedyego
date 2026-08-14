import 'package:url_launcher/url_launcher.dart';

/// Abre o Google Maps pela busca do endereço — sem API key / token.
Future<bool> abrirGoogleMaps(String query) async {
  final q = query.trim();
  if (q.isEmpty) return false;
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
