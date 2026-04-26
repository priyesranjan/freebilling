
import '../enums/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
import '../services/sync_service.dart';

class OtpRequestResult {
  const OtpRequestResult({required this.requestId, this.debugOtp});
  final String requestId;
  final String? debugOtp;
}

class OwnerAuthSession {
  const OwnerAuthSession({
    required this.ownerId,
    required this.normalizedPhone,
    required this.provider,
    required this.loggedInAt,
    this.whatsappCredits = 0,
    this.smsCredits = 0,
  });

  final String ownerId;
  final String normalizedPhone;
  final String provider;
  final DateTime loggedInAt;
  final int whatsappCredits;
  final int smsCredits;

  String get displayPhone => formatIndianPhoneForDisplay(normalizedPhone);
}

class Customer implements SyncableEntity {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.syncState = EntityState.synced,
  });

  @override
  final String id;
  final String name;
  final String phone;
  final String? email;
  
  @override
  final EntityState syncState;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      syncState: EntityState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => EntityState.synced,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'syncState': syncState.name,
  };
}

class BusinessRecord implements SyncableEntity {
  const BusinessRecord({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.plan,
    required this.status,
    required this.validTill,
    this.whatsappCredits = 0,
    this.smsCredits = 0,
    this.syncState = EntityState.synced,
    this.businessType,
    this.websiteSlug,
    this.category,
    this.logoUrl,
  });

  @override
  final String id;
  final String businessName;
  final String ownerName;
  final BillingPlan plan;
  final BusinessStatus status;
  final DateTime validTill;
  final int whatsappCredits;
  final int smsCredits;
  
  @override
  final EntityState syncState;

  final String? businessType;
  final String? websiteSlug;
  final String? category;
  final String? logoUrl;

  factory BusinessRecord.fromJson(Map<String, dynamic> json) {
    return BusinessRecord(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      ownerName: json['ownerName'] as String,
      plan: BillingPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => BillingPlan.free,
      ),
      status: BusinessStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BusinessStatus.onboarded,
      ),
      validTill: DateTime.parse(json['validTill'] as String),
      whatsappCredits: json['whatsappCredits'] as int? ?? 0,
      smsCredits: json['smsCredits'] as int? ?? 0,
      syncState: EntityState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => EntityState.synced,
      ),
      businessType: json['businessType'] as String?,
      websiteSlug: json['websiteSlug'] as String?,
    );
  }

  BusinessRecord copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    BillingPlan? plan,
    BusinessStatus? status,
    DateTime? validTill,
    int? whatsappCredits,
    int? smsCredits,
    EntityState? syncState,
    String? businessType,
    String? websiteSlug,
  }) {
    return BusinessRecord(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      validTill: validTill ?? this.validTill,
      whatsappCredits: whatsappCredits ?? this.whatsappCredits,
      smsCredits: smsCredits ?? this.smsCredits,
      syncState: syncState ?? this.syncState,
      businessType: businessType ?? this.businessType,
      websiteSlug: websiteSlug ?? this.websiteSlug,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'ownerName': ownerName,
    'plan': plan.name,
    'status': status.name,
    'validTill': validTill.toIso8601String(),
    'whatsappCredits': whatsappCredits,
    'smsCredits': smsCredits,
    'syncState': syncState.name,
    'businessType': businessType,
    'websiteSlug': websiteSlug,
    'category': category,
    'logoUrl': logoUrl,
  };
}

// --- NEW GST ENUM ---
enum TaxRate {
  exempt(0.0),
  five(5.0),
  twelve(12.0),
  eighteen(18.0),
  twentyEight(28.0);

  const TaxRate(this.percentage);
  final double percentage;
}

enum PaymentMode {
  cash,
  upi,
  credit,
}

// --- NEW ADVANCED INVENTORY MODELS ---
class ProductVariant {
  const ProductVariant({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class ProductBatch {
  const ProductBatch({
    required this.batchNumber,
    required this.mfgDate,
    required this.expiryDate,
    required this.stockCount,
  });

  final String batchNumber;
  final DateTime mfgDate;
  final DateTime? expiryDate;
  final double stockCount;

  factory ProductBatch.fromJson(Map<String, dynamic> json) {
    return ProductBatch(
      batchNumber: json['batchNumber'] as String,
      mfgDate: DateTime.parse(json['mfgDate'] as String),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      stockCount: (json['stockCount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'batchNumber': batchNumber,
    'mfgDate': mfgDate.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'stockCount': stockCount,
  };
}

class Product implements SyncableEntity {
  const Product({
    required this.id,
    required this.name,
    required this.sellingPrice,
    required this.codes,
    this.mrp = 0.0,
    this.syncState = EntityState.synced,
    // Advanced Inventory
    this.variants = const [],
    this.batches = const [],
    this.lowStockAlertLevel = 0.0,
    this.initialStock = 0.0,
    // GST
    this.taxRate = TaxRate.exempt,
  });

  @override
  final String id;
  final String name;
  final double mrp;
  final double sellingPrice;
  final List<String> codes;
  
  @override
  final EntityState syncState;

  final List<ProductVariant> variants;
  final List<ProductBatch> batches;
  final double lowStockAlertLevel;
  final double initialStock;
  final TaxRate taxRate;

  double get price => sellingPrice;

  double get offPercentage {
    if (mrp <= 0 || sellingPrice >= mrp) return 0.0;
    return ((mrp - sellingPrice) / mrp) * 100;
  }

  double get currentStock {
    double batchStock = batches.fold(0.0, (sum, batch) => sum + batch.stockCount);
    return initialStock + batchStock;
  }

  Product copyWith({
    String? id,
    String? name,
    double? mrp,
    double? sellingPrice,
    List<String>? codes,
    EntityState? syncState,
    List<ProductVariant>? variants,
    List<ProductBatch>? batches,
    double? lowStockAlertLevel,
    double? initialStock,
    TaxRate? taxRate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      mrp: mrp ?? this.mrp,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      codes: codes ?? this.codes,
      syncState: syncState ?? this.syncState,
      variants: variants ?? this.variants,
      batches: batches ?? this.batches,
      lowStockAlertLevel: lowStockAlertLevel ?? this.lowStockAlertLevel,
      initialStock: initialStock ?? this.initialStock,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num? ?? json['sellingPrice'] as num? ?? json['price'] as num? ?? 0).toDouble(),
      codes: (json['codes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      syncState: EntityState.values.firstWhere(
        (e) => e.name == (json['sync_state'] ?? json['syncState']),
        orElse: () => EntityState.synced,
      ),
      variants: (json['variants'] as List<dynamic>?)?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      batches: (json['batches'] as List<dynamic>?)?.map((e) => ProductBatch.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      lowStockAlertLevel: (json['low_stock_level'] as num? ?? json['lowStockAlertLevel'] as num?)?.toDouble() ?? 0.0,
      initialStock: (json['initialStock'] as num? ?? json['initialStockCount'] as num? ?? json['current_stock'] as num? ?? json['currentStock'] as num? ?? 0).toDouble(),
      taxRate: TaxRate.values.firstWhere(
        (e) => e.name == json['taxRate'],
        orElse: () => TaxRate.exempt,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mrp': mrp,
    'sellingPrice': sellingPrice,
    'selling_price': sellingPrice,
    'price': sellingPrice,
    'codes': codes,
    'syncState': syncState.name,
    'sync_state': syncState.name,
    'variants': variants.map((v) => {
      'id': v.id,
      'name': v.name,
      'price': v.price,
    }).toList(),
    'batches': batches.map((b) => {
      'batchNumber': b.batchNumber,
      'mfgDate': b.mfgDate.toIso8601String(),
      'expiryDate': b.expiryDate?.toIso8601String(),
      'stockCount': b.stockCount,
    }).toList(),
    'lowStockAlertLevel': lowStockAlertLevel,
    'low_stock_level': lowStockAlertLevel,
    'initialStock': initialStock,
    'currentStock': currentStock,
    'current_stock': currentStock,
    'taxRate': taxRate.name,
    'tax_rate': taxRate.name,
  }; 
}

class CartItem {
  const CartItem({
    required this.product, 
    required this.quantity,
    this.selectedVariant,
    this.discountAmount = 0.0,
  });

  final Product product;
  final int quantity;
  final ProductVariant? selectedVariant;
  final double discountAmount;

  double get unitPrice => selectedVariant?.price ?? product.price;
  double get taxableAmount => (unitPrice * quantity) - discountAmount;
  double get taxAmount => taxableAmount * (product.taxRate.percentage / 100);
  double get finalAmount => taxableAmount + taxAmount;

  CartItem copyWith({
    Product? product, 
    int? quantity, 
    ProductVariant? selectedVariant, 
    double? discountAmount
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

class InvoiceRecord implements SyncableEntity {
  const InvoiceRecord({
    required this.id,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.total,
    required this.lines,
    required this.channels,
    required this.publicLink,
    this.syncState = EntityState.synced,
    // Deep Accounting & GST
    this.customerGstin,
    this.businessGstin,
    this.eWayBillNumber,
    this.isInterState = false,
    this.paymentMode = PaymentMode.cash,
    this.loyaltyPointsUsed = 0,
    this.discountAmount = 0.0,
    this.isEdited = false,
    this.linkedCustomerId,
  });

  @override
  final String id;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final double total;
  final List<CartItem> lines;
  final Set<DeliveryChannel> channels;
  final String publicLink;
  
  @override
  final EntityState syncState;

  final String? customerGstin;
  final String? businessGstin;
  final String? eWayBillNumber;
  final bool isInterState;
  
  // Vyapar-like features
   final PaymentMode paymentMode;
  final int loyaltyPointsUsed;
  final double discountAmount;
  final bool isEdited;
  final String? linkedCustomerId;

  double get totalTaxAmount => lines.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get cgstAmount => isInterState ? 0.0 : totalTaxAmount / 2;
  double get sgstAmount => isInterState ? 0.0 : totalTaxAmount / 2;
  double get igstAmount => isInterState ? totalTaxAmount : 0.0;

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    return InvoiceRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      customerEmail: json['customerEmail'] as String,
      total: (json['total'] as num).toDouble(),
      lines: [], // Note: Lines are not reconstructed from Sync Queue
      channels: {}, // Channels not reconstructed
      publicLink: json['publicLink'] as String,
      paymentMode: PaymentMode.values.firstWhere((e) => e.name == json['paymentMode'], orElse: () => PaymentMode.cash),
      loyaltyPointsUsed: json['loyaltyPointsUsed'] as int? ?? 0,
      discountAmount: (json['discountAmount'] as num? ?? 0).toDouble(),
      syncState: EntityState.values.firstWhere((e) => e.name == json['syncState'], orElse: () => EntityState.synced),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'total': total,
    'lines': lines.map((item) => {
      'product_id': item.product.id,
      'quantity': item.quantity,
      'selectedVariant_id': item.selectedVariant?.id,
      'discountAmount': item.discountAmount,
    }).toList(),
    'channels': channels.map((c) => c.name).toList(),
    'publicLink': publicLink,
    'syncState': syncState.name,
    'customerGstin': customerGstin,
    'businessGstin': businessGstin,
    'eWayBillNumber': eWayBillNumber,
    'isInterState': isInterState,
    'paymentMode': paymentMode.name,
    'loyaltyPointsUsed': loyaltyPointsUsed,
    'discountAmount': discountAmount,
    'isEdited': isEdited,
    'linkedCustomerId': linkedCustomerId,
  }; 
}

class PartyRecord implements SyncableEntity {
  const PartyRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.balance = 0.0,
    this.syncState = EntityState.synced,
  });

  @override
  final String id;
  final String name;
  final String phone;
  final PartyType type;
  final double balance; // Positive means we "To Get" from them, Negative means "To Give".

  @override
  final EntityState syncState;

  factory PartyRecord.fromJson(Map<String, dynamic> json) {
    return PartyRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      type: PartyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PartyType.customer,
      ),
      balance: (json['balance'] as num).toDouble(),
      syncState: EntityState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => EntityState.synced,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'type': type.name,
    'balance': balance,
    'syncState': syncState.name,
  };
}

class LedgerTransaction implements SyncableEntity {
  const LedgerTransaction({
    required this.id,
    required this.partyId,
    required this.type,
    required this.amount,
    required this.date,
    this.notes,
    this.syncState = EntityState.synced,
  });

  @override
  final String id;
  final String partyId;
  final LedgerTransactionType type;
  final double amount;
  final DateTime date;
  final String? notes;

  @override
  final EntityState syncState;

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] as String,
      partyId: json['partyId'] as String,
      type: LedgerTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LedgerTransactionType.paymentIn,
      ),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      syncState: EntityState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => EntityState.synced,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'partyId': partyId,
    'type': type.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'notes': notes,
    'syncState': syncState.name,
  };
}

// --- Expense Tracking ---
class ExpenseRecord implements SyncableEntity {
  const ExpenseRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.paymentMode,
    this.note = '',
    this.partyName = '',
    this.syncState = EntityState.synced,
  });

  @override
  final String id;
  final DateTime date;
  final double amount;
  final ExpenseCategory category;
  final PaymentMode paymentMode;
  final String note;
  final String partyName;

  @override
  final EntityState syncState;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'amount': amount,
    'category': category.name,
    'paymentMode': paymentMode.name,
    'note': note,
    'partyName': partyName,
    'syncState': syncState.name,
  };
}

// --- Bank Account ---
class BankAccount {
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    this.ifscCode = '',
    this.accountHolderName = '',
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
  });

  final String id;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final double openingBalance;
  final double currentBalance;
}

// --- App Settings (Persistent) ---
class AppSettings {
  AppSettings({
    // Item Settings
    this.enableItems = true,
    this.itemType = ItemType.both,
    this.barcodeScanning = false,
    this.stockMaintenance = true,
    this.isStaffMode = false,
    this.businessLogo,
    this.enableManufacturing = false,
    this.enableItemUnits = true,
    this.useDefaultUnit = false,
    this.enableItemCategory = true,
    this.partyWiseItemRate = false,
    this.enableWholesalePrice = false,
    this.quantityDecimalPlaces = 2,
    this.itemWiseTax = true,
    this.calculateTaxOnMrp = false,
    // Invoice Print Settings
    this.paperSize = PaperSize.thermal80mm,
    this.showLogo = true,
    this.showSignature = false,
    this.termsAndConditions = 'Thank you for your business!',
    this.invoicePrefix = 'INV',
    this.invoiceNextNumber = 1,
    // Tax Settings
    this.gstin = '',
    this.businessGstinEnabled = false,
    this.defaultTaxType = 'exclusive',
    // General
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.currency = '₹',
    // Reminders
    this.paymentReminderEnabled = false,
    this.reminderDaysBeforeDue = 3,
    this.autoWhatsAppReminder = false,
  });

  // Item Settings
  bool enableItems;
  ItemType itemType;
  bool barcodeScanning;
  bool stockMaintenance;
  bool isStaffMode;
  String? businessLogo;
  bool get isAdmin => !isStaffMode;
  bool enableManufacturing;
  bool enableItemUnits;
  bool useDefaultUnit;
  bool enableItemCategory;
  bool partyWiseItemRate;
  bool enableWholesalePrice;
  int quantityDecimalPlaces;
  bool itemWiseTax;
  bool calculateTaxOnMrp;

  // Invoice Print Settings
  PaperSize paperSize;
  bool showLogo;
  bool showSignature;
  String termsAndConditions;
  String invoicePrefix;
  int invoiceNextNumber;

  // Tax Settings
  String gstin;
  bool businessGstinEnabled;
  String defaultTaxType;

  // General
  String businessName;
  String businessAddress;
  String businessPhone;
  String businessEmail;
  String currency;

  // Reminders
  bool paymentReminderEnabled;
  int reminderDaysBeforeDue;
  bool autoWhatsAppReminder;

  // Singleton-style global instance
  static final AppSettings instance = AppSettings();

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isStaffMode', isStaffMode);
    await prefs.setString('businessName', businessName);
    await prefs.setString('businessAddress', businessAddress);
    await prefs.setString('businessPhone', businessPhone);
    if (businessLogo != null) await prefs.setString('businessLogo', businessLogo!);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isStaffMode = prefs.getBool('isStaffMode') ?? false;
    businessName = prefs.getString('businessName') ?? '';
    businessAddress = prefs.getString('businessAddress') ?? '';
    businessPhone = prefs.getString('businessPhone') ?? '';
    businessLogo = prefs.getString('businessLogo');
  }
}

