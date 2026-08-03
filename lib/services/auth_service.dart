import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';

class AuthService {
  // API Base URL
  static const String baseUrl = 'https://moneymeter.biz';

  static String _apiUrl(String prefix, String endpoint) {
    return '$baseUrl/$prefix/$endpoint';
  }

  /// Login responses may contain either a raw token or one already prefixed
  /// with `Bearer`. Always send exactly one bearer prefix.
  static String _authorizationValue(String token) {
    final trimmedToken = token.trim();
    return trimmedToken.toLowerCase().startsWith('bearer ')
        ? trimmedToken
        : 'Bearer $trimmedToken';
  }

  static void _ensureApiSuccess(dynamic decoded) {
    if (decoded is! Map) return;

    final status = decoded['status'];
    final isFailure =
        status == false ||
        status == 0 ||
        status?.toString().toLowerCase() == 'false';
    if (!isFailure) return;

    throw Exception(
      decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Request failed',
    );
  }

  static Future<dynamic> _post(
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    String? authToken,
  }) async {
    final resolvedAuthToken = authToken ?? await getAuthToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      // Use form-encoded bodies because the API expects form fields for registration/login
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    if (resolvedAuthToken != null && resolvedAuthToken.isNotEmpty) {
      headers['Authorization'] = _authorizationValue(resolvedAuthToken);
    }

    final resolvedUri = queryParameters == null || queryParameters.isEmpty
        ? uri
        : uri.replace(
            queryParameters: queryParameters.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
          );

    // Convert body values to strings for form encoding
    Map<String, String>? formBody;
    if (body != null) {
      formBody = <String, String>{};
      body.forEach((k, v) {
        if (v == null) return;
        formBody![k] = v.toString();
      });
    }

    // Debug: show the form body being sent for easier troubleshooting
    try {
      // ignore: avoid_print
      print('API REQ ${resolvedUri.toString()} -> $formBody');
    } catch (_) {}

    http.Response response;
    try {
      response = await http.post(resolvedUri, headers: headers, body: formBody);
    } catch (e) {
      throw Exception('Network error: Please check your internet connection');
    }

    final decoded = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _ensureApiSuccess(decoded);
      return decoded;
    }

    // Log raw response for easier debugging of validation errors
    try {
      // ignore: avoid_print
      print(
        'API ERROR ${uri.toString()} [${response.statusCode}]: ${response.body}',
      );
    } catch (_) {}

    if (decoded is Map<String, dynamic>) {
      String message =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Request failed';

      // Helper to recursively collect messages from nested structures
      List<String> collectMessages(dynamic obj) {
        final parts = <String>[];
        if (obj == null) return parts;
        if (obj is String) {
          parts.add(obj);
          return parts;
        }
        if (obj is Map) {
          obj.forEach((k, v) {
            if (v == null) return;
            if (v is String) {
              parts.add(v);
            } else if (v is List || v is Map) {
              parts.addAll(collectMessages(v));
            } else {
              parts.add(v.toString());
            }
          });
          return parts;
        }
        if (obj is List) {
          for (final v in obj) {
            parts.addAll(collectMessages(v));
          }
          return parts;
        }
        parts.add(obj.toString());
        return parts;
      }

      final collected = <String>[];
      if (decoded.containsKey('errors'))
        collected.addAll(collectMessages(decoded['errors']));
      if (decoded.containsKey('data'))
        collected.addAll(collectMessages(decoded['data']));
      if (decoded.containsKey('validation'))
        collected.addAll(collectMessages(decoded['validation']));

      collected.addAll(collectMessages(decoded));

      final uniq = collected
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      uniq.removeWhere((s) => s == message);
      if (uniq.isNotEmpty) {
        message = '$message: ${uniq.join(', ')}';
      }

      throw Exception(message);
    }

    throw Exception(decoded.toString());
  }

  static Future<dynamic> _get(
    Uri uri, {
    Map<String, dynamic>? queryParameters,
    String? authToken,
  }) async {
    final resolvedAuthToken = authToken ?? await getAuthToken();

    final headers = <String, String>{'Accept': 'application/json'};
    if (resolvedAuthToken != null && resolvedAuthToken.isNotEmpty) {
      headers['Authorization'] = _authorizationValue(resolvedAuthToken);
    }

    final resolvedUri = queryParameters == null || queryParameters.isEmpty
        ? uri
        : uri.replace(
            queryParameters: queryParameters.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
          );

    http.Response response;
    try {
      response = await http.get(resolvedUri, headers: headers);
    } catch (e) {
      throw Exception('Network error: Please check your internet connection');
    }

    final decoded = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _ensureApiSuccess(decoded);
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      String message =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Request failed';

      throw Exception(message);
    }

    throw Exception(
      'GET ${resolvedUri.path} failed (${response.statusCode}): '
      '${response.reasonPhrase ?? 'Unexpected server response'}',
    );
  }

  static Future<dynamic> _patch(
    Uri uri, {
    Map<String, dynamic>? body,
    String? authToken,
  }) async {
    final resolvedAuthToken = authToken ?? await getAuthToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    if (resolvedAuthToken != null && resolvedAuthToken.isNotEmpty) {
      headers['Authorization'] = _authorizationValue(resolvedAuthToken);
    }

    Map<String, String>? formBody;
    if (body != null) {
      formBody = <String, String>{};
      body.forEach((k, v) {
        if (v == null) return;
        formBody![k] = v.toString();
      });
    }

    http.Response response;
    try {
      response = await http.patch(uri, headers: headers, body: formBody);
    } catch (e) {
      throw Exception('Network error: Please check your internet connection');
    }

    final decoded = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _ensureApiSuccess(decoded);
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      String message =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Request failed';

      List<String> collectMessages(dynamic obj) {
        final parts = <String>[];
        if (obj == null) return parts;
        if (obj is String) {
          parts.add(obj);
          return parts;
        }
        if (obj is Map) {
          obj.forEach((k, v) {
            if (v == null) return;
            if (v is String) {
              parts.add(v);
            } else if (v is List || v is Map) {
              parts.addAll(collectMessages(v));
            } else {
              parts.add(v.toString());
            }
          });
          return parts;
        }
        if (obj is List) {
          for (final v in obj) {
            parts.addAll(collectMessages(v));
          }
        }
        parts.add(obj.toString());
        return parts;
      }

      final collected = <String>[];
      if (decoded.containsKey('errors'))
        collected.addAll(collectMessages(decoded['errors']));
      if (decoded.containsKey('data'))
        collected.addAll(collectMessages(decoded['data']));
      if (decoded.containsKey('validation'))
        collected.addAll(collectMessages(decoded['validation']));

      collected.addAll(collectMessages(decoded));

      final uniq = collected
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      uniq.removeWhere((s) => s == message);
      if (uniq.isNotEmpty) {
        message = '$message: ${uniq.join(', ')}';
      }

      throw Exception(message);
    }

    throw Exception(decoded.toString());
  }

  static dynamic _decodeResponse(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static Map<String, String> buildLoginBody({
    required String username,
    required String password,
  }) {
    return {'username': username, 'password': password};
  }

  static Map<String, dynamic> buildRegisterBody({
    required String fullName,
    required String dob,
    required String gender,
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
    required String address,
    required String landmark,
    required String latitude,
    required String longitude,
  }) {
    final body = <String, dynamic>{
      'fu_sName': fullName,
      'fu_dDOB': dob,
      'fu_eGender': gender,
      'fu_sMobileNo': mobile,
      'fu_sPassword': password,
      'confirmPassword': confirmPassword,
      'fm_sAddress': address,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (email.isNotEmpty) body['fu_sEmail'] = email;
    if (landmark.isNotEmpty) body['fm_sLandMark'] = landmark;
    return body;
  }

  static Map<String, String> buildHomeScreenDataBody({required int familyId}) {
    return {'fInc_familyId': familyId.toString()};
  }

  static Map<String, String> buildFamilyIncomeHistoryBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fInc_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Map<String, String> buildFamilyUnpaidIncomeBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fInc_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Map<String, String> buildFamilyPaidIncomeBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fInc_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Map<String, String> buildFamilyExpenseHistoryBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fex_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Map<String, String> buildCreateIncomeMasterBody({
    required int familyId,
    required String incomeName,
    required String incomeType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
  }) {
    final body = <String, String>{
      'fInc_familyId': familyId.toString(),
      'fInc_sIncName': incomeName,
      'fInc_eIncType': incomeType,
      'fInc_iCycleMonths': cycleMonths.toString(),
      'fInc_dStartDate': startDate,
      'fInc_iAmount': amount.toString(),
      'fInc_dNextDueDate': nextDueDate,
    };
    body['fInc_iMonthDuration'] = monthDuration ?? '';
    return body;
  }

  static Map<String, String> buildUpdateIncomeMasterBody({
    required int familyId,
    required int incomeId,
    required String incomeName,
    required String incomeType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
    required String status,
  }) {
    final body = <String, String>{
      'fInc_familyId': familyId.toString(),
      'fInc_sIncName': incomeName,
      'fInc_id': incomeId.toString(),
      'fInc_eIncType': incomeType,
      'fInc_iCycleMonths': cycleMonths.toString(),
      'fInc_dStartDate': startDate,
      'fInc_iAmount': amount.toString(),
      'fInc_dNextDueDate': nextDueDate,
      'fInc_eStatus': status,
    };
    body['fInc_iMonthDuration'] = monthDuration ?? '';
    return body;
  }

  static Map<String, String> buildGetNextDueDateBody({
    required int familyId,
    required int incomeId,
  }) {
    return {
      'fInc_familyId': familyId.toString(),
      'fInc_id': incomeId.toString(),
    };
  }

  static Map<String, String> buildGetIncomeListQueryParameters({
    required int familyId,
    int startRow = 0,
  }) {
    return {'familyId': familyId.toString(), 'startRow': startRow.toString()};
  }

  static Map<String, String> buildGetExpenseListQueryParameters({
    required int familyId,
    int startRow = 0,
  }) {
    return {'familyId': familyId.toString(), 'startRow': startRow.toString()};
  }

  static Map<String, String> buildFamilyIncomeListBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fInc_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Map<String, String> buildFamilyIncomeViewBody({
    required int familyId,
    required int startRow,
    required int incomeId,
  }) {
    return {
      'fInc_familyId': familyId.toString(),
      'startRow': startRow.toString(),
      'fInc_id': incomeId.toString(),
    };
  }

  static Map<String, String> buildFamilyExpenseListBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fex_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Map<String, String> buildFamilyExpenseViewBody({
    required int familyId,
    required int startRow,
    required int expenseId,
  }) {
    return {
      'fex_familyId': familyId.toString(),
      'startRow': startRow.toString(),
      'fex_id': expenseId.toString(),
    };
  }

  static Map<String, String> buildRecurringExpensesPaidBody({
    required int familyId,
    required int startRow,
    required String fromDate,
    required String toDate,
  }) {
    return {
      'fex_familyId': familyId.toString(),
      'startRow': startRow.toString(),
      'dFromDate': fromDate,
      'dToDate': toDate,
    };
  }

  static Map<String, String> buildCreateExpenseMasterBody({
    required int familyId,
    required String expenseName,
    required String expenseType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
  }) {
    final body = <String, String>{
      'fEx_familyId': familyId.toString(),
      'fEx_sExpName': expenseName,
      'fEx_eExpType': expenseType,
      'fEx_iCycleMonths': cycleMonths.toString(),
      'fEx_dStartDate': startDate,
      'fEx_iAmount': amount.toString(),
      'fEx_dNextDueDate': nextDueDate,
    };
    body['fEx_iMonthDuration'] = monthDuration ?? '';
    return body;
  }

  static Map<String, String> buildUpdateExpenseMasterBody({
    required int familyId,
    required int expenseId,
    required String expenseName,
    required String expenseType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
    required String status,
  }) {
    final body = <String, String>{
      'fEx_familyId': familyId.toString(),
      'fEx_id': expenseId.toString(),
      'fEx_sExpName': expenseName,
      'fEx_eExpType': expenseType,
      'fEx_iCycleMonths': cycleMonths.toString(),
      'fEx_dStartDate': startDate,
      'fEx_iAmount': amount.toString(),
      'fEx_dNextDueDate': nextDueDate,
      'fEx_eStatus': status,
    };
    body['fEx_iMonthDuration'] = monthDuration ?? '';
    return body;
  }

  static Map<String, String> buildFamilyUnpaidExpenseBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fex_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Map<String, String> buildFamilyPaidExpenseBody({
    required int familyId,
    required int startRow,
  }) {
    return {
      'fex_familyId': familyId.toString(),
      'startRow': startRow.toString(),
    };
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final decoded = await _post(
      Uri.parse(_apiUrl('api/v1', 'member-login')),
      body: {'username': username, 'password': password},
    );

    // If API returned a token, persist it for session persistence
    if (decoded is Map<String, dynamic>) {
      // look for common token locations
      String? token;
      if (decoded.containsKey('token')) token = decoded['token']?.toString();
      if (token == null && decoded.containsKey('access_token'))
        token = decoded['access_token']?.toString();
      if (token == null &&
          decoded.containsKey('data') &&
          decoded['data'] is Map) {
        final data = decoded['data'] as Map<String, dynamic>;
        token = data['token']?.toString() ?? data['access_token']?.toString();
      }
      if (token != null && token.isNotEmpty) {
        await saveAuthToken(token);
      }
      // Try to extract and save the user's name from common response shapes
      String? name;
      if (decoded.containsKey('name')) name = decoded['name']?.toString();
      if (name == null && decoded.containsKey('fu_sName'))
        name = decoded['fu_sName']?.toString();
      if (name == null && decoded.containsKey('fullName'))
        name = decoded['fullName']?.toString();
      if (name == null &&
          decoded.containsKey('data') &&
          decoded['data'] is Map) {
        final data = decoded['data'] as Map<String, dynamic>;
        name =
            data['name']?.toString() ??
            data['fu_sName']?.toString() ??
            data['fullName']?.toString();
      }
      if (name != null && name.isNotEmpty) await saveUserName(name);

      // Save the username used to login (assuming it's the mobile number)
      try {
        if (username.isNotEmpty) await saveUserMobile(username);
      } catch (_) {}
    }

    return decoded is Map<String, dynamic>
        ? decoded
        : {'message': decoded.toString()};
  }

  static Future<void> logout() async {
    final token = await getAuthToken();
    if (token != null) {
      try {
        await memberLogout(authToken: token);
      } catch (_) {}
    }
    await clearAuthToken();
    await clearUserName();
    await clearUserMobile();
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String mobile,
  }) async {
    // This is a placeholder for the actual API call
    final decoded = await _post(
      Uri.parse(_apiUrl('api/v1', 'forgot-password')),
      body: {'mobile': mobile},
    );
    return decoded is Map<String, dynamic>
        ? decoded
        : {'message': decoded.toString()};
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String mobile,
    required String password,
  }) async {
    // This is a placeholder for the actual API call
    // In a real app, this would update the backend database
    final decoded = await _post(
      Uri.parse(_apiUrl('api/v1', 'reset-password')),
      body: {'mobile': mobile, 'password': password},
    );
    return decoded is Map<String, dynamic>
        ? decoded
        : {'message': decoded.toString()};
  }

  static const String _kAuthTokenKey = 'auth_token';
  static const String _kUserNameKey = 'user_name';
  static const String _kUserMobileKey = 'user_mobile';
  static const String _kAuthMethodPrefix = 'auth_method_';

  static Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> saveAuthMethod(String mobile, String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kAuthMethodPrefix$mobile', method);
  }

  static Future<String?> getAuthMethod(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kAuthMethodPrefix$mobile');
  }

  static Future<void> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAuthTokenKey, token);
    } catch (_) {}
  }

  static Future<void> saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserNameKey, name);
    } catch (_) {}
  }

  static Future<void> saveUserMobile(String mobile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserMobileKey, mobile);
    } catch (_) {}
  }

  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kAuthTokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAuthTokenKey);
    } catch (_) {}
  }

  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kUserNameKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserNameKey);
    } catch (_) {}
  }

  static Future<String?> getUserMobile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kUserMobileKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearUserMobile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserMobileKey);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> merchantLogin({
    required String username,
    required String password,
  }) async {
    final decoded = await _post(
      Uri.parse(_apiUrl('api/v1', 'merchant-login')),
      body: {'username': username, 'password': password},
    );

    return decoded is Map<String, dynamic>
        ? decoded
        : {'message': decoded.toString()};
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String dob,
    required String gender,
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
    required String address,
    required String landmark,
    required String latitude,
    required String longitude,
  }) async {
    final decoded = await _post(
      Uri.parse(_apiUrl('api/v1', 'member-register')),
      body: buildRegisterBody(
        fullName: fullName,
        dob: dob,
        gender: gender,
        email: email,
        mobile: mobile,
        password: password,
        confirmPassword: confirmPassword,
        address: address,
        landmark: landmark,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    // If registration returns a name or token, persist them
    if (decoded is Map<String, dynamic>) {
      String? name;
      if (decoded.containsKey('fu_sName'))
        name = decoded['fu_sName']?.toString();
      if (name == null && decoded.containsKey('name'))
        name = decoded['name']?.toString();
      if (name == null &&
          decoded.containsKey('data') &&
          decoded['data'] is Map) {
        final data = decoded['data'] as Map<String, dynamic>;
        name = data['fu_sName']?.toString() ?? data['name']?.toString();
      }
      if (name != null && name.isNotEmpty) await saveUserName(name);

      String? token;
      if (decoded.containsKey('token')) token = decoded['token']?.toString();
      if (token == null && decoded.containsKey('access_token'))
        token = decoded['access_token']?.toString();
      if (token == null &&
          decoded.containsKey('data') &&
          decoded['data'] is Map) {
        final data = decoded['data'] as Map<String, dynamic>;
        token = data['token']?.toString() ?? data['access_token']?.toString();
      }
      if (token != null && token.isNotEmpty) await saveAuthToken(token);
    }

    return decoded is Map<String, dynamic>
        ? decoded
        : {'message': decoded.toString()};
  }

  static Future<dynamic> memberLogout({required String authToken}) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'member-logout')),
      authToken: authToken,
    );
  }

  static Future<dynamic> merchantLogout({required String authToken}) async {
    return _post(
      Uri.parse(_apiUrl('merchant-api/v1', 'merchant-logout')),
      authToken: authToken,
    );
  }

  static Future<dynamic> getMerchantList({required int merchantId}) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-merchantlist')),
      body: {'merchantId': merchantId.toString()},
    );
  }

  static Future<dynamic> getMemberMasterList() async {
    return _post(Uri.parse(_apiUrl('member-api/v1', 'get-membermasterlist')));
  }

  static Future<dynamic> getMerchantBusinessStaff() async {
    return _post(
      Uri.parse(_apiUrl('merchant-api/v1', 'get-merchantbusinessstaff')),
    );
  }

  static Future<dynamic> getMerchantBusinessProducts() async {
    return _post(
      Uri.parse(_apiUrl('merchant-api/v1', 'get-merchantbusinessproducts')),
    );
  }

  static Future<dynamic> getMBBillHdrList() async {
    return _post(Uri.parse(_apiUrl('merchant-api/v1', 'get-mbbillhdrlist')));
  }

  static Future<dynamic> getMBBillBdyList() async {
    return _post(Uri.parse(_apiUrl('merchant-api/v1', 'get-mbbillsbdylist')));
  }

  static Future<dynamic> getMBBillsList() async {
    return _post(Uri.parse(_apiUrl('merchant-api/v1', 'get-mbbillslist')));
  }

  static Future<dynamic> getDeliveryHdrList() async {
    return _post(Uri.parse(_apiUrl('merchant-api/v1', 'get-deliveryhdrlist')));
  }

  static Future<dynamic> getDeliveryBdyList() async {
    return _post(Uri.parse(_apiUrl('merchant-api/v1', 'get-deliverybdylist')));
  }

  static Future<dynamic> getDeliveryDetails() async {
    return _post(Uri.parse(_apiUrl('merchant-api/v1', 'get-deliverydetails')));
  }

  static Future<dynamic> getMBCollectionList() async {
    return _post(Uri.parse(_apiUrl('merchant-api/v1', 'get-mbcollectionlist')));
  }

  static Future<dynamic> getCollectionMarkingList() async {
    return _post(
      Uri.parse(_apiUrl('merchant-api/v1', 'get-collectionmarkinglist')),
    );
  }

  static Future<dynamic> getMerchantBusinessesList() async {
    return _post(
      Uri.parse(_apiUrl('merchant-api/v1', 'get-merchantbusinesseslist')),
    );
  }

  static Future<dynamic> getMerchantBusinessClientList() async {
    return _post(
      Uri.parse(_apiUrl('merchant-api/v1', 'get-merchantbusinessclientlist')),
    );
  }

  static Future<dynamic> getCommonMasterList({
    required String commonType,
    String? commonId,
  }) async {
    final body = <String, String>{'commonType': commonType};
    if (commonId != null && commonId.isNotEmpty) {
      body['commonId'] = commonId;
    }
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-commonmaster')),
      body: body,
    );
  }

  static Future<dynamic> getFamilyIncomeHistory({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyincomehistory')),
      body: buildFamilyIncomeHistoryBody(
        familyId: familyId,
        startRow: startRow,
      ),
    );
  }

  static Future<dynamic> getFamilyUnpaidIncome({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyunpaidincome')),
      body: buildFamilyUnpaidIncomeBody(familyId: familyId, startRow: startRow),
    );
  }

  static Future<dynamic> getFamilyPaidIncome({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familypaidincome')),
      body: buildFamilyPaidIncomeBody(familyId: familyId, startRow: startRow),
    );
  }

  static Future<dynamic> getFamilyExpenseHistory({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyexpensehistory')),
      body: buildFamilyExpenseHistoryBody(
        familyId: familyId,
        startRow: startRow,
      ),
    );
  }

  static Future<List<FamilyTransactionItem>> getAllIncome({
    required int familyId,
    int startRow = 0,
  }) async {
    final response = await _get(
      Uri.parse(_apiUrl('member-api/v1', 'member-income')),
      queryParameters: buildGetIncomeListQueryParameters(
        familyId: familyId,
        startRow: startRow,
      ),
    );
    return FamilyTransactionItem.fromResponse(response);
  }

  static Future<FamilyTransactionItem?> getIncomeMasterDetail({
    required int incomeId,
  }) async {
    final response = await _get(
      Uri.parse(_apiUrl('member-api/v1', 'member-income/$incomeId')),
    );

    final items = FamilyTransactionItem.fromResponse(response);
    return items.isNotEmpty ? items.first : null;
  }

  static Future<List<FamilyTransactionItem>> getAllExpense({
    required int familyId,
    int startRow = 0,
  }) async {
    final response = await _get(
      Uri.parse(_apiUrl('member-api/v1', 'member-expense')),
      queryParameters: buildGetExpenseListQueryParameters(
        familyId: familyId,
        startRow: startRow,
      ),
    );
    return FamilyTransactionItem.fromResponse(response);
  }

  static Future<FamilyTransactionItem?> getExpenseMasterDetail({
    required int expenseId,
  }) async {
    final response = await _get(
      Uri.parse(_apiUrl('member-api/v1', 'member-expense/$expenseId')),
    );

    final items = FamilyTransactionItem.fromResponse(response);
    return items.isNotEmpty ? items.first : null;
  }

  static Future<dynamic> getFamilyIncomeList({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyincomelist')),
      queryParameters: {'fInc_familyId': familyId.toString()},
      body: buildFamilyIncomeListBody(
        familyId: familyId,
        startRow: startRow,
      ),
    );
  }

  static Future<dynamic> getFamilyIncomeView({
    required int familyId,
    int startRow = 0,
    required int incomeId,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyincomeview')),
      queryParameters: {'fInc_id': incomeId.toString()},
      body: buildFamilyIncomeViewBody(
        familyId: familyId,
        startRow: startRow,
        incomeId: incomeId,
      ),
    );
  }

  static Future<dynamic> getFamilyExpenseList({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyexpenselist')),
      body: buildFamilyExpenseListBody(
        familyId: familyId,
        startRow: startRow,
      ),
    );
  }

  static Future<dynamic> getFamilyExpenseView({
    required int familyId,
    int startRow = 0,
    required int expenseId,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyexpenseview')),
      queryParameters: {'fex_id': expenseId.toString()},
      body: buildFamilyExpenseViewBody(
        familyId: familyId,
        startRow: startRow,
        expenseId: expenseId,
      ),
    );
  }

  static Future<dynamic> getRecurringExpensesPaid({
    required int familyId,
    int startRow = 0,
    required String fromDate,
    required String toDate,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-recurringrxpensespaid')),
      body: buildRecurringExpensesPaidBody(
        familyId: familyId,
        startRow: startRow,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
  }

  static Future<dynamic> createExpenseMaster({
    required int familyId,
    required String expenseName,
    required String expenseType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'member-expense')),
      body: buildCreateExpenseMasterBody(
        familyId: familyId,
        expenseName: expenseName,
        expenseType: expenseType,
        cycleMonths: cycleMonths,
        startDate: startDate,
        monthDuration: monthDuration,
        amount: amount,
        nextDueDate: nextDueDate,
      ),
    );
  }

  static Future<dynamic> updateExpenseMaster({
    required int familyId,
    required int expenseId,
    required String expenseName,
    required String expenseType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
    required String status,
  }) async {
    return _patch(
      Uri.parse(_apiUrl('member-api/v1', 'member-expense/$expenseId')),
      body: buildUpdateExpenseMasterBody(
        familyId: familyId,
        expenseId: expenseId,
        expenseName: expenseName,
        expenseType: expenseType,
        cycleMonths: cycleMonths,
        startDate: startDate,
        monthDuration: monthDuration,
        amount: amount,
        nextDueDate: nextDueDate,
        status: status,
      ),
    );
  }

  static Future<String?> getNextDueDate({
    required int familyId,
    required int incomeId,
  }) async {
    final response = await _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-next-due-date')),
      body: buildGetNextDueDateBody(familyId: familyId, incomeId: incomeId),
    );

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final data = map['data'];
      if (data is Map) {
        final nested = Map<String, dynamic>.from(data);
        return nested['nextDueDate']?.toString() ??
            nested['dueDate']?.toString() ??
            nested['fInc_dNextDueDate']?.toString() ??
            nested['date']?.toString();
      }

      return map['nextDueDate']?.toString() ??
          map['dueDate']?.toString() ??
          map['fInc_dNextDueDate']?.toString() ??
          map['date']?.toString();
    }

    return null;
  }

  static Future<dynamic> createIncomeMaster({
    required int familyId,
    required String incomeName,
    required String incomeType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'member-income')),
      body: buildCreateIncomeMasterBody(
        familyId: familyId,
        incomeName: incomeName,
        incomeType: incomeType,
        cycleMonths: cycleMonths,
        startDate: startDate,
        monthDuration: monthDuration,
        amount: amount,
        nextDueDate: nextDueDate,
      ),
    );
  }

  static Future<dynamic> updateIncomeMaster({
    required int familyId,
    required int incomeId,
    required String incomeName,
    required String incomeType,
    required int cycleMonths,
    required String startDate,
    String? monthDuration,
    required int amount,
    required String nextDueDate,
    required String status,
  }) async {
    return _patch(
      Uri.parse(_apiUrl('member-api/v1', 'member-income/$incomeId')),
      body: buildUpdateIncomeMasterBody(
        familyId: familyId,
        incomeId: incomeId,
        incomeName: incomeName,
        incomeType: incomeType,
        cycleMonths: cycleMonths,
        startDate: startDate,
        monthDuration: monthDuration,
        amount: amount,
        nextDueDate: nextDueDate,
        status: status,
      ),
    );
  }

  static Future<dynamic> getFamilyUnpaidExpense({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyunpaidexpense')),
      body: buildFamilyUnpaidExpenseBody(
        familyId: familyId,
        startRow: startRow,
      ),
    );
  }

  static Future<dynamic> getFamilyPaidExpense({
    required int familyId,
    int startRow = 0,
  }) async {
    return _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familypaidexpense')),
      body: buildFamilyPaidExpenseBody(familyId: familyId, startRow: startRow),
    );
  }

  static Future<List<FamilyTransactionItem>> getIncomeTransactions({
    required int familyId,
  }) async {
    final paid = await getFamilyPaidIncome(familyId: familyId);
    final unpaid = await getFamilyUnpaidIncome(familyId: familyId);
    final combined = <FamilyTransactionItem>[]
      ..addAll(FamilyTransactionItem.fromResponse(paid))
      ..addAll(FamilyTransactionItem.fromResponse(unpaid));

    if (combined.isNotEmpty) {
      return combined;
    }

    final history = await getFamilyIncomeHistory(familyId: familyId);
    return FamilyTransactionItem.fromResponse(history);
  }

  static Future<List<FamilyTransactionItem>> getExpenseTransactions({
    required int familyId,
  }) async {
    final paid = await getFamilyPaidExpense(familyId: familyId);
    final unpaid = await getFamilyUnpaidExpense(familyId: familyId);
    final combined = <FamilyTransactionItem>[]
      ..addAll(FamilyTransactionItem.fromResponse(paid))
      ..addAll(FamilyTransactionItem.fromResponse(unpaid));

    if (combined.isNotEmpty) {
      return combined;
    }

    final history = await getFamilyExpenseHistory(familyId: familyId);
    return FamilyTransactionItem.fromResponse(history);
  }

  static Future<List<FamilyTransactionItem>> getUnbilledTransactions({
    required int familyId,
  }) async {
    final income = await getFamilyUnpaidIncome(familyId: familyId);
    final expense = await getFamilyUnpaidExpense(familyId: familyId);
    final combined = <FamilyTransactionItem>[]
      ..addAll(FamilyTransactionItem.fromResponse(income))
      ..addAll(FamilyTransactionItem.fromResponse(expense));

    return combined;
  }

  static Future<HomeScreenSummary> getHomeScreenData({
    required int familyId,
  }) async {
    final response = await _post(
      Uri.parse(_apiUrl('member-api/v1', 'get-familyhomescreendata')),
      body: buildHomeScreenDataBody(familyId: familyId),
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return HomeScreenSummary.fromJson(data);
      }
      if (data is Map) {
        return HomeScreenSummary.fromJson(Map<String, dynamic>.from(data));
      }
    }

    if (response is Map) {
      return HomeScreenSummary.fromJson(Map<String, dynamic>.from(response));
    }

    return HomeScreenSummary(
      mtdExpense: '₹0',
      mtdIncome: '₹0',
      projectedExpenses: '₹0',
      projectedIncome: '₹0',
    );
  }
}
