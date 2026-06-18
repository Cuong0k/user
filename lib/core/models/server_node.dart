/// Một node/server từ /api/v1/user/server/fetch.
/// v2board trả các field: name, type (vless/vmess/trojan/shadowsocks/hysteria),
/// host, port, server_key, tags, rate, và phần protocol_settings tuỳ loại.
class ServerNode {
  final int id;
  final String name;
  final String type;
  final String host;
  final dynamic port;     // có thể "443" hoặc "20000-30000"
  final List<String> tags;
  final String rate;      // hệ số nhân lưu lượng, "1.0"
  final bool isOnline;
  final int? lastCheckAt;
  final Map<String, dynamic> raw; // giữ nguyên để build cấu hình core

  ServerNode({
    required this.id,
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    required this.tags,
    required this.rate,
    required this.isOnline,
    this.lastCheckAt,
    required this.raw,
  });

  factory ServerNode.fromJson(Map<String, dynamic> j) => ServerNode(
        id: j['id'] ?? 0,
        name: j['name']?.toString() ?? 'Node',
        type: (j['type'] ?? 'vless').toString(),
        host: j['host']?.toString() ?? '',
        port: j['port'] ?? 443,
        tags: (j['tags'] is List)
            ? List<String>.from((j['tags']).map((e) => e.toString()))
            : <String>[],
        rate: (j['rate'] ?? '1.0').toString(),
        isOnline: (j['is_online'] ?? 1) == 1,
        lastCheckAt: j['last_check_at'],
        raw: j,
      );

  /// Đoán mã quốc gia 2 ký tự từ tên node để hiển thị cờ.
  String get countryCode {
    final n = name.toLowerCase();
    const map = {
      'hong kong': 'hk', 'hongkong': 'hk', 'hk': 'hk', '香港': 'hk',
      'singapore': 'sg', 'sg': 'sg', '新加坡': 'sg',
      'japan': 'jp', 'tokyo': 'jp', 'jp': 'jp', '日本': 'jp',
      'usa': 'us', 'united states': 'us', 'us': 'us', '美国': 'us',
      'taiwan': 'tw', 'tw': 'tw', '台湾': 'tw',
      'korea': 'kr', 'kr': 'kr', '韩国': 'kr',
      'vietnam': 'vn', 'vn': 'vn', 'việt nam': 'vn',
      'china': 'cn', 'cn': 'cn',
      'uk': 'gb', 'london': 'gb', 'germany': 'de', 'france': 'fr',
    };
    for (final e in map.entries) {
      if (n.contains(e.key)) return e.value.toUpperCase();
    }
    return 'UN';
  }
}
