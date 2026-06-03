import 'package:cross_file/cross_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_services.dart';

/// Values stored under [authRoleKey].
abstract class AppAuthRole {
  static const String customerAccounts = 'customer_accounts';
  static const String riders = 'riders';
}

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String authRoleKey = 'auth_role';
  static const String _customerIdKey = 'customer_id';
  static const String _customerNameKey = 'customer_name';
  static const String _customerPhoneKey = 'customer_phone';
  static const String _riderIdKey = 'rider_id';
  static const String _riderNameKey = 'rider_name';
  static const String _riderEmailKey = 'rider_email';
  static const String _riderPhoneKey = 'rider_phone';

  /// Reads token + role from the same [SharedPreferences] instance so a login
  /// cannot interleave between two awaits and leave mismatched state.
  static Future<({bool hasToken, String role})> readSessionSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final hasToken = token != null && token.isNotEmpty;
    final role = prefs.getString(authRoleKey) ?? AppAuthRole.customerAccounts;
    return (hasToken: hasToken, role: role);
  }

  static Future<bool> isAuthenticated() async {
    try {
      final snap = await readSessionSnapshot();
      return snap.hasToken;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  static Future<String> getAuthRole() async {
    final snap = await readSessionSnapshot();
    return snap.role;
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<void> saveAuthData({
    required String token,
    required int customerId,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(authRoleKey, AppAuthRole.customerAccounts);
      await prefs.setInt(_customerIdKey, customerId);
      await prefs.setString(_customerNameKey, customerName);
      await prefs.setString(_customerPhoneKey, customerPhone);
      await prefs.remove(_riderIdKey);
      await prefs.remove(_riderNameKey);
      await prefs.remove(_riderEmailKey);
      await prefs.remove(_riderPhoneKey);
    } catch (e) {
      print('Error saving authentication data: $e');
      throw Exception('Failed to save authentication data. Please restart the app.');
    }
  }

  static Future<void> saveRiderAuthData({
    required String token,
    required int riderId,
    required String fullName,
    required String email,
    String? phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(authRoleKey, AppAuthRole.riders);
    await prefs.setInt(_riderIdKey, riderId);
    await prefs.setString(_riderNameKey, fullName);
    await prefs.setString(_riderEmailKey, email);
    final phone = phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString(_riderPhoneKey, phone);
    } else {
      await prefs.remove(_riderPhoneKey);
    }
    await prefs.remove(_customerIdKey);
    await prefs.remove(_customerNameKey);
    await prefs.remove(_customerPhoneKey);
  }

  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(authRoleKey);
      await prefs.remove(_customerIdKey);
      await prefs.remove(_customerNameKey);
      await prefs.remove(_customerPhoneKey);
      await prefs.remove(_riderIdKey);
      await prefs.remove(_riderNameKey);
      await prefs.remove(_riderEmailKey);
      await prefs.remove(_riderPhoneKey);
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCustomerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt(_customerIdKey);
      final customerName = prefs.getString(_customerNameKey);
      final customerPhone = prefs.getString(_customerPhoneKey);

      if (customerId != null && customerName != null && customerPhone != null) {
        return {
          'id': customerId,
          'account_customer_name': customerName,
          'account_customer_phone_number': customerPhone,
        };
      }
      return null;
    } catch (e) {
      print('Error getting customer data: $e');
      return null;
    }
  }

  static Future<String?> getRiderDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_riderNameKey);
  }

  /// Values saved at login; used if `/user` is unavailable offline.
  static Future<Map<String, dynamic>> getCachedRiderProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_riderIdKey);
    final name = prefs.getString(_riderNameKey);
    final email = prefs.getString(_riderEmailKey);
    final phone = prefs.getString(_riderPhoneKey);
    return {
      if (id != null && id > 0) 'id': id,
      if (name != null && name.isNotEmpty) 'full_name': name,
      if (email != null && email.isNotEmpty) 'email_address': email,
      if (phone != null && phone.isNotEmpty) 'phone_number': phone,
    };
  }

  static Future<Map<String, dynamic>> fetchAuthenticatedUser() async {
    final token = await getToken();
    return ApiService.fetchAuthUser(token);
  }

  static Future<Map<String, dynamic>> signup({
    required String accountCustomerName,
    required String accountCustomerPhoneNumber,
    String? accountCustomerAddress,
  }) async {
    return await ApiService.signup(
      accountCustomerName: accountCustomerName,
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
      accountCustomerAddress: accountCustomerAddress,
    );
  }

  static Future<Map<String, dynamic>> login({
    required String accountCustomerPhoneNumber,
  }) async {
    return await ApiService.login(
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
          customerPhone: customer['account_customer_phone_number'] as String,
        );
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> riderLogin({
    required String email,
    required String password,
  }) async {
    final result = await ApiService.riderLogin(email: email, password: password);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>?;
      final token = data['token'] as String?;
      if (user != null && token != null && token.isNotEmpty) {
        final rawId = user['id'];
        final riderId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
        final name = user['name']?.toString() ?? user['full_name']?.toString() ?? 'Rider';
        final emailAddr = user['email_address']?.toString() ?? email;
        final phone = user['phone_number']?.toString();
        await saveRiderAuthData(
          token: token,
          riderId: riderId > 0 ? riderId : 0,
          fullName: name,
          email: emailAddr,
          phoneNumber: phone,
        );
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> registerRider({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String dateOfBirth,
    required String gender,
    required String nationalId,
    required String password,
    required String passwordConfirmation,
    required String drivingLicenseNumber,
    required String licenseExpiryDate,
    required String vehicleType,
    required String vehicleModel,
    required String vehiclePlateNumber,
    String? nationalIdPhotoUpload,
    String? selfieVerificationPhoto,
    XFile? nationalIdPhotoFile,
    XFile? selfiePhotoFile,
  }) async {
    return ApiService.registerRider(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      dateOfBirth: dateOfBirth,
      gender: gender,
      nationalId: nationalId,
      password: password,
      passwordConfirmation: passwordConfirmation,
      drivingLicenseNumber: drivingLicenseNumber,
      licenseExpiryDate: licenseExpiryDate,
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      vehiclePlateNumber: vehiclePlateNumber,
      nationalIdPhotoUpload: nationalIdPhotoUpload,
      selfieVerificationPhoto: selfieVerificationPhoto,
      nationalIdPhotoFile: nationalIdPhotoFile,
      selfiePhotoFile: selfiePhotoFile,
    );
  }

  static Future<void> logout() async {
    await clearAuthData();
  }
}
