import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'cart_service.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30), // ← AJOUTE
    receiveTimeout: const Duration(seconds: 30),  // ← AJOUTE
    sendTimeout: const Duration(seconds: 30),     // ← AJOUTE
    headers: {
      'Content-Type': 'application/json',
      'X-Platform': 'mobile',
    },
));
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();

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
 print('Login response: ${response.data}'); // Debug
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
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          throw Exception("Identifiants incorrects. Veuillez vérifier votre email et mot de passe.");
        }
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      throw Exception("Une erreur de réseau est survenue. Veuillez vérifier votre connexion.");
    } catch (e) {
      throw Exception("Une erreur inattendue est survenue.");
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
      // Nettoyer le téléphone pour enlever les espaces
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
      if (e.response != null) {
        if (e.response!.statusCode == 409) {
          throw Exception("Un compte avec cet email existe déjà.");
        }
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          throw Exception(e.response!.data['message']);
        }
      }
      throw Exception("Erreur lors de l'inscription. Vérifiez votre connexion.");
    } catch (e) {
      throw Exception("Une erreur inattendue est survenue.");
    }
  }

  // Gestion du Token
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> _saveUserInfo(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', data['id'] ?? '');
    await prefs.setString('user_email', data['email'] ?? '');
    await prefs.setString('user_nom', data['nom'] ?? '');
    await prefs.setString('user_prenom', data['prenom'] ?? '');
    await prefs.setString('user_telephone', data['telephone'] ?? '');
    await prefs.setInt('user_points', data['pointsFidelite'] ?? 0);
    await prefs.setString('user_image', data['image'] ?? '');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Récupérer le profil connecté
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(
        '/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _saveUserInfo(data);
        return data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le profil
  Future<Map<String, dynamic>?> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    String? password,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final cleanPhone = telephone.replaceAll(' ', '');

      final response = await _dio.put(
        ApiConfig.updateProfile,
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': cleanPhone,
          if (password != null && password.isNotEmpty) 'motDePasse': password,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _saveUserInfo(data);
        return data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_nom');
    await prefs.remove('user_prenom');
    await prefs.remove('user_telephone');
    await prefs.remove('user_points');
    await prefs.remove('user_image');
    await CartService().clearSession();
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConfig.resetPassword,
        data: {
          'email': email,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Erreur lors de la réinitialisation du mot de passe.");
    }
  }
}
