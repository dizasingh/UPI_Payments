import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // Flask backend
  //static const String baseUrl = 'http://127.0.0.1:5000';
  static const String baseUrl = 'http://192.168.1.9:5000';

  // ---------------- LOGIN ----------------

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    return _handleResponse(response);
  }

  // ---------------- REGISTER ----------------

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int bankId,
    required int pspId,
    required String upiId,
    required String upiPin,
    double initialBalance = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'password': password,
        'bank_id': bankId,
        'psp_id': pspId,
        'upi_id': upiId,
        'upi_pin': upiPin,
        'initial_balance': initialBalance,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- BANKS ----------------

  static Future<List<dynamic>> getBanks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/banks'));

    final data = _handleResponse(response);

    return data['banks'] ?? [];
  }

  // ---------------- PSPS ----------------

  static Future<List<dynamic>> getPsps() async {
    final response = await http.get(Uri.parse('$baseUrl/api/psps'));

    final data = _handleResponse(response);

    return data['psps'] ?? [];
  }

  // ---------------- USER PROFILE ----------------

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/user/$userId'));

    return _handleResponse(response);
  }

  // ---------------- RESOLVE PAYEE ----------------

  static Future<Map<String, dynamic>> resolvePayee(String identifier) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/resolve-payee'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );

    return _handleResponse(response);
  }

  // ---------------- MAKE PAYMENT ----------------

  static Future<Map<String, dynamic>> makePayment({
    required String sender,
    required String receiver,
    required double amount,
    required String pin,
    required String paymentMethod,
    String remarks = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender': sender,
        'receiver': receiver,
        'amount': amount,
        'pin': pin,
        'payment_method': paymentMethod,
        'remarks': remarks,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- TRANSACTIONS ----------------

  static Future<List<dynamic>> getTransactions(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/transactions/$userId'),
    );

    final data = _handleResponse(response);

    return data['transactions'] ?? [];
  }

  // ---------------- BENEFICIARIES ----------------

  static Future<List<dynamic>> getBeneficiaries(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/beneficiaries/$userId'),
    );

    final data = _handleResponse(response);

    return data['beneficiaries'] ?? [];
  }

  static Future<Map<String, dynamic>> addBeneficiary({
    required int userId,
    required String beneficiaryUpiId,
    String nickname = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/beneficiaries'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'beneficiary_upi_id': beneficiaryUpiId,
        'nickname': nickname,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- RESPONSE HANDLER ----------------

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? data['error'] ?? 'Something went wrong');
  }
}
