import 'dart:convert';
import 'package:coffeeapp/models/cartitem.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartStorageService {
  static const String _CART_KEY = 'cart_items';

  Future<void> saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = items.map((item) {
      return jsonEncode(item.toJson(item.idOrder));
    }).toList();
    await prefs.setStringList(_CART_KEY, jsonList);
  }

  Future<List<CartItem>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(_CART_KEY);

    if (jsonList == null) return [];

    try {
      return jsonList.map((jsonStr) {
        Map<String, dynamic> json = jsonDecode(jsonStr);
        return CartItem.fromJson(json);
      }).toList();
    } catch (e) {
      print("Error loading cart: $e");
      return [];
    }
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_CART_KEY);
  }
}
