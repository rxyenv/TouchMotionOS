import 'dart:convert';
import 'dart:io';

/// Thin client for the root-owned pairing daemon on the local console.
class RemoteStatus {
  const RemoteStatus({
    required this.paired,
    required this.connected,
  });

  factory RemoteStatus.fromJson(Map<String, dynamic> json) => RemoteStatus(
    paired: json['paired'] == true,
    connected: json['connected'] == true,
  );

  final bool paired;
  final bool connected;
}

class RemoteDevice {
  const RemoteDevice({required this.mac, required this.name});

  factory RemoteDevice.fromJson(Map<String, dynamic> json) => RemoteDevice(
    mac: json['mac'] as String,
    name: json['name'] as String? ?? 'Unknown device',
  );

  final String mac;
  final String name;
}

class RemoteService {
  static const _base = 'http://127.0.0.1:8754';

  static Future<RemoteStatus?> status() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$_base/api/status'));
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      if (response.statusCode != 200) return null;
      final body = await utf8.decoder.bind(response).join();
      client.close();
      return RemoteStatus.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } on Exception {
      return null;
    }
  }

  static Future<List<RemoteDevice>?> scan() async {
    final response = await _post('/api/local/scan', const {});
    if (response == null || response['devices'] is! List) return null;
    return (response['devices'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(RemoteDevice.fromJson)
        .toList();
  }

  /// Returns null on success, otherwise a safe service error for the UI.
  static Future<String?> pair(String mac) async {
    final response = await _post('/api/local/pair', {'mac': mac});
    if (response?['ok'] == true) return null;
    return response?['error'] as String? ?? 'Could not pair remote.';
  }

  static Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$_base$path'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final responseBody = await utf8.decoder.bind(response).join();
      client.close();
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      return response.statusCode == 200 ? decoded : {...decoded, '_failed': true};
    } on Exception {
      return null;
    }
  }
}
