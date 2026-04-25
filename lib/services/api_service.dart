import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../enums/enums.dart';
import 'sync_service.dart';

class ApiService {
  static const String baseUrl = 'https://backend-noobcoders.vercel.app/api'; 

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
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth ---

  static Future<void> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: _headers(null),
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp, [String? name]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers(null),
      body: jsonEncode({'phone': phone, 'otp': otp, if (name != null) 'name': name}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    throw Exception('Failed to verify OTP: ${response.body}');
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

  // --- Products ---

  static Future<List<Product>> getProducts() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/products'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        return Product(
          id: json['id'],
          name: json['name'],
          price: double.tryParse(json['price'].toString()) ?? 0.0,
          codes: json['codes'] != null ? List<String>.from(json['codes']) : [],
          taxRate: TaxRate.values.firstWhere((e) => e.name == json['tax_rate'], orElse: () => TaxRate.exempt),
          lowStockAlertLevel: double.tryParse(json['low_stock_level']?.toString() ?? '0') ?? 0.0,
          batches: [
            ProductBatch(
              batchNumber: 'INITIAL',
              mfgDate: DateTime.now(),
              expiryDate: null,
              stockCount: double.tryParse(json['current_stock']?.toString() ?? '0') ?? 0.0,
            )
          ],
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
        'price': p.price,
        'codes': p.codes,
        'tax_rate': p.taxRate.name,
        'current_stock': p.currentStock,
        'low_stock_level': p.lowStockAlertLevel,
      }),
    );
    if (response.statusCode == 200) {
      return p.copyWith(syncState: EntityState.synced);
    }
    throw Exception('Failed to save product');
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
        return InvoiceRecord(
          id: json['id'],
          customerName: json['customer_name'] ?? '',
          customerPhone: json['customer_phone'] ?? '',
          customerEmail: '',
          total: double.tryParse(json['total'].toString()) ?? 0.0,
          paymentMode: PaymentMode.values.firstWhere((e) => e.name == json['payment_mode'], orElse: () => PaymentMode.cash),
          createdAt: DateTime.parse(json['created_at']),
          lines: [], // In full version, fetch lines too
          channels: {},
          publicLink: '',
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
      }),
    );
    if (response.statusCode == 200) {
      return i;
    }
    throw Exception('Failed to save invoice');
  }
}
