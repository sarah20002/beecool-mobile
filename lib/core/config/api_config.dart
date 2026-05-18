class ApiConfig {
  // Utilisation de l'IP locale pour le test sur mobile physique
  static const String baseUrl = 'http://192.168.1.55:8081/api'; 
  
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String updateProfile = '/auth/update-profile';
  static const String scanTable = '/tables/'; // + {token} + /scan
  static const String etablissements = '/etablissements';
  static String platsParEtablissement(String id) => '/menu/$id/plats';
  static String categoriesParEtablissement(String id) => '/menu/$id';
}
