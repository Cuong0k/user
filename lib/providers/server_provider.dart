import 'package:flutter/foundation.dart';
import '../core/api/v2board_service.dart';
import '../core/api/subscribe_service.dart';
import '../core/api/api_endpoints.dart';
import '../core/models/server_node.dart';

class ServerProvider extends ChangeNotifier {
  final _svc = V2BoardService.instance;

  List<ServerNode> _nodes = [];
  ServerNode? _selected;
  bool _loading = false;
  String? _error;
  final Map<int, int> _pings = {};

  List<ServerNode> get nodes => _nodes;
  ServerNode? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;
  Map<int, int> get pings => _pings;

  Map<String, List<ServerNode>> get byCountry {
    final m = <String, List<ServerNode>>{};
    for (final n in _nodes) {
      m.putIfAbsent(n.countryCode, () => []).add(n);
    }
    return m;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Lấy token subscribe từ API, rồi tải node TỪ ENDPOINT TRỰC TIẾP của panel
      // (không dùng subscribe_url rút gọn vì domain đó bị chặn access).
      final info = await _svc.getSubscribeInfo();
      final token = (info['token'] ?? '').toString();
      if (token.isNotEmpty) {
        final url = '${Api.baseUrl}/api/v1/client/subscribe?token=$token';
        _nodes = await SubscribeService.instance.fetch(url);
      }
      // Dự phòng: nếu vẫn rỗng thì thử subscribe_url gốc rồi tới server/fetch
      if (_nodes.isEmpty) {
        final sub = (info['subscribe_url'] ?? '').toString();
        if (sub.isNotEmpty) _nodes = await SubscribeService.instance.fetch(sub);
      }
      if (_nodes.isEmpty) _nodes = await _svc.fetchServers();

      _selected ??= _nodes.isNotEmpty ? _nodes.first : null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void select(ServerNode node) {
    _selected = node;
    notifyListeners();
  }

  void setPing(int id, int ms) {
    _pings[id] = ms;
    notifyListeners();
  }
}
