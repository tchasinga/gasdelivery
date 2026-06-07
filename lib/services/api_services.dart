import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
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



  // static String get baseUrl {
  //   if (kIsWeb) {
  //     return 'http://127.0.0.1:8000/api';
  //   }
  //   return 'http://${Platform.isAndroid ? '10.0.2.2' : '127.0.0.1'}:8000/api';
  // }

  static String get baseUrl {
    if (kIsWeb) {
      return 'https://cylindtrack.veritech.co.ke/api';
    }
    return 'https://cylindtrack.veritech.co.ke/api';
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

  static Future<Map<String, dynamic>> getCustomerReturnableCylinders(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer-account/returns/cylinders'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final rawList = data['cylinders'];
        return {
          'success': true,
          'cylinders': rawList is List
              ? rawList
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[],
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerReturnRiders({
    required String token,
    String? query,
  }) async {
    try {
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) {
        params['q'] = query;
      }
      final uri = Uri.parse('$baseUrl/customer-account/returns/riders')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri, headers: _authHeaders(token));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final rawList = data['riders'];
        return {
          'success': true,
          'riders': rawList is List
              ? rawList
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[],
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> customerInitiateReturn({
    required String token,
    required int riderId,
    required List<int> cylinderIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer-account/returns/initiate'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'rider_id': riderId,
          'cylinder_ids': cylinderIds,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'order_confirmation_id': data['order_confirmation_id'],
          'rider': data['rider'],
        };
      }
      return {'success': false, 'message': _firstApiErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> customerConfirmReturn({
    required String token,
    required int orderConfirmationId,
    required String otpCode,
    required int riderId,
    required List<int> cylinderIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer-account/returns/confirm'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'order_confirmation_id': orderConfirmationId,
          'otp_code': otpCode,
          'rider_id': riderId,
          'cylinder_ids': cylinderIds,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'returns': data['returns'],
        };
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
