import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import '../core/vpn/vpn_service.dart';
import '../core/models/server_node.dart';

class VpnProvider extends ChangeNotifier {
  final _vpn = VpnService.instance;

  VpnState _state = VpnState.disconnected;
  String _duration = '00:00:00';
  String _uploadSpeed = '0 B/s';
  String _downloadSpeed = '0 B/s';
  String _uploadTotal = '0 B';
  String _downloadTotal = '0 B';
  ServerNode? _activeNode;

  Timer? _ticker;
  DateTime? _since;
  bool _gotRealStatus = false;

  VpnState get state => _state;
  String get duration => _duration;
  String get uploadSpeed => _uploadSpeed;
  String get downloadSpeed => _downloadSpeed;
  String get uploadTotal => _uploadTotal;
  String get downloadTotal => _downloadTotal;
  ServerNode? get activeNode => _activeNode;
  bool get isConnected => _state == VpnState.connected;

  Future<void> init() async {
    _vpn.onStatus = (state, V2RayStatus status) {
      _gotRealStatus = true;
      if (state == VpnState.connected || state == VpnState.connecting) {
        _state = state;
      } else if (state == VpnState.disconnected &&
          _state == VpnState.connected) {
        _state = VpnState.disconnected;
        _stopTicker();
        _activeNode = null;
        _resetStats();
      }
      if (status.duration.isNotEmpty) _duration = status.duration;
      _uploadSpeed = '${_fmt(status.uploadSpeed)}/s';
      _downloadSpeed = '${_fmt(status.downloadSpeed)}/s';
      _uploadTotal = _fmt(status.upload);
      _downloadTotal = _fmt(status.download);
      notifyListeners();
    };
    await _vpn.init();
  }

  Future<void> toggle(ServerNode node, {bool proxyOnly = false}) async {
    if (_state == VpnState.connected || _state == VpnState.connecting) {
      _state = VpnState.disconnecting;
      notifyListeners();
      await _vpn.disconnect();
      _stopTicker();
      _state = VpnState.disconnected;
      _activeNode = null;
      _resetStats();
      notifyListeners();
    } else {
      _activeNode = node;
      _state = VpnState.connecting;
      _gotRealStatus = false;
      notifyListeners();
      try {
        await _vpn.connect(node, proxyOnly: proxyOnly);
        _state = VpnState.connected;
        _startTicker();
        notifyListeners();
      } catch (e) {
        _stopTicker();
        _state = VpnState.disconnected;
        _activeNode = null;
        _resetStats();
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<int> ping(ServerNode node) => _vpn.ping(node);

  String get rawState => _vpn.lastRawState;
  List<String> get trace => _vpn.debugTrace;
  Future<List<String>> logs() => _vpn.fetchLogs();
  String get config => _vpn.lastConfig;

  void _startTicker() {
    _since = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_since == null) return;
      if (!_gotRealStatus) {
        _duration = _fmtDur(DateTime.now().difference(_since!));
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _since = null;
  }

  void _resetStats() {
    _duration = '00:00:00';
    _uploadSpeed = '0 B/s';
    _downloadSpeed = '0 B/s';
    _uploadTotal = '0 B';
    _downloadTotal = '0 B';
  }

  String _fmtDur(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
