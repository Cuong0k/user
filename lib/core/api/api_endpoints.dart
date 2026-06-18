/// Toàn bộ endpoint v2board/Xboard mà SlagClient gốc gọi (trích từ libapp.so).
/// Khớp với NewV2board nên dùng thẳng được với panel của bạn.
class Api {
  Api._();

  /// Đổi thành domain panel của bạn, ví dụ: https://vpnstore.pro.vn
  static const String baseUrl = 'https://client-user.jiangsuhk.com';

  static const String prefix = '/api/v1';

  // --- Guest / config ---
  static const String guestConfig = '$prefix/guest/comm/config';
  static const String appVersion = '$prefix/client/app/getVersion';

  // --- Passport (auth) ---
  static const String login = '$prefix/passport/auth/login';
  static const String register = '$prefix/passport/auth/register';
  static const String forget = '$prefix/passport/auth/forget';
  static const String phoneLogin = '$prefix/passport/auth/phoneLogin';
  static const String phoneRegister = '$prefix/passport/auth/phoneRegister';
  static const String phoneForget = '$prefix/passport/auth/phoneForget';
  static const String sendEmailVerify = '$prefix/passport/comm/sendEmailVerify';
  static const String sendPhoneVerify = '$prefix/passport/comm/sendPhoneVerify';

  // --- User ---
  static const String userInfo = '$prefix/user/info';
  static const String userConfig = '$prefix/user/comm/config';
  static const String getSubscribe = '$prefix/user/getSubscribe';
  static const String changePassword = '$prefix/user/changePassword';
  static const String serverFetch = '$prefix/user/server/fetch';
  static const String planFetch = '$prefix/user/plan/fetch';
  static const String notice = '$prefix/user/notice/fetch';

  // --- Order / payment ---
  static const String orderFetch = '$prefix/user/order/fetch';
  static const String orderDetail = '$prefix/user/order/detail';
  static const String orderSave = '$prefix/user/order/save';
  static const String orderCheckout = '$prefix/user/order/checkout';
  static const String orderCancel = '$prefix/user/order/cancel';
  static const String paymentMethod = '$prefix/user/order/getPaymentMethod';
  static const String couponCheck = '$prefix/user/coupon/check';

  // --- Invite / gift ---
  static const String inviteFetch = '$prefix/user/invite/fetch';
  static const String inviteSave = '$prefix/user/invite/save';
  static const String giftRedeem = '$prefix/user/gift-card/redeem';

  // --- Ticket ---
  static const String ticketFetch = '$prefix/user/ticket/fetch';
  static const String ticketSave = '$prefix/user/ticket/save';
  static const String ticketReply = '$prefix/user/ticket/reply';
}
