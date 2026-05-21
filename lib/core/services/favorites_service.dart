import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class FavoritesService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'X-Platform': 'mobile',
    },
  ));

  // Récupérer la liste des favoris du client
  Future<List<dynamic>> getFavorites() async {
    try {
      final token = await AuthService().getToken();
      final prefs = await SharedPreferences.getInstance();
      final clientId = prefs.getString('user_id') ?? '';

      if (clientId.isEmpty) return [];

      final response = await _dio.get(
        '/favoris/client/$clientId',
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

  // Ajouter un plat aux favoris du client
  Future<bool> addFavorite(String platId) async {
    try {
      final token = await AuthService().getToken();
      final prefs = await SharedPreferences.getInstance();
      final clientId = prefs.getString('user_id') ?? '';

      if (clientId.isEmpty || platId.isEmpty) return false;

      final response = await _dio.post(
        '/favoris/client/$clientId/plat/$platId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Retirer un plat des favoris du client
  Future<bool> removeFavorite(String platId) async {
    try {
      final token = await AuthService().getToken();
      final prefs = await SharedPreferences.getInstance();
      final clientId = prefs.getString('user_id') ?? '';

      if (clientId.isEmpty || platId.isEmpty) return false;

      final response = await _dio.delete(
        '/favoris/client/$clientId/plat/$platId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
