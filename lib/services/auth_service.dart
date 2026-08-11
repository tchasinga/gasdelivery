import 'package:shared_preferences/shared_preferences.dart';
import 'api_services.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _customerIdKey = 'customer_id';
  static const String _customerNameKey = 'customer_name';
  static const String _customerSurnameKey = 'customer_surname';
  static const String _customerPhoneKey = 'customer_phone';

  static Future<({bool hasToken})> readSessionSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final hasToken = token != null && token.isNotEmpty;
    return (hasToken: hasToken);
  }

  static Future<bool> isAuthenticated() async {
    try {
      final snap = await readSessionSnapshot();
      return snap.hasToken;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveAuthData({
    required String token,
    required int customerId,
    required String customerName,
    required String customerPhone,
    String? customerSurname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_customerIdKey, customerId);
    await prefs.setString(_customerNameKey, customerName);
    await prefs.setString(_customerPhoneKey, customerPhone);
    if (customerSurname != null && customerSurname.isNotEmpty) {
      await prefs.setString(_customerSurnameKey, customerSurname);
    } else {
      await prefs.remove(_customerSurnameKey);
    }
  }

  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_customerIdKey);
      await prefs.remove(_customerNameKey);
      await prefs.remove(_customerSurnameKey);
      await prefs.remove(_customerPhoneKey);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getCustomerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt(_customerIdKey);
      final customerName = prefs.getString(_customerNameKey);
      final customerSurname = prefs.getString(_customerSurnameKey);
      final customerPhone = prefs.getString(_customerPhoneKey);
      if (customerId != null && customerName != null && customerPhone != null) {
        return {
          'id': customerId,
          'account_customer_name': customerName,
          'account_customer_surname': customerSurname ?? '',
          'account_customer_phone_number': customerPhone,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String accountCustomerName,
    required String accountCustomerSurname,
    required String accountCustomerPhoneNumber,
    String? accountCustomerAddress,
  }) async {
    return ApiService.signup(
      accountCustomerName: accountCustomerName,
      accountCustomerSurname: accountCustomerSurname,
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
      accountCustomerAddress: accountCustomerAddress,
    );
  }

  static Future<Map<String, dynamic>> login({
    required String accountCustomerPhoneNumber,
  }) async {
    return ApiService.login(
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
    );
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String accountCustomerPhoneNumber,
    required String accountOptCode,
  }) async {
    final result = await ApiService.verifyOtp(
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
      accountOptCode: accountOptCode,
    );
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['token'] != null && data['customer'] != null) {
        final customer = data['customer'] as Map<String, dynamic>;
        await saveAuthData(
          token: data['token'] as String,
          customerId: customer['id'] as int,
          customerName: customer['account_customer_name'] as String,
          customerSurname:
              customer['account_customer_surname'] as String? ?? '',
          customerPhone: customer['account_customer_phone_number'] as String,
        );
      }
    }
    return result;
  }

  static Future<void> logout() async {
    await clearAuthData();
  }
}
