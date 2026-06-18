/// Dữ liệu mời bạn từ /api/v1/user/invite/fetch.
class InviteInfo {
  final List<String> codes;       // mã mời
  final int registerCount;
  final num totalCommission;      // xu
  final num commissionRate;       // %

  InviteInfo({
    required this.codes,
    required this.registerCount,
    required this.totalCommission,
    required this.commissionRate,
  });

  factory InviteInfo.fromJson(Map<String, dynamic> j) {
    final codes = <String>[];
    if (j['codes'] is List) {
      for (final c in j['codes']) {
        if (c is Map && c['code'] != null) codes.add(c['code'].toString());
      }
    }
    final stat = j['stat'];
    return InviteInfo(
      codes: codes,
      registerCount: (stat is List && stat.isNotEmpty) ? (stat[0] ?? 0) : 0,
      totalCommission: (stat is List && stat.length > 3) ? (stat[3] ?? 0) : 0,
      commissionRate: (stat is List && stat.length > 1) ? (stat[1] ?? 0) : 0,
    );
  }

  String? get firstCode => codes.isNotEmpty ? codes.first : null;
}
