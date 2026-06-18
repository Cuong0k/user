import 'dart:convert';
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

  String lastRawState = '(chua co)';
  String lastConfig = '';
  final List<String> debugTrace = [];

  void _trace(String s) {
    debugTrace.add('${DateTime.now().toIso8601String().substring(11, 19)}  $s');
    if (debugTrace.length > 60) debugTrace.removeAt(0);
  }

  Future<void> init() async {
    if (_inited) return;
    _v2ray = V2ray(
      onStatusChanged: (status) {
        lastRawState = status.state;
        _trace('status=${status.state} up=${status.upload} down=${status.download}');
        onStatus?.call(_map(status.state), status);
      },
    );
    await _v2ray.initialize(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
    _trace('initialize() done');
    _inited = true;
  }

  VpnState _map(String s) {
    final u = s.toUpperCase();
    if (u.contains('CONNECTED')) return VpnState.connected;
    if (u.contains('CONNECTING')) return VpnState.connecting;
    if (u.contains('DISCONNECTING')) return VpnState.disconnecting;
    return VpnState.disconnected;
  }

  Future<bool> requestPermission() => _v2ray.requestPermission();

  String _rawLink(ServerNode node) {
    final link = node.shareLink;
    if (link == null || link.isEmpty) throw Exception('Node has no share link');
    return link;
  }

  String _sanitize(String raw) {
    try {
      final m = Map<String, dynamic>.from(jsonDecode(raw));
      if (m['inbounds'] is List) {
        for (final inb in (m['inbounds'] as List)) {
          if (inb is Map) {
            inb['sniffing'] = {'enabled': true, 'destOverride': ['http', 'tls']};
          }
        }
      }
      if (m['outbounds'] is List) {
        for (final ob in (m['outbounds'] as List)) {
          if (ob is Map && ob['protocol'] == 'shadowsocks') {
            ob.remove('streamSettings');
            ob.remove('mux');
          }
        }
      }
      m['routing'] = {
        'domainStrategy': 'AsIs',
        'rules': [
          {'type': 'field', 'port': 53, 'outboundTag': 'direct'},
          {'type': 'field', 'network': 'tcp,udp', 'outboundTag': 'proxy'}
        ]
      };
      m['dns'] = {'servers': ['1.1.1.1', '8.8.8.8']};
      return jsonEncode(m);
    } catch (e) {
      _trace('sanitize loi: $e');
      return raw;
    }
  }

  Future<void> connect(ServerNode node, {bool proxyOnly = false}) async {
    _trace('connect() start node=${node.cleanName}');
    await init();
    final link = _rawLink(node);
    final parser = V2ray.parseFromURL(link);
    _trace('parsed remark=${parser.remark}');
    final cfg = _sanitize(parser.getFullConfiguration());
    lastConfig = cfg;
    _trace('config len=${cfg.length}');
    if (!proxyOnly) {
      final ok = await requestPermission();
      _trace('requestPermission=$ok');
      if (!ok) throw Exception('VPN permission denied');
    }
    final remark = node.cleanName.isNotEmpty ? node.cleanName : parser.remark;
    await _v2ray.startV2Ray(
      remark: remark,
      config: cfg,
      blockedApps: null,
      bypassSubnets: null,
      proxyOnly: proxyOnly,
    );
    _trace('startV2Ray() returned');
  }

  Future<void> disconnect() async {
    _trace('disconnect()');
    await _v2ray.stopV2Ray();
  }

  Future<List<String>> fetchLogs() async {
    try {
      final logs = await _v2ray.getLogs();
      return logs.isEmpty ? ['(log rong)'] : logs;
    } catch (e) {
      return ['getLogs loi: $e'];
    }
  }

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
