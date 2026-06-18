import 'dart:convert';
import 'dart:io';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_node.dart';

enum VpnState { disconnected, connecting, connected, disconnecting }

class VpnService {
  VpnService._();
  static final VpnService instance = VpnService._();

  late final FlutterV2ray _v2ray;
  bool _inited = false;
  void Function(VpnState state, V2RayStatus status)? onStatus;

  Future<void> init() async {
    if (_inited) return;
    _v2ray = FlutterV2ray(
      onStatusChanged: (status) => onStatus?.call(_map(status.state), status),
    );
    await _v2ray.initializeV2Ray();
    _inited = true;
  }

  VpnState _map(String s) {
    switch (s.toUpperCase()) {
      case 'CONNECTED':
        return VpnState.connected;
      case 'CONNECTING':
        return VpnState.connecting;
      case 'DISCONNECTING':
        return VpnState.disconnecting;
      default:
        return VpnState.disconnected;
    }
  }

  Future<bool> requestPermission() => _v2ray.requestPermission();

  String _link(ServerNode node) {
    final link = node.shareLink;
    if (link == null || link.isEmpty) {
      throw Exception('Node has no share link');
    }
    return link;
  }

  /// Build config từ link rồi CHÈN DNS + bật sniffing để tránh "kết nối nhưng
  /// không vào mạng" (thường do thiếu DNS).
  String _fullConfig(ServerNode node) {
    final parsed = FlutterV2ray.parseFromURL(_link(node));
    final cfg = jsonDecode(parsed.getFullConfiguration());
    if (cfg is Map<String, dynamic>) {
      cfg['dns'] = {
        'servers': ['1.1.1.1', '8.8.8.8', 'localhost'],
      };
      // bật sniffing cho các inbound (giúp định tuyến theo domain)
      if (cfg['inbounds'] is List) {
        for (final inb in (cfg['inbounds'] as List)) {
          if (inb is Map) {
            inb['sniffing'] = {
              'enabled': true,
              'destOverride': ['http', 'tls'],
            };
          }
        }
      }
      return jsonEncode(cfg);
    }
    return parsed.getFullConfiguration();
  }

  Future<void> connect(ServerNode node, {bool proxyOnly = false}) async {
    await init();
    if (!await requestPermission()) throw Exception('VPN permission denied');
    await _v2ray.startV2Ray(
      remark: node.cleanName,
      config: _fullConfig(node),
      proxyOnly: proxyOnly,
    );
  }

  Future<void> disconnect() async => _v2ray.stopV2Ray();

  /// PING KIỂU TCP: mở socket tới host:port của node, đo thời gian bắt tay.
  /// Nhanh và ổn định hơn delay test của core. -1 = timeout.
  Future<int> ping(ServerNode node) async {
    final host = node.host;
    final port = int.tryParse(node.port.split('-').first) ?? 443;
    if (host.isEmpty) return -1;
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 5));
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return -1;
    } finally {
      socket?.destroy();
    }
  }
}
