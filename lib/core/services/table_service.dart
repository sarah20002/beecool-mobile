import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class TableService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Singleton
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;
  TableService._internal();

  // Scanner une table et récupérer le token de session
  Future<Map<String, dynamic>?> scanTable(String tableToken) async {
    try {
      final response = await _dio.get('${ApiConfig.scanTable}$tableToken/scan');

      if (response.statusCode == 200) {
        final data = response.data;
        final String? sessionToken = data['token'];

        if (sessionToken != null) {
          await _saveSessionToken(sessionToken);
        }
        return data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
  }

  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_token');
  }
}
