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

  String _config(ServerNode node) {
    final link = _rawLink(node);
    final parser = FlutterV2ray.parseFromURL(link);
    final raw = parser.getFullConfiguration();
    Map<String, dynamic> cfg;
    try {
      cfg = Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
    if (cfg['inbounds'] is List) {
      for (final inb in (cfg['inbounds'] as List)) {
        if (inb is Map) {
          inb['sniffing'] = {
            'enabled': true,
            'destOverride': ['http', 'tls', 'quic'],
            'routeOnly': false
          };
          if (inb['protocol'] == 'socks') {
            inb['settings'] ??= {};
            if (inb['settings'] is Map) inb['settings']['udp'] = true;
          }
        }
      }
    }
    final proxy = _proxyOutbound(link, raw);
    if (proxy == null) return raw;
    cfg['outbounds'] = [
      proxy,
      {'tag': 'direct', 'protocol': 'freedom', 'settings': {'domainStrategy': 'UseIP'}},
      {'tag': 'block', 'protocol': 'blackhole', 'settings': {'response': {'type': 'http'}}}
    ];
    cfg['routing'] = {
      'domainStrategy': 'AsIs',
      'rules': [
        {'type': 'field', 'ip': ['geoip:private'], 'outboundTag': 'direct'},
        {'type': 'field', 'port': '0-65535', 'outboundTag': 'proxy'}
      ]
    };
    cfg['dns'] = {'servers': ['1.1.1.1', '8.8.8.8'], 'queryStrategy': 'UseIPv4'};
    return jsonEncode(cfg);
  }

  Map<String, dynamic>? _proxyOutbound(String link, String raw) {
    if (link.startsWith('ss://')) {
      final ss = _parseSs(link);
      if (ss == null) return null;
      return {
        'tag': 'proxy',
        'protocol': 'shadowsocks',
        'settings': {
          'servers': [
            {'address': ss['address'], 'port': ss['port'], 'method': ss['method'], 'password': ss['password'], 'level': 8, 'ota': false}
          ]
        },
        'streamSettings': {'network': 'tcp'},
        'mux': {'enabled': false, 'concurrency': -1}
      };
    }
    try {
      final cfg = jsonDecode(raw);
      final outs = cfg['outbounds'];
      if (outs is List) {
        for (final ob in outs) {
          if (ob is Map && ob['protocol'] != 'freedom' && ob['protocol'] != 'blackhole') {
            final m = Map<String, dynamic>.from(ob);
            m['tag'] = 'proxy';
            return m;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _parseSs(String link) {
    try {
      String body = link.substring('ss://'.length);
      final hashIdx = body.indexOf('#');
      if (hashIdx >= 0) body = body.substring(0, hashIdx);
      String method, password, host;
      int port;
      if (body.contains('@')) {
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
      return {'address': host, 'port': port, 'method': method, 'password': password};
    } catch (_) {
      return null;
    }
  }

  Future<void> connect(ServerNode node, {bool proxyOnly = false}) async {
    await init();
    if (!await requestPermission()) throw Exception('VPN permission denied');
    await _v2ray.startV2Ray(remark: node.cleanName, config: _config(node), proxyOnly: proxyOnly);
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
