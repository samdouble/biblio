import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SendOtpResult {
  SendOtpResult({required this.sent, this.error});
  final bool sent;
  final String? error;
}

class VerifyOtpResult {
  VerifyOtpResult({this.userId, this.email, this.error});
  final String? userId;
  final String? email;
  final String? error;
}

Future<SendOtpResult> sendOtp(String email) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) {
    return SendOtpResult(sent: false, error: 'API not configured');
  }

  final url = Uri.parse('$baseUrl/auth/sendOtp');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode != 200) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
      return SendOtpResult(sent: false, error: err?.toString() ?? 'Failed to send code');
    } catch (_) {
      return SendOtpResult(sent: false, error: 'Failed to send code');
    }
  }

  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final sent = body?['body'] is Map ? (body!['body'] as Map)['sent'] == true : false;
    final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
    return SendOtpResult(sent: sent, error: err?.toString());
  } catch (_) {
    return SendOtpResult(sent: false, error: 'Invalid response');
  }
}

Future<VerifyOtpResult> verifyOtp(String email, String otp) async {
  final baseUrl = dotenv.env['BIBLIO_API_URL'] ?? '';
  if (baseUrl.isEmpty) {
    return VerifyOtpResult(error: 'API not configured');
  }

  final url = Uri.parse('$baseUrl/auth/verifyOtp');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'email': email, 'otp': otp}),
  );

  if (response.statusCode != 200) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final err = body?['body'] is Map ? (body!['body'] as Map)['error'] : null;
      return VerifyOtpResult(error: err?.toString() ?? 'Invalid code');
    } catch (_) {
      return VerifyOtpResult(error: 'Invalid code');
    }
  }

  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final b = body?['body'];
    if (b is Map) {
      return VerifyOtpResult(
        userId: b['userId'] as String?,
        email: b['email'] as String?,
        error: b['error'] as String?,
      );
    }
    return VerifyOtpResult(error: 'Invalid response');
  } catch (_) {
    return VerifyOtpResult(error: 'Invalid response');
  }
}
