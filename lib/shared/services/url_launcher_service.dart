import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static Future<bool> launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
