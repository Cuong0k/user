import 'dart:convert';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_node.dart';

enum VpnState { disconnected, connecting, connected, disconnecting }

/// Bọc flutter_v2ray (xray-core). Build share-link từ node v2board (format phẳng:
/// server_port / cipher). Với shadowsocks, password = uuid của user.
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

  Future<void> connect(ServerNode node, String uuid,
      {bool proxyOnly = false}) async {
    await init();
    final link = buildShareLink(node, uuid);
    final config = FlutterV2ray.parseFromURL(link);
    if (!await requestPermission()) throw Exception('VPN permission denied');
    await _v2ray.startV2Ray(
      remark: node.cleanName,
      config: config.getFullConfiguration(),
      proxyOnly: proxyOnly,
    );
  }

  Future<void> disconnect() async => _v2ray.stopV2Ray();

  Future<int> ping(ServerNode node, String uuid) async {
    final link = buildShareLink(node, uuid);
    final config = FlutterV2ray.parseFromURL(link);
    return _v2ray.getServerDelay(config: config.getFullConfiguration());
  }

  /// uuid = user.uuid (lấy từ /user/info hoặc /user/getSubscribe).
  String buildShareLink(ServerNode n, String uuid) {
    final r = n.raw;
    final port = n.connectPort;
    final name = Uri.encodeComponent(n.cleanName);

    switch (n.type) {
      case 'shadowsocks':
        final method = (n.cipher ?? 'chacha20-ietf-poly1305');
        // v2board: password shadowsocks = uuid của user
        final userinfo = base64.encode(utf8.encode('$method:$uuid'));
        return 'ss://$userinfo@${n.host}:$port#$name';

      case 'vless':
        final flow = (r['flow'] ?? '').toString();
        final net = (r['network'] ?? 'tcp').toString();
        final security = _sec(r);
        final q = <String, String>{
          'type': net,
          'security': security,
          if (flow.isNotEmpty) 'flow': flow,
          ..._stream(r, net, security),
        };
        return 'vless://$uuid@${n.host}:$port?${_qs(q)}#$name';

      case 'vmess':
        final net = (r['network'] ?? 'tcp').toString();
        final vmess = {
          'v': '2', 'ps': n.cleanName, 'add': n.host, 'port': port,
          'id': uuid, 'aid': (r['alter_id'] ?? 0).toString(),
          'net': net, 'type': 'none',
          'host': (r['host'] ?? '').toString(),
          'path': (r['path'] ?? '').toString(),
          'tls': _sec(r) == 'tls' ? 'tls' : '',
        };
        return 'vmess://${base64.encode(utf8.encode(jsonEncode(vmess)))}';

      case 'trojan':
        final q = <String, String>{
          'sni': (r['server_name'] ?? r['sni'] ?? n.host).toString(),
          'allowInsecure': '1',
        };
        return 'trojan://$uuid@${n.host}:$port?${_qs(q)}#$name';

      default:
        throw Exception('Unsupported node type: ${n.type}');
    }
  }

  String _sec(Map r) {
    final security = r['security']?.toString();
    if (security == 'reality') return 'reality';
    if (r['tls'] == 1 || r['tls'] == true || security == 'tls') return 'tls';
    return 'none';
  }

  Map<String, String> _stream(Map r, String net, String security) {
    final out = <String, String>{};
    if (net == 'ws') {
      out['path'] = (r['path'] ?? '/').toString();
      if (r['host'] != null) out['host'] = r['host'].toString();
    } else if (net == 'grpc') {
      out['serviceName'] = (r['service_name'] ?? '').toString();
    }
    if (security == 'tls' || security == 'reality') {
      out['sni'] = (r['server_name'] ?? r['sni'] ?? '').toString();
      if (r['public_key'] != null) out['pbk'] = r['public_key'].toString();
      if (r['short_id'] != null) out['sid'] = r['short_id'].toString();
      if (r['fingerprint'] != null) out['fp'] = r['fingerprint'].toString();
    }
    return out;
  }

  String _qs(Map<String, String> q) => q.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
