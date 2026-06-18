import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/server_node.dart';

/// Tải link subscribe của user và parse ra danh sách node (giống v2rayNG).
/// Đây là nguồn CHÂN LÝ: link đã chứa sẵn đúng password/port/cipher nên
/// connect luôn khớp với server, không cần tự đoán.
class SubscribeService {
  SubscribeService._();
  static final SubscribeService instance = SubscribeService._();

  Future<List<ServerNode>> fetch(String subscribeUrl) async {
    final dio = Dio();
    final res = await dio.get(
      subscribeUrl,
      options: Options(
        headers: {'User-Agent': 'v2rayNG/1.8.0'},
        responseType: ResponseType.plain,
        followRedirects: true,
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    String body = res.data.toString().trim();

    // Subscribe v2board thường trả base64 của danh sách link. Thử decode.
    String decoded = body;
    final maybe = _tryBase64(body);
    if (maybe != null) decoded = maybe;

    final lines = decoded
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    final nodes = <ServerNode>[];
    int id = 0;
    for (final l in lines) {
      if (l.startsWith('ss://') ||
          l.startsWith('vmess://') ||
          l.startsWith('vless://') ||
          l.startsWith('trojan://')) {
        try {
          nodes.add(ServerNode.fromLink(id++, l));
        } catch (_) {}
      }
    }
    return nodes;
  }

  String? _tryBase64(String s) {
    try {
      final clean = s.replaceAll(RegExp(r'\s'), '');
      // base64 hợp lệ và decode ra chứa scheme link
      final out = utf8.decode(base64.decode(base64.normalize(clean)));
      if (out.contains('://')) return out;
    } catch (_) {}
    return null;
  }
}
