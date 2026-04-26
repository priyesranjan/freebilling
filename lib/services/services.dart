
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

export 'sync_service.dart';
export 'reporting_service.dart';
export 'api_service.dart';
export 'pdf_service.dart';
export 'a4_pdf_service.dart';
export 'catalog_service.dart';
export 'websocket_service.dart';

abstract class OwnerAuthService {
  Future<OtpRequestResult> requestOtp({required String phoneNumber});
  Future<OwnerAuthSession> verifyOtp({
    required String phoneNumber,
    required String requestId,
    required String otp,
  });

  factory OwnerAuthService.fromEnvironment() {
    const String apiKey = String.fromEnvironment('TWO_FACTOR_API_KEY');
    if (apiKey.isEmpty) {
      return MockOwnerAuthService();
    }
    const String templateName = String.fromEnvironment('TWO_FACTOR_TEMPLATE');
    return TwoFactorOwnerAuthService(apiKey: apiKey, templateName: templateName);
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MockOwnerAuthService implements OwnerAuthService {
  final Map<String, String> _otpByRequestId = <String, String>{};

  @override
  Future<OtpRequestResult> requestOtp({required String phoneNumber}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final String requestId =
        'mock-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99)}';
    final String otp = (Random().nextInt(900000) + 100000).toString();
    _otpByRequestId[requestId] = otp;

    return OtpRequestResult(requestId: requestId, debugOtp: otp);
  }

  @override
  Future<OwnerAuthSession> verifyOtp({
    required String phoneNumber,
    required String requestId,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final String? expectedOtp = _otpByRequestId[requestId];
    if (expectedOtp == null) {
      throw const AuthException('OTP request expired. Request a new OTP.');
    }

    if (expectedOtp != otp) {
      throw const AuthException('Invalid OTP. Try again.');
    }

    return OwnerAuthSession(
      ownerId: 'owner-${phoneNumber.substring(phoneNumber.length - 4)}',
      normalizedPhone: phoneNumber,
      provider: 'mock',
      loggedInAt: DateTime.now(),
    );
  }
}

class TwoFactorOwnerAuthService implements OwnerAuthService {
  TwoFactorOwnerAuthService({
    required this.apiKey,
    required this.templateName,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String templateName;
  final http.Client _client;

  Uri _buildOtpUri(String phoneNumber) {
    if (templateName.trim().isEmpty) {
      return Uri.parse(
        'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN',
      );
    }

    return Uri.parse(
      'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN/$templateName',
    );
  }

  Uri _buildVerifyUri(String requestId, String otp) {
    return Uri.parse(
      'https://2factor.in/API/V1/$apiKey/SMS/VERIFY/$requestId/$otp',
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const AuthException('Unable to parse authentication response.');
    }

    if (response.statusCode >= 400) {
      final String error =
          json['Details']?.toString() ?? '2factor returned an error.';
      throw AuthException(error);
    }

    return json;
  }

  @override
  Future<OtpRequestResult> requestOtp({required String phoneNumber}) async {
    final http.Response response = await _client.get(_buildOtpUri(phoneNumber));
    final Map<String, dynamic> json = _decodeResponse(response);

    final String status = (json['Status'] ?? '').toString().toLowerCase();
    if (status != 'success') {
      throw AuthException(
        (json['Details'] ?? '2factor OTP request failed.').toString(),
      );
    }

    final String requestId = (json['Details'] ?? '').toString();
    if (requestId.isEmpty) {
      throw const AuthException('2factor did not return a request id.');
    }

    return OtpRequestResult(requestId: requestId);
  }

  @override
  Future<OwnerAuthSession> verifyOtp({
    required String phoneNumber,
    required String requestId,
    required String otp,
  }) async {
    final http.Response response = await _client.get(
      _buildVerifyUri(requestId, otp),
    );
    final Map<String, dynamic> json = _decodeResponse(response);

    final String status = (json['Status'] ?? '').toString().toLowerCase();
    if (status != 'success') {
      throw AuthException(
        (json['Details'] ?? 'OTP verification failed.').toString(),
      );
    }

    return OwnerAuthSession(
      ownerId: 'owner-${phoneNumber.substring(phoneNumber.length - 4)}',
      normalizedPhone: phoneNumber,
      provider: '2factor',
      loggedInAt: DateTime.now(),
    );
  }
}
