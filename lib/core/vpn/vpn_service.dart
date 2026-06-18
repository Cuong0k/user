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

  String _rawLink(ServerNode node) {
    final link = node.shareLink;
    if (link == null || link.isEmpty) throw Exception('Node has no share link');
    return link;
  }

  /// Build config xray. Với shadowsocks tự dựng tay (parser thư viện hay sai
  /// định dạng SIP002). Các loại khác dùng parseFromURL rồi chèn DNS.
  String _config(ServerNode node) {
    final link = _rawLink(node);
    if (link.startsWith('ss://')) {
      final cfg = _buildSsConfig(link);
      if (cfg != null) return cfg;
    }
    final parsed = FlutterV2ray.parseFromURL(link);
    final cfg = jsonDecode(parsed.getFullConfiguration());
    if (cfg is Map<String, dynamic>) {
      cfg['dns'] = {'servers': ['1.1.1.1', '8.8.8.8', 'localhost']};
      return jsonEncode(cfg);
    }
    return parsed.getFullConfiguration();
  }

  /// Giải mã ss:// (cả SIP002 lẫn legacy) -> config xray hoàn chỉnh.
  String? _buildSsConfig(String link) {
    try {
      String body = link.substring('ss://'.length);
      final hashIdx = body.indexOf('#');
      if (hashIdx >= 0) body = body.substring(0, hashIdx);

      String method, password, host;
      int port;

      if (body.contains('@')) {
        // SIP002: base64(method:password)@host:port
        final at = body.lastIndexOf('@');
        final ui = utf8.decode(base64.decode(base64.normalize(body.substring(0, at))));
        final ci = ui.indexOf(':');
        method = ui.substring(0, ci);
        password = ui.substring(ci + 1);
        final hp = body.substring(at + 1).split('?').first;
        final colon = hp.lastIndexOf(':');
        host = hp.substring(0, colon);
        port = int.parse(hp.substring(colon + 1));
      } else {
        // legacy: base64(method:password@host:port)
        final d = utf8.decode(base64.decode(base64.normalize(body)));
        final at = d.lastIndexOf('@');
        final ui = d.substring(0, at);
        final ci = ui.indexOf(':');
        method = ui.substring(0, ci);
        password = ui.substring(ci + 1);
        final hp = d.substring(at + 1);
        final colon = hp.lastIndexOf(':');
        host = hp.substring(0, colon);
        port = int.parse(hp.substring(colon + 1));
      }

      final config = {
        "remarks": "ss",
        "log": {"loglevel": "warning"},
        "dns": {"servers": ["1.1.1.1", "8.8.8.8", "localhost"]},
        "inbounds": [
          {
            "tag": "socks",
            "port": 10808,
            "protocol": "socks",
            "settings": {"auth": "noauth", "udp": true, "userLevel": 8},
            "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
          },
          {
            "tag": "http",
            "port": 10809,
            "protocol": "http",
            "settings": {"userLevel": 8}
          }
        ],
        "outbounds": [
          {
            "tag": "proxy",
            "protocol": "shadowsocks",
            "settings": {
              "servers": [
                {
                  "address": host,
                  "port": port,
                  "method": method,
                  "password": password,
                  "level": 8
                }
              ]
            },
            "streamSettings": {"network": "tcp"}
          },
          {"tag": "direct", "protocol": "freedom", "settings": {}},
          {
            "tag": "block",
            "protocol": "blackhole",
            "settings": {"response": {"type": "http"}}
          }
        ],
        "routing": {
          "domainStrategy": "IPIfNonMatch",
          "rules": [
            {"type": "field", "outboundTag": "proxy", "port": "0-65535"}
          ]
        }
      };
      return jsonEncode(config);
    } catch (_) {
      return null;
    }
  }

  Future<void> connect(ServerNode node, {bool proxyOnly = false}) async {
    await init();
    if (!await requestPermission()) throw Exception('VPN permission denied');
    await _v2ray.startV2Ray(
      remark: node.cleanName,
      config: _config(node),
      proxyOnly: proxyOnly,
    );
  }

  Future<void> disconnect() async => _v2ray.stopV2Ray();

  /// Ping TCP tới host:port của node.
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
