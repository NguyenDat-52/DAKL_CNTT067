import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthViewModel() {
    loadSavedUser();
  }

  Future<void> loadSavedUser() async {
    _currentUser = await StorageService.getUser();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await ApiService.login(username, password);
      _currentUser = user;
      await StorageService.saveUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    String? email,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.register(
        username: username,
        password: password,
        fullName: fullName,
        phone: phone,
        email: email,
        address: address,
      );
      // Auto login after register
      final user = await ApiService.login(username, password);
      _currentUser = user;
      await StorageService.saveUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    required String email,
  }) async {
    if (_currentUser == null || _currentUser!.maKhachHang == null) {
      _errorMessage = 'Bạn chưa đăng nhập.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await ApiService.updateProfile(
        customerId: _currentUser!.maKhachHang!,
        hoTen: fullName,
        soDienThoai: phone,
        diaChi: address,
        email: email,
      );

      // Preserve token and role
      _currentUser = _currentUser!.copyWith(
        hoTen: updatedUser.hoTen,
        soDienThoai: updatedUser.soDienThoai,
        diaChi: updatedUser.diaChi,
        email: updatedUser.email,
      );

      await StorageService.saveUser(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (_currentUser == null || _currentUser!.maKhachHang == null) return;
    try {
      final data = await ApiService.getProfile(_currentUser!.maKhachHang!);
      _currentUser = _currentUser!.copyWith(
        hoTen: data['hoTen'] ?? _currentUser!.hoTen,
        soDienThoai: data['soDienThoai'] ?? _currentUser!.soDienThoai,
        diaChi: data['diaChi'] ?? _currentUser!.diaChi,
        email: data['email'] ?? _currentUser!.email,
      );
      await StorageService.saveUser(_currentUser!);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    _currentUser = null;
    await StorageService.clearUser();
    notifyListeners();
  }
}
