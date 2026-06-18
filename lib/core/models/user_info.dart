/// Thông tin user từ /api/v1/user/info của v2board.
class UserInfo {
  final String email;
  final num balance;          // số dư (xu) - v2board lưu *100
  final num commissionBalance;
  final int? planId;
  final int? expiredAt;       // unix, null = vô thời hạn
  final int u;                // upload bytes
  final int d;                // download bytes
  final int? transferEnable;  // tổng dung lượng bytes
  final int? deviceLimit;
  final String? uuid;
  final bool banned;

  UserInfo({
    required this.email,
    required this.balance,
    required this.commissionBalance,
    this.planId,
    this.expiredAt,
    required this.u,
    required this.d,
    this.transferEnable,
    this.deviceLimit,
    this.uuid,
    required this.banned,
  });

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
        email: j['email']?.toString() ?? '',
        balance: j['balance'] ?? 0,
        commissionBalance: j['commission_balance'] ?? 0,
        planId: j['plan_id'],
        expiredAt: j['expired_at'],
        u: j['u'] ?? 0,
        d: j['d'] ?? 0,
        transferEnable: j['transfer_enable'],
        deviceLimit: j['device_limit'],
        uuid: j['uuid']?.toString(),
        banned: (j['banned'] ?? 0) == 1,
      );

  int get usedBytes => u + d;
  double get usedGB => usedBytes / (1024 * 1024 * 1024);
  double get totalGB =>
      transferEnable == null ? 0 : transferEnable! / (1024 * 1024 * 1024);
  bool get unlimited => transferEnable == null || transferEnable == 0;

  bool get hasActiveSubscription {
    if (planId == null) return false;
    if (expiredAt == null) return true; // vô thời hạn
    return expiredAt! * 1000 > DateTime.now().millisecondsSinceEpoch;
  }

  DateTime? get expireDate =>
      expiredAt == null ? null : DateTime.fromMillisecondsSinceEpoch(expiredAt! * 1000);
}
