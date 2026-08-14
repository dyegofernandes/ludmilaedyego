/// API local (Docker Postgres + Nest). Override:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3004
/// flutter run --dart-define=WEB_BASE_URL=http://ludmilaedyego
class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001',
  );

  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://207.180.243.108:8086',
  );

  static const fallbackNomeNoivo = 'Dyego';
  static const fallbackNomeNoiva = 'Ludmila';
  static const brandLogoAsset = 'assets/branding/logo_ludmila_dyego.png';

  static String conviteUrl(String codigo) {
    final base = webBaseUrl.replaceAll(RegExp(r'/$'), '');
    final code = codigo.trim();
    return '$base/convite/$code';
  }

  static String mediaUrl(String url) {
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('data:')) {
      return url;
    }
    final base = apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }
}
