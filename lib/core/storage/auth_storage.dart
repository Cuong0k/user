import 'package:shared_preferences/shared_preferences.dart';

/// Lưu token đăng nhập + link subscribe.
class AuthStorage {
  AuthStorage._();
  static final AuthStorage instance = AuthStorage._();

  static const _kToken = 'auth_token';
  static const _kSubscribe = 'subscribe_url';

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);

  Future<void> saveToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(_kToken, token);

  Future<String?> getSubscribe() async =>
      (await SharedPreferences.getInstance()).getString(_kSubscribe);

  Future<void> saveSubscribe(String url) async =>
      (await SharedPreferences.getInstance()).setString(_kSubscribe, url);

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kSubscribe);
  }

  Future<bool> get isLoggedIn async => (await getToken())?.isNotEmpty ?? false;
}
