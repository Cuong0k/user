import 'dart:convert';

/// Node VPN. Có 2 nguồn:
///  - fromLink: parse từ share link trong subscribe (ƯU TIÊN, luôn đúng)
///  - fromJson: từ /user/server/fetch (chỉ để hiển thị/dự phòng)
class ServerNode {
  final int id;
  final String name;
  final String type;
  final String host;
  final String port;
  final num rate;
  final bool isOnline;
  final String? shareLink; // link gốc ss:// vmess:// ... dùng để connect
  final Map<String, dynamic> raw;

  ServerNode({
    required this.id,
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    required this.rate,
    required this.isOnline,
    this.shareLink,
    this.raw = const {},
  });

  /// Parse từ share link (nguồn chính).
  factory ServerNode.fromLink(int id, String link) {
    final scheme = link.split('://').first;
    String name = '';
    String host = '';
    String port = '';

    final hashIdx = link.indexOf('#');
    if (hashIdx >= 0) {
      name = Uri.decodeComponent(link.substring(hashIdx + 1));
    }

    try {
      if (scheme == 'vmess') {
        final b64 = link.substring('vmess://'.length).split('#').first;
        final json = jsonDecode(utf8.decode(base64.decode(base64.normalize(b64))));
        name = (json['ps'] ?? name).toString();
        host = (json['add'] ?? '').toString();
        port = (json['port'] ?? '').toString();
      } else {
        // ss / vless / trojan: userinfo@host:port?...#name
        final afterScheme = link.substring(scheme.length + 3);
        final atIdx = afterScheme.lastIndexOf('@');
        if (atIdx >= 0) {
          final hostPart = afterScheme.substring(atIdx + 1);
          final hp = hostPart.split(RegExp(r'[?#]')).first;
          final c = hp.lastIndexOf(':');
          if (c >= 0) {
            host = hp.substring(0, c);
            port = hp.substring(c + 1);
          } else {
            host = hp;
          }
        }
      }
    } catch (_) {}

    if (name.isEmpty) name = '$scheme node';

    return ServerNode(
      id: id,
      name: name,
      type: scheme,
      host: host,
      port: port,
      rate: 1,
      isOnline: true,
      shareLink: link,
    );
  }

  factory ServerNode.fromJson(Map<String, dynamic> j) => ServerNode(
        id: j['id'] ?? 0,
        name: j['name']?.toString() ?? 'Node',
        type: (j['type'] ?? 'shadowsocks').toString(),
        host: j['host']?.toString() ?? '',
        port: (j['server_port'] ?? j['port'] ?? 443).toString(),
        rate: j['rate'] ?? 1,
        isOnline: (j['is_online'] ?? 1) == 1,
        raw: j,
      );

  String get countryCode {
    final flag = _flagFromEmoji(name);
    if (flag != null) return flag;
    final n = name.toLowerCase();
    const map = {
      'hong kong': 'HK', 'hk': 'HK',
      'singapore': 'SG', 'sgp': 'SG', 'sg': 'SG',
      'japan': 'JP', 'jp': 'JP',
      'united states': 'US', 'new york': 'US', 'us': 'US',
      'taiwan': 'TW', 'tw': 'TW',
      'korea': 'KR', 'kr': 'KR',
      'india': 'IN', 'bangalore': 'IN',
      'vietnam': 'VN', 'vnpt': 'VN', 'viettel': 'VN', 'vn': 'VN',
    };
    for (final e in map.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return 'UN';
  }

  String? _flagFromEmoji(String s) {
    final runes = s.runes.toList();
    for (int i = 0; i < runes.length - 1; i++) {
      final a = runes[i], b = runes[i + 1];
      if (a >= 0x1F1E6 && a <= 0x1F1FF && b >= 0x1F1E6 && b <= 0x1F1FF) {
        return String.fromCharCode(a - 0x1F1E6 + 65) +
            String.fromCharCode(b - 0x1F1E6 + 65);
      }
    }
    return null;
  }

  String get cleanName =>
      name.replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true), '').trim();
}
