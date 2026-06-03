import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isInitializing = true;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _customerData;
  String _authRole = AppAuthRole.customerAccounts;
  String? _riderDisplayName;

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get customerData => _customerData;
  String get authRole => _authRole;
  bool get isRiderSession => _authRole == AppAuthRole.riders;
  String? get riderDisplayName => _riderDisplayName;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isInitializing = true;
    notifyListeners();
    final snap = await AuthService.readSessionSnapshot();
    _isAuthenticated = snap.hasToken;
    _authRole = snap.role;
    if (_isAuthenticated && _authRole == AppAuthRole.customerAccounts) {
      _customerData = await AuthService.getCustomerData();
      _riderDisplayName = null;
    } else if (_isAuthenticated && _authRole == AppAuthRole.riders) {
      _customerData = null;
      _riderDisplayName = await AuthService.getRiderDisplayName();
    } else {
      _customerData = null;
      _riderDisplayName = null;
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> signup({
    required String accountCustomerName,
    required String accountCustomerPhoneNumber,
    String? accountCustomerAddress,
  }) async {
    final result = await AuthService.signup(
      accountCustomerName: accountCustomerName,
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
      accountCustomerAddress: accountCustomerAddress,
    );
    return result;
  }

  Future<Map<String, dynamic>> login({
    required String accountCustomerPhoneNumber,
  }) async {
    final result = await AuthService.login(
      accountCustomerPhoneNumber: accountCustomerPhoneNumber,
    );
    return result;
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

  Future<Map<String, dynamic>> loginRider({
    required String email,
    required String password,
  }) async {
    final result = await AuthService.riderLogin(email: email, password: password);
    if (result['success'] == true) {
      await checkAuthStatus();
    }
    return result;
  }

  Future<Map<String, dynamic>> registerRider({
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
    return AuthService.registerRider(
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

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _customerData = null;
    _authRole = AppAuthRole.customerAccounts;
    _riderDisplayName = null;
    notifyListeners();
  }
}
