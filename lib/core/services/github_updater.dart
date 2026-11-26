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
  static const Duration _requestTimeout = Duration(seconds: 10);

  static Future<UpdateInfo> checkForUpdates() async {
    final repo = dotenv.isInitialized
        ? (dotenv.env['GITHUB_REPO'] ??
            const String.fromEnvironment('GITHUB_REPO',
                defaultValue: 'archon/Abadgar'))
        : const String.fromEnvironment('GITHUB_REPO',
            defaultValue: 'archon/Abadgar');
    final response = await http
        .get(Uri.parse('https://api.github.com/repos/$repo/releases/latest'))
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to check for updates (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid update response');
    }

    final String latestTag = data['tag_name']?.toString() ?? 'v0.0.0';
    final assets = data['assets'] as List<dynamic>?;
    String rawUrl = data['html_url']?.toString() ?? '';
    if (assets != null && assets.isNotEmpty) {
      final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
            (a) => (a?['name']?.toString().toLowerCase().endsWith('.apk') ??
                false),
            orElse: () => null,
          );
      final chosen = apkAsset ??
          (assets.first is Map<String, dynamic>
              ? assets.first as Map<String, dynamic>
              : null);
      final assetUrl = chosen?['browser_download_url']?.toString();
      if (assetUrl != null && assetUrl.isNotEmpty) {
        rawUrl = assetUrl;
      }
    }
    final String downloadUrl = isTrustedDownloadUrl(rawUrl) ? rawUrl : '';
    final String body = data['body']?.toString() ?? '';

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = 'v${packageInfo.version}';

    return UpdateInfo(
      latestVersion: latestTag,
      downloadUrl: downloadUrl,
      releaseNotes: body,
      isUpdateAvailable:
          isNewerVersion(latestTag, currentVersion) && downloadUrl.isNotEmpty,
    );
  }

  static bool isTrustedDownloadUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return host == 'github.com' ||
        host.endsWith('.github.com') ||
        host == 'githubusercontent.com' ||
        host.endsWith('.githubusercontent.com');
  }

  static bool isNewerVersion(String latest, String current) {
    final latestParts = _parseVersionParts(latest);
    final currentParts = _parseVersionParts(current);
    if (latestParts == null || currentParts == null) return false;

    final maxLen = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static List<int>? _parseVersionParts(String version) {
    final match = RegExp(r'^v?(\d+(?:\.\d+)*)').firstMatch(version.trim());
    if (match == null) return null;
    return match.group(1)!.split('.').map(int.parse).toList();
  }
}
