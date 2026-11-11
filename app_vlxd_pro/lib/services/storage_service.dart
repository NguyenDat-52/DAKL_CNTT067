import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/cart_item_model.dart';

class StorageService {
  static const String _keyUser = 'vlxd_user_profile';
  static const String _keyToken = 'vlxd_auth_token';
  static const String _keyCart = 'vlxd_local_cart';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    if (user.token != null) {
      await prefs.setString(_keyToken, user.token!);
    }
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(userJson);
        final token = prefs.getString(_keyToken);
        return UserModel.fromJson(map, token: token);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
  }

  // --- Cart Persistence ---
  static Future<void> saveCart(List<CartItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = items.map((e) => e.toJson()).toList();
    await prefs.setString(_keyCart, jsonEncode(list));
  }

  static Future<List<CartItemModel>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_keyCart);
    if (cartJson != null && cartJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cartJson);
        return list.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }
}
