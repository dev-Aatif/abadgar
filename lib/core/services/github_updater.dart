import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isUpdateAvailable;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isUpdateAvailable,
  });
}

class GithubUpdater {
  static Future<UpdateInfo> checkForUpdates() async {
    final repo = dotenv.env['GITHUB_REPO'] ?? 'archon/Abadgar';
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to check for updates');
    }

    final data = jsonDecode(response.body);
    final String latestTag = data['tag_name']; // e.g. "v1.2.0"
    final String downloadUrl = data['assets'][0]['browser_download_url'];
    final String body = data['body'];

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = 'v${packageInfo.version}';

    return UpdateInfo(
      latestVersion: latestTag,
      downloadUrl: downloadUrl,
      releaseNotes: body,
      isUpdateAvailable: _isNewer(latestTag, currentVersion),
    );
  }

  static bool _isNewer(String latest, String current) {
    // Simple version comparison (e.g. v1.2.0 > v1.1.0)
    // In a production app, use a proper semver package if versions are complex.
    final cleanLatest = latest.replaceAll('v', '');
    final cleanCurrent = current.replaceAll('v', '');
    
    List<int> latestParts = cleanLatest.split('.').map(int.parse).toList();
    List<int> currentParts = cleanCurrent.split('.').map(int.parse).toList();

    for (var i = 0; i < latestParts.length; i++) {
       if (i >= currentParts.length) return true;
       if (latestParts[i] > currentParts[i]) return true;
       if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
