import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isInitializing = true;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _customerData;

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get customerData => _customerData;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isInitializing = true;
    notifyListeners();
    _isAuthenticated = await AuthService.isAuthenticated();
    if (_isAuthenticated) {
      _customerData = await AuthService.getCustomerData();
    } else {
      _customerData = null;
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> signup({
    required String accountCustomerName,
    required String accountCustomerSurname,
    required String accountCustomerPhoneNumber,
    String? accountCustomerAddress,
  }) async {
    return AuthService.signup(
      accountCustomerName: accountCustomerName,
      accountCustomerSurname: accountCustomerSurname,
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
      accountCustomerAddress: accountCustomerAddress,
    );
  }

  Future<Map<String, dynamic>> login({
    required String accountCustomerPhoneNumber,
  }) async {
    return AuthService.login(
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String accountCustomerPhoneNumber,
    required String accountOptCode,
  }) async {
    final result = await AuthService.verifyOtp(
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
      accountOptCode: accountOptCode,
    );
    if (result['success'] == true) {
      await checkAuthStatus();
    }
    return result;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _customerData = null;
    notifyListeners();
  }
}
