import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../enums/enums.dart';
import 'sync_service.dart';
import 'websocket_service.dart';

class ApiService {
  // ── Backend API URL ──────────────────────────────────────────────
  // All backend routes are prefixed with /api (e.g. /api/auth/send-otp)
  static const String baseUrl = 'https://meradukan.in/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    
    // Reset singleton instances to prevent session pollution
    WebSocketService.instance.disconnect();
    AppSettings.instance.reset(); 
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to send OTP: ${response.body}');
  }

  static Future<String> sendVoiceOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp-call'),
      headers: _headers(null),
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['sessionId'];
    }
    throw Exception('Failed to send Voice OTP: ${response.body}');
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phone, String otp, String sessionId, {
    String? name, String? businessType, String? category, String? logoUrl
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'sessionId': sessionId,
        'name': name,
        'businessType': businessType,
        'category': category,
        'logoUrl': logoUrl,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    throw Exception('Verification failed');
  }

  static Future<Map<String, dynamic>> googleLogin(String email, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'name': name}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    throw Exception('Failed to login with Google: ${response.body}');
  }

  static Future<Map<String, dynamic>> loginWithPassword(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers(null),
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    final error = jsonDecode(response.body)['error'] ?? 'Login failed';
    throw Exception(error);
  }

  static Future<Map<String, dynamic>> registerWithPassword(String phone, String password, {String? name, String? businessType, String? category}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers(null),
      body: jsonEncode({
        'phone': phone, 
        'password': password,
        'name': name,
        'businessType': businessType,
        'category': category
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
    throw Exception(error);
  }

  static Future<String?> uploadLogo(Uint8List bytes, String filename) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-logo'));
    request.files.add(http.MultipartFile.fromBytes('logo', bytes, filename: filename));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    }
    throw Exception('Failed to upload logo: ${response.body}');
  }

  // --- Profile ---
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/profile'), headers: _headers(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch profile: ${response.body}');
  }

  // --- Products ---

  static Future<List<Product>> getProducts() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/products'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        final rawCodes = json['codes'];
        List<String> parsedCodes = [];
        if (rawCodes != null) {
          final codesList = rawCodes is String ? jsonDecode(rawCodes) : rawCodes;
          if (codesList is List) {
            parsedCodes = List<String>.from(codesList);
          }
        }
        return Product(
          id: json['id'],
          name: json['name'],
          mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0.0,
          sellingPrice: double.tryParse(json['selling_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
          codes: parsedCodes,
          taxRate: TaxRate.values.firstWhere((e) => e.name == json['tax_rate'], orElse: () => TaxRate.exempt),
          lowStockAlertLevel: double.tryParse(json['low_stock_level']?.toString() ?? '0') ?? 0.0,
          initialStock: double.tryParse(json['current_stock']?.toString() ?? '0') ?? 0.0,
        );
      }).toList();
    }
    throw Exception('Failed to fetch products');
  }

  static Future<Product> saveProduct(Product p) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _headers(token),
      body: jsonEncode({
        'id': p.id,
        'name': p.name,
        'mrp': p.mrp,
        'selling_price': p.sellingPrice,
        'price': p.sellingPrice,
        'codes': p.codes,
        'tax_rate': p.taxRate.name,
        'current_stock': p.currentStock,
        'low_stock_level': p.lowStockAlertLevel,
      }),
    );
    if (response.statusCode == 200) {
      return p.copyWith(syncState: EntityState.synced);
    }
    throw Exception('Failed to save product: ${response.body}');
  }

  static Future<void> deleteProduct(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

  // --- Khata (Parties) ---

  static Future<List<PartyRecord>> getParties() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/khata'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        return PartyRecord(
          id: json['id'],
          name: json['name'],
          phone: json['phone'] ?? '',
          type: PartyType.values.firstWhere((e) => e.name == json['type'], orElse: () => PartyType.customer),
          balance: double.tryParse(json['balance'].toString()) ?? 0.0,
        );
      }).toList();
    }
    throw Exception('Failed to fetch khata');
  }

  static Future<PartyRecord> saveParty(PartyRecord p) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/khata'),
      headers: _headers(token),
      body: jsonEncode({
        'id': p.id,
        'name': p.name,
        'phone': p.phone,
        'type': p.type.name,
        'balance': p.balance,
      }),
    );
    if (response.statusCode == 200) {
      return p;
    }
    throw Exception('Failed to save party');
  }

  // --- Invoices ---

  static Future<List<InvoiceRecord>> getInvoices() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/invoices'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        // Parse lines from the JSONB column stored in the backend
        final rawLines = json['lines'];
        List<CartItem> parsedLines = [];
        if (rawLines != null) {
          final linesList = rawLines is String ? jsonDecode(rawLines) : rawLines;
          if (linesList is List) {
            parsedLines = linesList.map<CartItem>((l) {
              final unitPrice = double.tryParse(l['unitPrice']?.toString() ?? '0') ?? 0.0;
              final qty = int.tryParse(l['quantity']?.toString() ?? '1') ?? 1;
              // Reconstruct a stub Product from the stored name and price
              final product = Product(
                id: l['product_id'] ?? 'item_${l['name']}',
                name: l['name'] ?? 'Item',
                sellingPrice: unitPrice,
                codes: [],
              );
              return CartItem(product: product, quantity: qty);
            }).toList();
          }
        }

        return InvoiceRecord(
          id: json['id'],
          customerName: json['customer_name'] ?? '',
          customerPhone: json['customer_phone'] ?? '',
          customerEmail: json['customer_email'] ?? '',
          total: double.tryParse(json['total'].toString()) ?? 0.0,
          paymentMode: PaymentMode.values.firstWhere(
            (e) => e.name == json['payment_mode'],
            orElse: () => PaymentMode.cash,
          ),
          type: () {
            final t = (json['invoice_type'] ?? json['type'] ?? '').toString().toLowerCase();
            if (t.contains('online') || t.contains('order') || t.contains('booking')) return DocumentType.onlineOrder;
            if (t == 'quotation') return DocumentType.quotation;
            return DocumentType.invoice;
          }(),
          createdAt: DateTime.parse(json['created_at']),
          lines: parsedLines,
          channels: {},
          publicLink: '',
          discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
        );
      }).toList();
    }
    throw Exception('Failed to fetch invoices');
  }

  static Future<InvoiceRecord> saveInvoice(InvoiceRecord i) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/invoices'),
      headers: _headers(token),
      body: jsonEncode({
        'id': i.id,
        'customer_name': i.customerName,
        'customer_phone': i.customerPhone,
        'total': i.total,
        'payment_mode': i.paymentMode.name,
        'invoice_type': i.type.name,
        'lines': i.lines.map((l) => {
          'name': l.product.name,
          'quantity': l.quantity,
          'unitPrice': l.unitPrice,
          'finalAmount': l.finalAmount,
        }).toList(),
      }),
    );
    if (response.statusCode == 200) {
      return i;
    }
    throw Exception('Failed to save invoice');
  }

  static Future<void> updateOnboarding({
    required String name,
    required String businessType,
    required String websiteSlug,
    String? gmbLocationId,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/businesses/onboard'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'businessType': businessType,
        'websiteSlug': websiteSlug,
        'gmbLocationId': gmbLocationId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update onboarding info');
    }
  }

  static Future<void> updateBusinessProfile(AppSettings settings) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/businesses/profile'),
      headers: _headers(token),
      body: jsonEncode({
        'name': settings.businessName,
        'address': settings.businessAddress,
        'email': settings.businessEmail,
        'gstin': settings.gstin,
        'category': settings.businessCategory,
        'businessType': settings.businessType,
        'state': settings.state,
        'district': settings.district,
        'city': settings.city,
        'pincode': settings.pincode,
        'invoiceFormat': settings.invoiceFormat,
        'invoiceTheme': settings.invoiceTheme,
        'certifications': settings.certifications,
        'onlineStoreTheme': settings.onlineStoreTheme,
        'logoUrl': settings.businessLogo,
        'signatureUrl': settings.businessSignature,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update business profile: ${response.body}');
    }
  }

  static Future<void> updateWebsiteConfig({
    required String themeColor,
    required String announcementText,
    required String ctaButtonText,
    required String instagram,
    required String facebook,
    required String youtube,
    required String googleMaps,
  }) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/businesses/website-config'),
      headers: _headers(token),
      body: jsonEncode({
        'themeColor': themeColor,
        'announcementText': announcementText,
        'ctaButtonText': ctaButtonText,
        'instagram': instagram,
        'facebook': facebook,
        'youtube': youtube,
        'googleMaps': googleMaps,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update website config: ${response.body}');
    }
  }
}
