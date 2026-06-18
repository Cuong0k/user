import 'package:flutter/foundation.dart';
import '../core/api/v2board_service.dart';
import '../core/storage/auth_storage.dart';
import '../core/models/user_info.dart';

class AuthProvider extends ChangeNotifier {
  final _svc = V2BoardService.instance;

  bool _loggedIn = false;
  UserInfo? _user;
  String? _uuid;
  bool _loading = false;
  String? _error;

  bool get loggedIn => _loggedIn;
  UserInfo? get user => _user;
  String? get uuid => _uuid;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> bootstrap() async {
    _loggedIn = await AuthStorage.instance.isLoggedIn;
    if (_loggedIn) await refreshUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final token = await _svc.login(email, password);
      await AuthStorage.instance.saveToken(token);
      _loggedIn = true;
      await refreshUser();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String pw, String code, String? invite) async {
    _setLoading(true);
    try {
      final token = await _svc.register(email, pw, code, inviteCode: invite);
      await AuthStorage.instance.saveToken(token);
      _loggedIn = true;
      await refreshUser();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    try {
      _user = await _svc.getUserInfo();
      // getSubscribe trả uuid + subscribe_url; uuid dùng làm password node
      final sub = await _svc.getSubscribeInfo();
      _uuid = (sub['uuid'] ?? _user?.uuid)?.toString();
      final url = (sub['subscribe_url'] ?? '').toString();
      if (url.isNotEmpty) await AuthStorage.instance.saveSubscribe(url);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthStorage.instance.clear();
    _loggedIn = false;
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    _error = null;
    notifyListeners();
  }
}
