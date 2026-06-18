import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../core/vpn/vpn_service.dart';
import '../core/models/server_node.dart';

class VpnProvider extends ChangeNotifier {
  final _vpn = VpnService.instance;

  VpnState _state = VpnState.disconnected;
  String _duration = '00:00:00';
  String _uploadSpeed = '0 KB/s';
  String _downloadSpeed = '0 KB/s';
  ServerNode? _activeNode;

  VpnState get state => _state;
  String get duration => _duration;
  String get uploadSpeed => _uploadSpeed;
  String get downloadSpeed => _downloadSpeed;
  ServerNode? get activeNode => _activeNode;
  bool get isConnected => _state == VpnState.connected;

  Future<void> init() async {
    _vpn.onStatus = (state, V2RayStatus status) {
      _state = state;
      _duration = status.duration;
      _uploadSpeed = _fmt(status.uploadSpeed);
      _downloadSpeed = _fmt(status.downloadSpeed);
      notifyListeners();
    };
    await _vpn.init();
  }

  Future<void> toggle(ServerNode node, {bool proxyOnly = false}) async {
    if (_state == VpnState.connected || _state == VpnState.connecting) {
      await _vpn.disconnect();
      _activeNode = null;
    } else {
      _activeNode = node;
      await _vpn.connect(node, proxyOnly: proxyOnly);
    }
  }

  Future<int> ping(ServerNode node) => _vpn.ping(node);

  String _fmt(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }
}
