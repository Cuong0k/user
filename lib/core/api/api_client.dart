import 'package:dio/dio.dart';
import '../storage/auth_storage.dart';
import 'api_endpoints.dart';

/// Lỗi API chuẩn hoá.
class ApiException implements Exception {
  final String message;
  final int? code;
  ApiException(this.message, {this.code});
  @override
  String toString() => message;
}

/// Client gọi v2board. Tự gắn Authorization token, tự bóc tách `{ "data": ... }`.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.instance.getToken();
          if (token != null && token.isNotEmpty) {
            // v2board nhận token qua header Authorization (kiểu auth_data)
            options.headers['Authorization'] = token;
          }
          handler.next(options);
        },
        onError: (e, handler) {
          handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  /// GET trả về `data` đã bóc tách.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _wrap(() => _dio.get(path, queryParameters: query));
  }

  /// POST trả về `data` đã bóc tách.
  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query}) async {
    return _wrap(() => _dio.post(path, data: data, queryParameters: query));
  }

  Future<dynamic> _wrap(Future<Response> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } on DioException catch (e) {
      // v2board thường trả { "message": "..." } khi lỗi
      final data = e.response?.data;
      String msg = 'Connection error';
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else if (e.type == DioExceptionType.connectionTimeout) {
        msg = 'Connection timeout';
      }
      throw ApiException(msg, code: e.response?.statusCode);
    }
  }
}
