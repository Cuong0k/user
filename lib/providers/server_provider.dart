import 'package:flutter/foundation.dart';
import '../core/api/v2board_service.dart';
import '../core/api/subscribe_service.dart';
import '../core/models/server_node.dart';

class ServerProvider extends ChangeNotifier {
  final _svc = V2BoardService.instance;

  List<ServerNode> _nodes = [];
  ServerNode? _selected;
  bool _loading = false;
  String? _error;
  final Map<int, int> _pings = {}; // id -> ms

  List<ServerNode> get nodes => _nodes;
  ServerNode? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;
  Map<int, int> get pings => _pings;

  /// Gom node theo quốc gia để hiển thị màn "Country/Region".
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
      // Ưu tiên: tải node TỪ LINK SUBSCRIBE (giống v2rayNG -> luôn kết nối được)
      final info = await _svc.getSubscribeInfo();
      final subUrl = (info['subscribe_url'] ?? '').toString();
      if (subUrl.isNotEmpty) {
        _nodes = await SubscribeService.instance.fetch(subUrl);
      }
      // Dự phòng: nếu subscribe rỗng thì dùng server/fetch
      if (_nodes.isEmpty) {
        _nodes = await _svc.fetchServers();
      }
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
