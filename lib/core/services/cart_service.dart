import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  String notes;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'platId': id,
    'quantite': quantity,
    'notes': notes,
  };
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal() {
    _loadFromPrefs();
  }

  final List<CartItem> _items = [];
  String? _sessionToken;
  String? _etablissementId;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get sessionToken => _sessionToken;
  String? get etablissementId => _etablissementId;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString('session_token');
    _etablissementId = prefs.getString('etablissement_id');
    notifyListeners();
  }

  Future<void> setSessionToken(String token) async {
    _sessionToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
    notifyListeners();
  }

  Future<void> setEtablissementId(String id) async {
    _etablissementId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('etablissement_id', id);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _sessionToken = null;
    _etablissementId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('etablissement_id');
    notifyListeners();
  }

  void addItem(CartItem item) {
    // Vérifier si l'item existe déjà avec la même note
    final index = _items.indexWhere((i) => i.id == item.id && i.notes == item.notes);
    if (index != null && index >= 0) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateQuantity(int index, int delta) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void updateItem(int index, {int? quantity, String? notes}) {
    if (index >= 0 && index < _items.length) {
      if (quantity != null) {
        _items[index].quantity = quantity;
      }
      if (notes != null) {
        _items[index].notes = notes;
      }
      notifyListeners();
    }
  }

  double get total {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
