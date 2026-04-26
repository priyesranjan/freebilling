import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class RazorpayService {
  static Future<String> generatePaymentLink(InvoiceRecord invoice) async {
    final keyId = AppSettings.instance.razorpayKeyId;
    final keySecret = AppSettings.instance.razorpayKeySecret;

    if (keyId.isEmpty || keySecret.isEmpty) {
      throw Exception('Razorpay API keys are not configured in Integration Settings.');
    }

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';
    final url = Uri.parse('https://api.razorpay.com/v1/payment_links');

    final body = {
      "amount": (invoice.total * 100).toInt(), // Amount in paise
      "currency": "INR",
      "accept_partial": false,
      "reference_id": invoice.id,
      "description": "Payment for Invoice #${invoice.id.substring(0, 8)}",
      "customer": {
        "name": invoice.customerName.isEmpty ? 'Walk-in Customer' : invoice.customerName,
        "contact": invoice.customerPhone.isNotEmpty ? '+91${invoice.customerPhone}' : '',
        "email": invoice.customerEmail ?? ''
      },
      "notify": {
        "sms": invoice.customerPhone.isNotEmpty,
        "email": invoice.customerEmail != null && invoice.customerEmail!.isNotEmpty
      },
      "reminder_enable": true,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['short_url'];
    } else {
      throw Exception('Failed to generate payment link: ${response.body}');
    }
  }
}
