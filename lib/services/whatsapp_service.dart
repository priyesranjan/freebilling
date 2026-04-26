import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class WhatsAppService {
  static Future<void> sendInvoicePdf(String phone, Uint8List pdfBytes, String invoiceId) async {
    final token = AppSettings.instance.whatsappApiToken;
    final phoneId = AppSettings.instance.whatsappPhoneNumberId;

    if (token.isEmpty || phoneId.isEmpty) {
      throw Exception('WhatsApp API token or Phone ID is missing in Integration Settings.');
    }

    // Format phone number to international format without +
    // Assuming Indian numbers if length is 10
    String formattedPhone = phone;
    if (formattedPhone.length == 10) {
      formattedPhone = '91$formattedPhone';
    }
    
    // Step 1: Upload the PDF as Media to get the Media ID
    final mediaId = await _uploadMedia(token, phoneId, pdfBytes, invoiceId);

    // Step 2: Send the Document Message
    await _sendDocumentMessage(token, phoneId, formattedPhone, mediaId, invoiceId);
  }

  static Future<String> _uploadMedia(String token, String phoneId, Uint8List bytes, String invoiceId) async {
    final url = Uri.parse('https://graph.facebook.com/v18.0/$phoneId/media');
    
    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['messaging_product'] = 'whatsapp'
      ..files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: 'Invoice_$invoiceId.pdf',
        contentType: http.Client().post.runtimeType == Object ? null : null, // Handle depending on mime type package
      ));

    final response = await request.send();
    final responseStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseStr);
      return data['id'];
    } else {
      throw Exception('Failed to upload PDF to WhatsApp: $responseStr');
    }
  }

  static Future<void> _sendDocumentMessage(String token, String phoneId, String phone, String mediaId, String invoiceId) async {
    final url = Uri.parse('https://graph.facebook.com/v18.0/$phoneId/messages');
    
    final body = {
      "messaging_product": "whatsapp",
      "recipient_type": "individual",
      "to": phone,
      "type": "document",
      "document": {
        "id": mediaId,
        "caption": "Here is your invoice #$invoiceId. Thank you for your business!",
        "filename": "Invoice_$invoiceId.pdf"
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send WhatsApp message: ${response.body}');
    }
  }
}
