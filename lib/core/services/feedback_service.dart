import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class FeedbackService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'X-Platform': 'mobile',
    },
  ));

  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  Future<List<dynamic>> getMesFeedbacks() async {
    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) return [];

      final response = await _dio.get(
        '/feedbacks/mes-feedbacks',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
