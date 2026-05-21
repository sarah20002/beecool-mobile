import 'package:flutter/foundation.dart';

class ApiConfig {
  // Utilisation de l'IP locale pour le test sur mobile physique (mise à jour à 192.168.1.55)
  static const String _localIp = '192.168.1.55'; 

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8081/api';
    }
    return 'http://$_localIp:8081/api';
  } 
  
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String updateProfile = '/auth/update-profile';
  static const String scanTable = '/tables/'; // + {token} + /scan
  static const String etablissements = '/etablissements';
  static const String reservations = '/reservations';
  static String platsParEtablissement(String id) => '/menu/$id/plats';
  static String categoriesParEtablissement(String id) => '/menu/$id';
}
