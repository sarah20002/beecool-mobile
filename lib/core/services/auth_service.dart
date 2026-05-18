import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'cart_service.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'X-Platform': 'mobile', // Très important pour le Backend !
    },
  ));

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Connexion
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'email': email,
          'motDePasse': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final String? token = data['token'];

        if (token != null) {
          await _saveToken(token);
          await _saveUserInfo(data);
        }
        return data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Inscription
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String telephone,
  }) async {
    try {
      // Nettoyer le téléphone pour enlever les espaces (le backend refuse les espaces)
      final cleanPhone = telephone.replaceAll(' ', '');

      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'motDePasse': password,
          'telephone': cleanPhone,
        },
      );
      if (response.statusCode == 201) {
        final data = response.data;
        final String? token = data['token'];
        if (token != null) {
          await _saveToken(token);
          await _saveUserInfo(data);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Gestion du Token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> _saveUserInfo(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', data['email'] ?? '');
    await prefs.setString('user_nom', data['nom'] ?? '');
    await prefs.setString('user_prenom', data['prenom'] ?? '');
    await prefs.setInt('user_points', data['pointsFidelite'] ?? 0);
    await prefs.setString('user_image', data['image'] ?? '');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await CartService().clearSession();
  }
}
