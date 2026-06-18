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
        _trace('status=${status.state} up=${status.upload} dn=${status.download}');
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

  String? _extractSsHost(String rawConfig) {
    try {
      final m = jsonDecode(rawConfig);
      final outs = m['outbounds'];
      if (outs is! List) return null;
      for (final ob in outs) {
        if (ob is Map && ob['protocol'] == 'shadowsocks') {
          final servers = ob['settings']?['servers'];
          if (servers is List && servers.isNotEmpty) {
            return servers[0]['address'] as String?;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> connect(ServerNode node, {bool proxyOnly = false}) async {
    _trace('connect() start node=${node.cleanName}');
    await init();
    final link = _rawLink(node);
    final parser = V2ray.parseFromURL(link);
    _trace('parsed remark=${parser.remark}');
    final rawCfg = parser.getFullConfiguration();
    final ssHost = _extractSsHost(rawCfg);
    _trace('ss host: $ssHost');
    List<String>? bypassSubnets;
    if (!proxyOnly && ssHost != null) {
      try {
        final addrs = await InternetAddress.lookup(ssHost);
        bypassSubnets = addrs
            .where((a) => a.type == InternetAddressType.IPv4)
            .map((a) => '${a.address}/32')
            .toList();
        if (bypassSubnets.isEmpty) bypassSubnets = null;
        _trace('bypass: $bypassSubnets');
      } catch (e) {
        _trace('lookup failed: $e');
      }
    }
    lastConfig = rawCfg;
    _trace('config len=${rawCfg.length}');
    if (!proxyOnly) {
      final ok = await requestPermission();
      _trace('requestPermission=$ok');
      if (!ok) throw Exception('VPN permission denied');
    }
    final remark = node.cleanName.isNotEmpty ? node.cleanName : parser.remark;
    await _v2ray.startV2Ray(
      remark: remark,
      config: rawCfg,
      blockedApps: null,
      bypassSubnets: bypassSubnets,
      proxyOnly: proxyOnly,
    );
    _trace('startV2Ray() returned');
  }

  Future<void> disconnect() async {
    _trace('disconnect()');
    try { await _v2ray.stopV2Ray(); } catch (e) { _trace('stop err: $e'); }
  }

  Future<List<String>> fetchLogs() async {
    try {
      final logs = await _v2ray.getLogs();
      return logs.isEmpty ? ['(log rong)'] : logs;
    } catch (e) { return ['getLogs: $e']; }
  }

  Future<int> ping(ServerNode node) async {
    final host = node.host;
    final port = int.tryParse(node.port.split('-').first) ?? 443;
    if (host.isEmpty) return -1;
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      sw.stop(); return sw.elapsedMilliseconds;
    } catch (_) { return -1; } finally { socket?.destroy(); }
  }
}
