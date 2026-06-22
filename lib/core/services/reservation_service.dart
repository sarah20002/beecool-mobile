import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ReservationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'X-Platform': 'mobile',
    },
  ));

  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  /// Crée une réservation sur le backend
  Future<Map<String, dynamic>?> createReservation({
    required String etablissementId,
    required String dateHeure, // Format: yyyy-MM-ddTHH:mm:00
    required int nbPersonnes,
    String? nomReservation,
    bool cautionPayee = true,
    String? tableId,
    String? notes,
    String? stripePaymentIntentId,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception("Vous devez être connecté pour réserver.");
      }

      final response = await _dio.post(
        ApiConfig.reservations,
        data: {
          'etablissementId': etablissementId,
          'dateHeure': dateHeure,
          'nbPersonnes': nbPersonnes,
          'nomReservation': nomReservation,
          'cautionPayee': cautionPayee,
          'tableId': tableId,
          'notes': notes,
          'stripePaymentIntentId': stripePaymentIntentId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère la liste des réservations du client connecté
  Future<List<dynamic>> fetchUserReservations() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception("Vous devez être connecté pour voir vos réservations.");
      }

      final response = await _dio.get(
        ApiConfig.reservations,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
      return [];
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Annule une réservation
  Future<bool> cancelReservation(int reservationId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception("Vous devez être connecté pour annuler une réservation.");
      }

      final response = await _dio.put(
        '${ApiConfig.reservations}/$reservationId/annuler',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map && e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
