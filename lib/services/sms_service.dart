import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class SmsService {
  static Future<void> sendInvoiceAlert(String phone, String invoiceId, double amount) async {
    if (phone.isEmpty) return;

    final apiKey = AppSettings.instance.twoFactorApiKey;
    if (apiKey.isEmpty) throw Exception('2Factor API Key is missing.');

    final message = 'Thank you for your purchase! Invoice #$invoiceId for Rs. ${amount.toStringAsFixed(2)} is confirmed.';
    await _sendSms(apiKey, phone, message);
  }

  static Future<void> sendMarketingBlast(List<String> phones, String message) async {
    final apiKey = AppSettings.instance.twoFactorApiKey;
    if (apiKey.isEmpty) throw Exception('2Factor API Key is missing.');

    final phoneList = phones.join(',');
    await _sendSms(apiKey, phoneList, message);
  }

  static Future<void> _sendSms(String apiKey, String phone, String message) async {
    // 2Factor Transactional SMS API endpoint (Template-based or open depending on DLT registration)
    // Using the open ADDON_SERVICES endpoint for demo. In production, this requires DLT template ID.
    final url = Uri.parse('https://2factor.in/API/V1/$apiKey/ADDON_SERVICES/SEND/PSMS');
    
    final body = {
      "From": "ERPBIL",
      "To": phone,
      "Msg": message,
    };

    final response = await http.post(
      url,
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send SMS: ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    if (data['Status'] != 'Success') {
      throw Exception('2Factor API Error: ${data['Details']}');
    }
  }
}
