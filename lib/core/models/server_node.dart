/// Một node/server từ /api/v1/user/server/fetch.
/// Panel này trả field PHẲNG: server_port (port connect thật), cipher, host...
class ServerNode {
  final int id;
  final String name;
  final String type;
  final String host;
  final dynamic port;        // port hiển thị
  final dynamic serverPort;  // port connect thật (quan trọng)
  final String? cipher;      // cho shadowsocks
  final num rate;
  final bool isOnline;
  final Map<String, dynamic> raw;

  ServerNode({
    required this.id,
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    required this.serverPort,
    this.cipher,
    required this.rate,
    required this.isOnline,
    required this.raw,
  });

  factory ServerNode.fromJson(Map<String, dynamic> j) => ServerNode(
        id: j['id'] ?? 0,
        name: j['name']?.toString() ?? 'Node',
        type: (j['type'] ?? 'shadowsocks').toString(),
        host: j['host']?.toString() ?? '',
        port: j['port'] ?? 443,
        serverPort: j['server_port'] ?? j['port'] ?? 443,
        cipher: j['cipher']?.toString(),
        rate: j['rate'] ?? 1,
        isOnline: (j['is_online'] ?? 1) == 1,
        raw: j,
      );

  /// Port dùng để kết nối (ưu tiên server_port).
  String get connectPort => serverPort.toString().split('-').first;

  /// Lấy mã quốc gia từ emoji cờ đầu tên (🇻🇳 -> VN), hoặc từ chữ.
  String get countryCode {
    final flag = _flagFromEmoji(name);
    if (flag != null) return flag;
    final n = name.toLowerCase();
    const map = {
      'hong kong': 'HK', 'hk': 'HK',
      'singapore': 'SG', 'sg': 'SG',
      'japan': 'JP', 'jp': 'JP',
      'us': 'US', 'united states': 'US', 'new york': 'US',
      'taiwan': 'TW', 'tw': 'TW',
      'korea': 'KR', 'kr': 'KR',
      'vietnam': 'VN', 'vn': 'VN', 'vnpt': 'VN', 'viettel': 'VN',
    };
    for (final e in map.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return 'UN';
  }

  /// Giải mã cặp Regional Indicator (🇻🇳) thành "VN".
  String? _flagFromEmoji(String s) {
    final runes = s.runes.toList();
    for (int i = 0; i < runes.length - 1; i++) {
      final a = runes[i], b = runes[i + 1];
      if (a >= 0x1F1E6 && a <= 0x1F1FF && b >= 0x1F1E6 && b <= 0x1F1FF) {
        final c1 = String.fromCharCode(a - 0x1F1E6 + 65);
        final c2 = String.fromCharCode(b - 0x1F1E6 + 65);
        return '$c1$c2';
      }
    }
    return null;
  }

  /// Tên sạch (bỏ emoji cờ ở đầu) để hiển thị.
  String get cleanName => name.replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true), '').trim();
}
