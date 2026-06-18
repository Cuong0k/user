import 'api_client.dart';
import 'api_endpoints.dart';
import '../models/user_info.dart';
import '../models/plan.dart';
import '../models/server_node.dart';
import '../models/invite_info.dart';

/// Tầng nghiệp vụ: gọi v2board và map sang model.
class V2BoardService {
  V2BoardService._();
  static final V2BoardService instance = V2BoardService._();
  final _api = ApiClient.instance;

  // ---------- Auth ----------
  /// Đăng nhập email. v2board trả { token, auth_data, is_admin }.
  Future<String> login(String email, String password) async {
    final data = await _api.post(Api.login, data: {
      'email': email,
      'password': password,
    });
    // auth_data là token dùng cho header Authorization
    return (data['auth_data'] ?? data['token']).toString();
  }

  Future<String> register(String email, String password, String emailCode,
      {String? inviteCode}) async {
    final data = await _api.post(Api.register, data: {
      'email': email,
      'password': password,
      'email_code': emailCode,
      if (inviteCode != null && inviteCode.isNotEmpty) 'invite_code': inviteCode,
    });
    return (data['auth_data'] ?? data['token']).toString();
  }

  Future<void> sendEmailCode(String email) async {
    await _api.post(Api.sendEmailVerify, data: {'email': email});
  }

  // ---------- User ----------
  Future<UserInfo> getUserInfo() async {
    final data = await _api.get(Api.userInfo);
    return UserInfo.fromJson(Map<String, dynamic>.from(data));
  }

  /// Lấy link subscribe (chứa token sub để tải config node).
  Future<String> getSubscribeUrl() async {
    final data = await _api.get(Api.getSubscribe);
    return data['subscribe_url'].toString();
  }

  // ---------- Servers / Nodes ----------
  Future<List<ServerNode>> fetchServers() async {
    final data = await _api.get(Api.serverFetch);
    final list = (data as List);
    return list
        .map((e) => ServerNode.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ---------- Plans ----------
  Future<List<Plan>> fetchPlans() async {
    final data = await _api.get(Api.planFetch);
    final list = (data as List);
    return list.map((e) => Plan.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ---------- Orders ----------
  /// Tạo đơn, trả về trade_no.
  Future<String> createOrder(int planId, String period, {String? coupon}) async {
    final data = await _api.post(Api.orderSave, data: {
      'plan_id': planId,
      'period': period,
      if (coupon != null && coupon.isNotEmpty) 'coupon_code': coupon,
    });
    return data.toString();
  }

  Future<List<dynamic>> getPaymentMethods() async {
    final data = await _api.get(Api.paymentMethod);
    return (data as List);
  }

  /// Checkout đơn -> trả về URL thanh toán hoặc trạng thái.
  Future<dynamic> checkout(String tradeNo, int methodId) async {
    return _api.post(Api.orderCheckout, data: {
      'trade_no': tradeNo,
      'method': methodId,
    });
  }

  // ---------- Invite ----------
  Future<InviteInfo> fetchInvite() async {
    final data = await _api.get(Api.inviteFetch);
    return InviteInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> generateInviteCode() async {
    await _api.get(Api.inviteSave);
  }

  // ---------- Notice ----------
  Future<List<dynamic>> fetchNotices() async {
    final data = await _api.get(Api.notice);
    if (data is Map && data['data'] is List) return data['data'];
    if (data is List) return data;
    return [];
  }
}
