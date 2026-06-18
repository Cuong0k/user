import 'dart:convert';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/server_node.dart';

/// Trạng thái kết nối hiển thị trên UI (khớp i18n home.* của app gốc).
enum VpnState { disconnected, connecting, connected, disconnecting }

/// Bọc flutter_v2ray (xray-core). Nhận một [ServerNode] của v2board, dựng
/// share-link tương ứng (vless:// / vmess:// / trojan:// / ss://) rồi connect.
///
/// Lưu ý: SlagClient gốc dùng core sing-box (libomnxt.so) và nạp cấu hình trực
/// tiếp từ link subscribe. Ở đây ta dùng xray-core mã nguồn mở cho đơn giản;
/// logic build link giữ nguyên tinh thần đó.
class VpnService {
  VpnService._();
  static final VpnService instance = VpnService._();

  late final FlutterV2ray _v2ray;
  bool _inited = false;

  /// Callback báo trạng thái + tốc độ lên (provider lắng nghe).
  void Function(VpnState state, V2RayStatus status)? onStatus;

  Future<void> init() async {
    if (_inited) return;
    _v2ray = FlutterV2ray(
      onStatusChanged: (status) {
        onStatus?.call(_map(status.state), status);
      },
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

  /// Connect tới một node v2board.
  Future<void> connect(ServerNode node, {bool proxyOnly = false}) async {
    await init();
    final link = buildShareLink(node);
    final config = FlutterV2ray.parseFromURL(link);
    final granted = await requestPermission();
    if (!granted) throw Exception('VPN permission denied');
    await _v2ray.startV2Ray(
      remark: node.name,
      config: config.getFullConfiguration(),
      proxyOnly: proxyOnly,
    );
  }

  Future<void> disconnect() async => _v2ray.stopV2Ray();

  /// Đo độ trễ tới node (ms). -1 nếu timeout.
  Future<int> ping(ServerNode node) async {
    final link = buildShareLink(node);
    final config = FlutterV2ray.parseFromURL(link);
    return _v2ray.getServerDelay(config: config.getFullConfiguration());
  }

  /// Dựng share-link từ field v2board. Đọc protocol_settings trong raw.
  String buildShareLink(ServerNode n) {
    final ps = (n.raw['protocol_settings'] is Map)
        ? Map<String, dynamic>.from(n.raw['protocol_settings'])
        : <String, dynamic>{};
    final uuid = (n.raw['uuid'] ?? ps['uuid'] ?? '').toString();
    final port = n.port.toString().split('-').first; // lấy port đầu nếu là range
    final name = Uri.encodeComponent(n.name);

    switch (n.type) {
      case 'vless':
        final flow = ps['flow'] ?? '';
        final net = (ps['network'] ?? 'tcp').toString();
        final security = _tlsKind(ps);
        final q = <String, String>{
          'type': net,
          'security': security,
          if (flow.toString().isNotEmpty) 'flow': flow.toString(),
          ..._streamParams(ps, net, security),
        };
        return 'vless://$uuid@${n.host}:$port?${_qs(q)}#$name';

      case 'vmess':
        final net = (ps['network'] ?? 'tcp').toString();
        final vmess = {
          'v': '2',
          'ps': n.name,
          'add': n.host,
          'port': port,
          'id': uuid,
          'aid': (ps['alter_id'] ?? 0).toString(),
          'net': net,
          'type': 'none',
          'host': ps['host'] ?? '',
          'path': ps['path'] ?? '',
          'tls': _tlsKind(ps) == 'tls' ? 'tls' : '',
        };
        return 'vmess://${base64.encode(utf8.encode(jsonEncode(vmess)))}';

      case 'trojan':
        final q = <String, String>{
          'sni': (ps['server_name'] ?? n.host).toString(),
          'allowInsecure': '1',
        };
        return 'trojan://$uuid@${n.host}:$port?${_qs(q)}#$name';

      case 'shadowsocks':
        final method = (ps['cipher'] ?? 'aes-256-gcm').toString();
        final pwd = (n.raw['password'] ?? ps['password'] ?? uuid).toString();
        final userinfo = base64.encode(utf8.encode('$method:$pwd'));
        return 'ss://$userinfo@${n.host}:$port#$name';

      default:
        throw Exception('Unsupported node type: ${n.type}');
    }
  }

  String _tlsKind(Map ps) {
    final tls = (ps['tls'] ?? 0);
    final security = ps['security']?.toString();
    if (security == 'reality') return 'reality';
    if (tls == 1 || tls == true || security == 'tls') return 'tls';
    return 'none';
  }

  Map<String, String> _streamParams(Map ps, String net, String security) {
    final out = <String, String>{};
    if (net == 'ws') {
      out['path'] = (ps['path'] ?? '/').toString();
      if (ps['host'] != null) out['host'] = ps['host'].toString();
    } else if (net == 'grpc') {
      out['serviceName'] = (ps['service_name'] ?? ps['serviceName'] ?? '').toString();
    }
    if (security == 'tls' || security == 'reality') {
      out['sni'] = (ps['server_name'] ?? ps['sni'] ?? '').toString();
      if (ps['public_key'] != null) out['pbk'] = ps['public_key'].toString();
      if (ps['short_id'] != null) out['sid'] = ps['short_id'].toString();
      if (ps['fingerprint'] != null) out['fp'] = ps['fingerprint'].toString();
    }
    return out;
  }

  String _qs(Map<String, String> q) =>
      q.entries.where((e) => e.value.isNotEmpty).map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
}
