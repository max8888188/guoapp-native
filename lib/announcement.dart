import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

const announcementSourceUrl =
    'https://raw.githubusercontent.com/max8888188/guoapp-native/main/announcement.json';

const announcementVersionKey = 'app.version';

const _dismissedPrefix = 'announcement.dismissed.';

const _requestTimeout = Duration(seconds: 6);

const _connectTimeout = Duration(seconds: 4);

String _plainText(Object? value) {
  if (value is String) return value.trim();
  if (value is num) return '$value';
  return '';
}

bool _flag(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.trim().toLowerCase() == 'true';
  return false;
}

DateTime? _moment(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toUtc();
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.minVersion,
    required this.maxVersion,
    required this.mandatory,
    required this.actionText,
    required this.actionUrl,
    required this.startAt,
    required this.endAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: _plainText(json['id']),
    title: _plainText(json['title']),
    body: _plainText(json['body']),
    minVersion: _plainText(json['minVersion']),
    maxVersion: _plainText(json['maxVersion']),
    mandatory: _flag(json['mandatory']),
    actionText: _plainText(json['actionText']),
    actionUrl: _plainText(json['actionUrl']),
    startAt: _moment(json['startAt']),
    endAt: _moment(json['endAt']),
  );

  final String id;
  final String title;
  final String body;
  final String minVersion;
  final String maxVersion;
  final bool mandatory;
  final String actionText;
  final String actionUrl;
  final DateTime? startAt;
  final DateTime? endAt;

  bool get ready => id.isNotEmpty && title.isNotEmpty;

  bool activeAt(DateTime now) {
    final start = startAt;
    final end = endAt;
    if (start != null && now.isBefore(start)) return false;
    if (end != null && now.isAfter(end)) return false;
    return true;
  }
}

class AnnouncementService {
  AnnouncementService(this.preferences);

  final SharedPreferences preferences;

  String dismissedKey(String id) => '$_dismissedPrefix$id';

  Future<Announcement?> check({String? currentVersion}) async {
    try {
      final announcement = await _read();
      if (announcement == null || !announcement.ready) return null;
      if (!announcement.activeAt(DateTime.now().toUtc())) return null;
      final version =
          currentVersion ?? preferences.getString(announcementVersionKey) ?? '';
      if (!_supports(announcement, version)) return null;
      if (!announcement.mandatory && dismissed(announcement.id)) return null;
      return announcement;
    } catch (_) {
      return null;
    }
  }

  bool dismissed(String id) =>
      id.isNotEmpty && (preferences.getBool(dismissedKey(id)) ?? false);

  Future<void> dismiss(Announcement announcement) async {
    if (announcement.mandatory || !announcement.ready) return;
    try {
      await preferences.setBool(dismissedKey(announcement.id), true);
    } catch (_) {
      return;
    }
  }

  static int _compareVersion(String left, String right) {
    final a = left.split('.');
    final b = right.split('.');
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final x = index < a.length ? int.tryParse(a[index].trim()) ?? 0 : 0;
      final y = index < b.length ? int.tryParse(b[index].trim()) ?? 0 : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }

  bool _supports(Announcement announcement, String version) {
    if (version.isEmpty) return true;
    final min = announcement.minVersion;
    if (min.isNotEmpty && _compareVersion(version, min) < 0) return false;
    final max = announcement.maxVersion;
    if (max.isNotEmpty && _compareVersion(version, max) > 0) return false;
    return true;
  }

  Future<Announcement?> _read() async {
    final source = await _download();
    if (source == null || source.isEmpty) return null;
    final decoded = jsonDecode(source);
    if (decoded is! Map) return null;
    return Announcement.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<String?> _download() async {
    final client = HttpClient()..connectionTimeout = _connectTimeout;
    try {
      final request = await client
          .getUrl(Uri.parse(announcementSourceUrl))
          .timeout(_requestTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache, no-store');
      request.headers.set(HttpHeaders.pragmaHeader, 'no-cache');
      final response = await request.close().timeout(_requestTimeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      return await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
