import 'dart:io';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import '../models/server_node.dart';

enum VpnState { disconnected, connecting, connected, disconnecting }

class VpnService {
  VpnService._();
  static final VpnService instance = VpnService._();

  late final V2ray _v2ray;
  bool _inited = false;
  void Function(VpnState state, V2RayStatus status)? onStatus;

  Future<void> init() async {
    if (_inited) return;
    _v2ray = V2ray(
      onStatusChanged: (status) => onStatus?.call(_map(status.state), status),
    );
    await _v2ray.initialize(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
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

  String _rawLink(ServerNode node) {
    final link = node.shareLink;
    if (link == null || link.isEmpty) throw Exception('Node has no share link');
    return link;
  }

  Future<void> connect(ServerNode node, {bool proxyOnly = false}) async {
    await init();
    final parser = V2ray.parseFromURL(_rawLink(node));
    if (!proxyOnly && !await requestPermission()) {
      throw Exception('VPN permission denied');
    }
    final remark = node.cleanName.isNotEmpty ? node.cleanName : parser.remark;
    await _v2ray.startV2Ray(
      remark: remark,
      config: parser.getFullConfiguration(),
      blockedApps: null,
      bypassSubnets: null,
      proxyOnly: proxyOnly,
    );
  }

  Future<void> disconnect() async => _v2ray.stopV2Ray();

  Future<int> ping(ServerNode node) async {
    final host = node.host;
    final port = int.tryParse(node.port.split('-').first) ?? 443;
    if (host.isEmpty) return -1;
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return -1;
    } finally {
      socket?.destroy();
    }
  }
}
