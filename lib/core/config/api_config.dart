import 'package:flutter/foundation.dart';

class ApiConfig {
  // Mise à jour automatique de l'IP du PC
  static const String _localIp = '192.168.155.222'; 

  static String get baseUrl {
    if (kIsWeb) {

           return 'http://localhost:8081/api';

     // return 'https://beecool.back.dpc.com.tn/api';
    }
  return 'http://$_localIp:8081/api';
   // return 'https://beecool.back.dpc.com.tn/api';
  } 
  
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String updateProfile = '/auth/update-profile';
  static const String resetPassword = '/auth/reset-password';
  static const String scanTable = '/tables/'; // + {token} + /scan
  static const String etablissements = '/etablissements';
  static const String reservations = '/reservations';
  static String platsParEtablissement(String id) => '/menu/$id/plats';
  static String categoriesParEtablissement(String id) => '/menu/$id';
  static String aiRecommend(String platId, {String? etablissementId}) {
    String url = '/v1/analytics/ai/recommend/$platId';
    if (etablissementId != null) {
      url += '?etablissementId=$etablissementId';
    }
    return url;
  }
}
