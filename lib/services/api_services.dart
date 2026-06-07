import 'dart:io' show Platform;
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ApiService {
  /// Laravel only returns JSON (including validation errors) when the request
  /// is treated as an API call. Without this, errors become 302 + HTML and
  /// [jsonDecode] throws FormatException.
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String _firstApiErrorMessage(dynamic data) {
    if (data is! Map) {
      return 'Request failed';
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages = <String>[];
      for (final value in errors.values) {
        if (value is List) {
          for (final item in value) {
            final text = item?.toString().trim() ?? '';
            if (text.isNotEmpty) {
              messages.add(text);
            }
          }
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }
    return 'Request failed';
  }

  static Future<http.MultipartFile> _multipartFromXFile(
    String fieldName,
    XFile file,
  ) async {
    // Always send bytes (not fromPath): Android gallery/camera often uses
    // content:// URIs that PHP never receives as valid uploads.
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Selected photo is empty. Please pick the image again.');
    }

    var name = file.name.trim();
    if (name.isEmpty || !name.contains('.')) {
      name = '$fieldName.jpg';
    }

    final ext = name.split('.').last.toLowerCase();
    final MediaType contentType;
    switch (ext) {
      case 'png':
        contentType = MediaType('image', 'png');
        break;
      case 'webp':
        contentType = MediaType('image', 'webp');
        break;
      case 'heic':
      case 'heif':
        contentType = MediaType('image', 'heic');
        break;
      default:
        contentType = MediaType('image', 'jpeg');
        if (ext != 'jpg' && ext != 'jpeg') {
          name = '$fieldName.jpg';
        }
    }

    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: name,
      contentType: contentType,
    );
  }

  static void _riderMultipartTextFields({
    required Map<String, String> fields,
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
  }) {
    fields.addAll({
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email_address': emailAddress,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'national_id': nationalId,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'driving_license_number': drivingLicenseNumber,
      'license_expiry_date': licenseExpiryDate,
      'vehicle_type': vehicleType,
      'vehicle_model': vehicleModel,
      'vehicle_plate_number': vehiclePlateNumber,
    });
    if (nationalIdPhotoUpload != null && nationalIdPhotoUpload.isNotEmpty) {
      fields['national_id_photo_upload'] = nationalIdPhotoUpload;
    }
    if (selfieVerificationPhoto != null && selfieVerificationPhoto.isNotEmpty) {
      fields['selfie_verification_photo'] = selfieVerificationPhoto;
    }
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://${Platform.isAndroid ? '10.0.2.2' : '127.0.0.1'}:8000/api';
  }

  // static String get baseUrl {
  //   if (kIsWeb) {
  //     return 'https://cylindtrack.veritech.co.ke/api';
  //   }
  //   return 'https://cylindtrack.veritech.co.ke/api';
  // }

  /// Sanctum-protected rider verification image (`national_id` or `selfie`).
  static String riderVerificationPhotoUrl(String kind) {
    return '$baseUrl/rider/verification-photo/$kind';
  }

  static Future<Map<String, dynamic>> signup({
    required String accountCustomerName,
    required String accountCustomerPhoneNumber,
    String? accountCustomerAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer-account/signup'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'account_customer_name': accountCustomerName,
          'account_customer_phone_number': accountCustomerPhoneNumber,
          'account_customer_address': accountCustomerAddress ?? '',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String accountCustomerPhoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer-account/login'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'account_customer_phone_number': accountCustomerPhoneNumber,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        // Extract error message from Laravel validation response
        String errorMessage = 'Login failed';
        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError[0];
            }
          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Network error: Please check your internet connection and try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String accountCustomerPhoneNumber,
    required String accountOptCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer-account/verify-otp'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'account_customer_phone_number': accountCustomerPhoneNumber,
          'account_opt_code': accountOptCode,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        // Extract error message from Laravel validation response
        String errorMessage = 'OTP verification failed';
        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError[0];
            }
          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Network error: Please check your internet connection and try again.',
      };
    }
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
    final hasImageFiles =
        nationalIdPhotoFile != null || selfiePhotoFile != null;
    try {
      late final http.Response response;
      if (hasImageFiles) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/auth/register-rider'),
        );
        request.headers['Accept'] = 'application/json';
        _riderMultipartTextFields(
          fields: request.fields,
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
          nationalIdPhotoUpload:
              nationalIdPhotoFile == null ? nationalIdPhotoUpload : null,
          selfieVerificationPhoto:
              selfiePhotoFile == null ? selfieVerificationPhoto : null,
        );
        if (nationalIdPhotoFile != null) {
          request.files.add(
            await _multipartFromXFile('national_id_photo', nationalIdPhotoFile),
          );
        }
        if (selfiePhotoFile != null) {
          request.files.add(
            await _multipartFromXFile('selfie_photo', selfiePhotoFile),
          );
        }
        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/auth/register-rider'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'full_name': fullName,
            'phone_number': phoneNumber,
            'email_address': emailAddress,
            'date_of_birth': dateOfBirth,
            'gender': gender,
            'national_id': nationalId,
            'password': password,
            'password_confirmation': passwordConfirmation,
            'driving_license_number': drivingLicenseNumber,
            'license_expiry_date': licenseExpiryDate,
            'national_id_photo_upload': nationalIdPhotoUpload,
            'selfie_verification_photo': selfieVerificationPhoto,
            'vehicle_type': vehicleType,
            'vehicle_model': vehicleModel,
            'vehicle_plate_number': vehiclePlateNumber,
          }),
        );
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registered',
          'data': data,
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> riderLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'user_type': 'rider',
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {
        'success': false,
        'message':
            'Network error: Please check your internet connection and try again.',
      };
    }
  }

  /// Current Sanctum user (`GET /user`). Pass a valid Bearer token.
  static Future<Map<String, dynamic>> fetchAuthUser(String? bearerToken) async {
    if (bearerToken == null || bearerToken.isEmpty) {
      return {'success': false, 'message': 'Not signed in'};
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $bearerToken'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message':
            data is Map
                ? _firstApiErrorMessage(data)
                : 'Could not load profile',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Map<String, String> _authHeaders(String? token) => {
        ..._jsonHeaders,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> getMiniWarehouses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer-delivery/mini-warehouses'),
        headers: _jsonHeaders,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'mini_warehouses': data['mini_warehouses'] ?? []};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> placeCustomerDeliveryOrder({
    required String token,
    required int miniWarehouseId,
    int? quantityRequested,
    String? cylinderSize,
    bool isOutright = false,
    List<Map<String, dynamic>>? lineItems,
    String? notes,
    int? customerAccountAddressHolderId,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    try {
      final body = <String, dynamic>{
        'mini_warehouse_id': miniWarehouseId,
        if (lineItems != null && lineItems.isNotEmpty)
          'line_items': lineItems
        else ...{
          'quantity_requested': quantityRequested,
          'cylinder_size': cylinderSize,
          'is_outright': isOutright,
        },
        if (notes != null) 'notes': notes,
        if (customerAccountAddressHolderId != null)
          'customer_account_address_holder_id': customerAccountAddressHolderId,
        if (deliveryAddress != null && deliveryAddress.isNotEmpty)
          'delivery_address': deliveryAddress,
        if (deliveryLat != null) 'delivery_lat': deliveryLat,
        if (deliveryLng != null) 'delivery_lng': deliveryLng,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/customer-delivery/orders'),
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'order': data['order'], 'message': data['message']};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerCylinderCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer-account/cylinder-count'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final count = data['cylinder_count'];
        final rawList = data['cylinders'];
        final cylinders = rawList is List
            ? rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        return {
          'success': true,
          'cylinder_count': count is int ? count : int.tryParse(count.toString()) ?? cylinders.length,
          'cylinders': cylinders,
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerDeliveryOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer-delivery/orders'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'orders': data['orders'] ?? []};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getRiderDeliveryOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rider/delivery-orders'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'orders': data['orders'] ?? []};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getRiderDeliveryOrder(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rider/delivery-orders/$id'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'order': data['order']};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> riderDeliverNow(
    String token,
    int orderId, {
    String? customerNumberAlternative,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (customerNumberAlternative != null &&
          customerNumberAlternative.trim().isNotEmpty) {
        body['customer_number_alternative'] = customerNumberAlternative.trim();
      }
      final response = await http.post(
        Uri.parse('$baseUrl/rider/delivery-orders/$orderId/deliver-now'),
        headers: _authHeaders(token),
        body: body.isEmpty ? null : jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> riderVerifyDeliveryOtp({
    required String token,
    required int orderId,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rider/delivery-orders/$orderId/verify-otp'),
        headers: _authHeaders(token),
        body: jsonEncode({'otp': otp}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> riderUpdateLocation({
    required String token,
    required int orderId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rider/delivery-orders/$orderId/location'),
        headers: _authHeaders(token),
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'order': data['order']};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerProducts({
    required String token,
    required String category,
    String? groupType,
  }) async {
    try {
      final params = <String, String>{'category': category};
      if (groupType != null && groupType.isNotEmpty) {
        params['product_group_type'] = groupType;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/customer-products').replace(queryParameters: params),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'products': (data['products'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer-addresses'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'addresses': (data['addresses'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createCustomerAddress({
    required String token,
    required String name,
    String? details,
    double? lat,
    double? lng,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer-addresses'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'account_customer_address_name': name,
          'account_customer_address_details': details,
          'is_default': isDefault,
          if (lat != null && lng != null)
            'account_customer_longitude_latitude': {'lat': lat, 'lng': lng},
        }),
      );
      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return {'success': true, 'address': data['address']};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> setDefaultAddress({
    required String token,
    required int addressId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/customer-addresses/$addressId/default'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'address': data['address']};
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNearbyMiniWarehouses({
    required String token,
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer-addresses/nearby-mini-warehouses')
            .replace(queryParameters: {
          'lat': '$lat',
          'lng': '$lng',
          'radius_km': '$radiusKm',
        }),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'mini_warehouses': (data['mini_warehouses'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
