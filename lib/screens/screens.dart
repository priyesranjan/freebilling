import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../models/models.dart';
import '../enums/enums.dart';
import '../services/services.dart';
import '../core/core.dart';
import 'home_section.dart';
import 'items_section.dart';
import 'invoices_section.dart';
import 'khata_section.dart';
import 'menu_section.dart';

import 'auth_screen.dart';

export 'auth_screen.dart';
export 'onboarding_screen.dart';
export 'home_section.dart';
export 'items_section.dart';
export 'invoices_section.dart';
export 'khata_section.dart';
export 'menu_section.dart';

final List<BusinessRecord> mockBusinesses = <BusinessRecord>[
  BusinessRecord(
    id: 'B1001',
    businessName: 'Sarthi Grocery',
    ownerName: 'Amit Jain',
    plan: BillingPlan.basic,
    status: BusinessStatus.onboarded,
    validTill: DateTime.now().add(const Duration(days: 18)),
  ),
  BusinessRecord(
    id: 'B1002',
    businessName: 'Metro Pharmacy',
    ownerName: 'Neha Singh',
    plan: BillingPlan.premium,
    status: BusinessStatus.extended,
    validTill: DateTime.now().add(const Duration(days: 46)),
  ),
  BusinessRecord(
    id: 'B1003',
    businessName: 'Fresh Cart',
    ownerName: 'Ravi Kumar',
    plan: BillingPlan.free,
    status: BusinessStatus.suspended,
    validTill: DateTime.now().add(const Duration(days: 7)),
  ),
];

final List<Product> mockProducts = <Product>[
  Product(
    id: 'P2001',
    name: 'Milk 1L',
    sellingPrice: 58,
    mrp: 60,
    codes: const <String>['89010001', 'MILK-1L'],
    taxRate: TaxRate.five,
    lowStockAlertLevel: 10.0,
    batches: [
      ProductBatch(
        batchNumber: 'B-001',
        mfgDate: DateTime.now().subtract(const Duration(days: 5)),
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        stockCount: 15.0,
      ),
    ],
  ),
  Product(
    id: 'P2002',
    name: 'Rice 5kg',
    sellingPrice: 390,
    mrp: 450,
    codes: const <String>['89010002', 'RICE-5KG'],
    taxRate: TaxRate.exempt,
    lowStockAlertLevel: 5.0,
    batches: [
      ProductBatch(
        batchNumber: 'R-100',
        mfgDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 300)),
        stockCount: 4.0, // Low stock
      ),
    ],
  ),
  Product(
    id: 'P2003',
    name: 'Soap Pack',
    sellingPrice: 120,
    mrp: 150,
    codes: const <String>['89010003', 'SOAP-PACK'],
    taxRate: TaxRate.eighteen,
    lowStockAlertLevel: 20.0,
    batches: [
      ProductBatch(
        batchNumber: 'S-200',
        mfgDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 700)),
        stockCount: 50.0,
      ),
    ],
  ),
];

final List<InvoiceRecord> mockInvoices = <InvoiceRecord>[];

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService.instance.statusStream,
      initialData: SyncStatus.idle,
      builder: (context, snapshot) {
        final status = snapshot.data!;
        return StreamBuilder<int>(
          stream: SyncService.instance.queueSizeStream,
          initialData: 0,
          builder: (context, queueSnapshot) {
            final queueSize = queueSnapshot.data!;
            Widget icon;
            String text;
            Color color;
            
            if (status == SyncStatus.offline) {
              icon = const Icon(Icons.cloud_off, size: 16, color: BrandPalette.coral);
              text = 'Offline ($queueSize)';
              color = BrandPalette.coral;
            } else if (status == SyncStatus.syncing) {
              icon = const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: BrandPalette.sun),
              );
              text = 'Syncing...';
              color = BrandPalette.sun;
            } else {
              if (queueSize > 0) {
                 icon = const Icon(Icons.cloud_upload, size: 16, color: BrandPalette.teal);
                 text = '$queueSize pending';
                 color = BrandPalette.teal;
              } else {
                 icon = const Icon(Icons.cloud_done, size: 16, color: BrandPalette.mint);
                 text = 'Synced';
                 color = BrandPalette.mint;
              }
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   icon,
                   const SizedBox(width: 8),
                   Flexible(
                     child: Text(
                       text,
                       overflow: TextOverflow.ellipsis,
                       maxLines: 1,
                       style: GoogleFonts.dmSans(
                         fontSize: 12,
                         fontWeight: FontWeight.w700,
                         color: color,
                       ),
                     ),
                   ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PlatformShell extends StatefulWidget {
  const PlatformShell({super.key});

  @override
  State<PlatformShell> createState() => _PlatformShellState();
}

class _PlatformShellState extends State<PlatformShell> {
  AppSection _section = AppSection.home;
  int _sequence = 1000;

  bool _isLoading = true;
  List<BusinessRecord> _businesses = mockBusinesses;
  List<Product> _products = [];
  List<InvoiceRecord> _invoices = [];
  List<PartyRecord> _parties = [];
  List<ExpenseRecord> _expenses = [];

  @override
  void initState() {
    super.initState();
    SyncService.instance.initialize();
    _loadDataFromCloud();
    
    // Connect to WebSockets for live Multi-Device Sync
    try {
      WebSocketService.instance.connect();
      WebSocketService.instance.onDataChanged = () {
        debugPrint("WebSocket triggered Live Refresh!");
        _loadDataFromCloud();
      };
    } catch (e) {
      debugPrint("WebSocket Init Error: $e");
    }
  }

  Future<void> _loadDataFromCloud() async {
    setState(() => _isLoading = true);
    try {
      // Temporarily bypass token check since we don't have login flow fully wired yet for the demo
      // final token = await ApiService.getToken();
      
      _products = await ApiService.getProducts();
      _parties = await ApiService.getParties();
      _invoices = await ApiService.getInvoices();
    } catch (e) {
      // If fetching from API fails, fallback to empty
      debugPrint('Failed to load from cloud: $e');
      _businesses = [];
      _products = [];
      _parties = [];
      _invoices = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    WebSocketService.instance.disconnect();
    SyncService.instance.dispose();
    super.dispose();
  }

  String _nextId(String prefix) {
    _sequence += 1;
    return '$prefix$_sequence';
  }

  String _generatePublicInvoiceLink() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int randomSuffix = Random().nextInt(9000) + 1000;
    return 'https://erpbill.app/invoice/$timestamp-$randomSuffix';
  }

  String? _addProduct({
    required String name,
    required double sellingPrice,
    required double mrp,
    required List<String> codes,
    required double initialStock,
    required double lowStockAlertLevel,
    required TaxRate taxRate,
  }) {
    for (final String code in codes) {
      final bool alreadyExists = _products.any(
        (Product product) => product.codes.any(
          (String productCode) =>
              productCode.toLowerCase() == code.toLowerCase(),
        ),
      );

      if (alreadyExists) {
        return 'Code $code is already assigned to another product.';
      }
    }

    final product = Product(
      id: 'P-${DateTime.now().millisecondsSinceEpoch}', 
      name: name, 
      sellingPrice: sellingPrice, 
      mrp: mrp,
      codes: codes,
      initialStock: initialStock,
      lowStockAlertLevel: lowStockAlertLevel,
      taxRate: taxRate,
      syncState: EntityState.pendingInsert,
    );

    setState(() {
      _products.insert(0, product);
    });
    
    SyncService.instance.enqueueForSync(product);

    return null;
  }

  void _updateProduct(Product product) {
    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _products[index] = product;
        SyncService.instance.enqueueForSync(product);
      }
    });
  }

  void _deleteProduct(String id) {
    setState(() {
      _products.removeWhere((p) => p.id == id);
      // In a real app we'd mark it deleted and sync
    });
  }

  void _storeInvoice(InvoiceRecord invoice) {
    setState(() {
      _invoices.insert(0, invoice);
      
      // Khata (Ledger) Auto-Update Logic
      if (invoice.customerPhone.isNotEmpty) {
        final existingPartyIdx = _parties.indexWhere((p) => p.phone == invoice.customerPhone);
        PartyRecord party;
        if (existingPartyIdx >= 0) {
          party = _parties[existingPartyIdx];
        } else {
          party = PartyRecord(
            id: 'PARTY-${DateTime.now().millisecondsSinceEpoch}',
            name: invoice.customerName.isNotEmpty ? invoice.customerName : 'Unknown Customer',
            phone: invoice.customerPhone,
            type: PartyType.customer,
            balance: 0,
            syncState: EntityState.pendingInsert,
          );
        }

        // Add to customer's "To Get" balance
        double newBalance = party.balance + invoice.total;
        
        // If they paid immediately via Cash/UPI, settle the balance
        if (invoice.paymentMode != PaymentMode.credit) {
            newBalance -= invoice.total;
        }

        final updatedParty = PartyRecord(
            id: party.id,
            name: party.name,
            phone: party.phone,
            type: party.type,
            balance: newBalance,
            syncState: EntityState.pendingUpdate,
        );

        if (existingPartyIdx >= 0) {
            _parties[existingPartyIdx] = updatedParty;
        } else {
            _parties.add(updatedParty);
        }
        SyncService.instance.enqueueForSync(updatedParty);
      }

      // Stock Deduction Logic
      for (final line in invoice.lines) {
        final productIndex = _products.indexWhere((p) => p.id == line.product.id);
        if (productIndex >= 0) {
          final product = _products[productIndex];
          final adjustmentBatch = ProductBatch(
            batchNumber: 'INV-${invoice.id}',
            mfgDate: DateTime.now(),
            expiryDate: null,
            stockCount: -line.quantity.toDouble(), // Negative stock to deduct
          );
          
          final updatedProduct = product.copyWith(
            batches: [...product.batches, adjustmentBatch],
            syncState: EntityState.pendingUpdate,
          );
          
          _products[productIndex] = updatedProduct;
          SyncService.instance.enqueueForSync(updatedProduct);
        }
      }
    });
    SyncService.instance.enqueueForSync(invoice);
  }

  void _storeExpense(ExpenseRecord expense) {
    setState(() {
      _expenses.insert(0, expense);
    });
    SyncService.instance.enqueueForSync(expense);
  }

  Widget _sectionWidget() {
    switch (_section) {
      case AppSection.home:
        return HomeSection(
          businesses: _businesses,
          products: _products,
          invoices: _invoices,
          parties: _parties,
          expenses: _expenses,
          onAddSale: () => setState(() => _section = AppSection.invoices),
        );
      case AppSection.items:
        return ItemsSection(
          products: _products,
          onAddProduct: _addProduct,
          onUpdateProduct: _updateProduct,
          onDeleteProduct: _deleteProduct,
        );
      case AppSection.invoices:
        return InvoicesSection(
          invoices: _invoices,
          onCreateInvoice: _storeInvoice,
          products: _products,
          parties: _parties,
          generateInvoiceLink: _generatePublicInvoiceLink,
        );
      case AppSection.khata:
        return KhataSection(
          parties: _parties,
          onPartyAdded: (p) => setState(() => _parties.add(p)),
        );
      case AppSection.menu:
        return MenuSection(
          invoices: _invoices,
          expenses: _expenses,
          products: _products,
          onAddExpense: _storeExpense,
          onUpdateSettings: (s) => setState(() {}),
        );
    }
  }

  Widget _animatedSectionBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0.0, 0.03),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<AppSection>(_section),
        child: _sectionWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool isWide = MediaQuery.of(context).size.width >= 980;

    const List<NavigationRailDestination> railDestinations =
        <NavigationRailDestination>[
          NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: Text('Items'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: Text('Invoices'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: Text('Khata'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: Text('Menu'),
          ),
        ];

    if (isWide) {
      return Scaffold(
        body: BrandedBackdrop(
          child: Row(
            children: <Widget>[
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[BrandPalette.navy, Color(0xFF1D4D66)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: BrandPalette.navy.withValues(alpha: 0.22),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 20),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: BrandPalette.sun.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ERPBill',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Command',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const SyncIndicator(),
                        const SizedBox(height: 14),
                        Expanded(
                          child: NavigationRail(
                            backgroundColor: Colors.transparent,
                            selectedIndex: _section.index,
                            labelType: NavigationRailLabelType.all,
                            groupAlignment: -0.8,
                            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
                            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            unselectedIconTheme: const IconThemeData(color: Colors.white70),
                            selectedIconTheme: const IconThemeData(color: Colors.white),
                            indicatorColor: Colors.white.withValues(alpha: 0.2),
                            onDestinationSelected: (int index) {
                              setState(() {
                                _section = AppSection.values[index];
                              });
                            },
                            destinations: railDestinations,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 26, 24, 20),
                    child: _animatedSectionBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'ERP Bill Platform',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BrandPalette.navy,
              ),
            ),
            Text(
              'Scan faster. Bill smarter.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BrandPalette.navy.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: const <Widget>[
          SyncIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: BrandedBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _animatedSectionBody(),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        ),
        child: NavigationBar(
          selectedIndex: _section.index,
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 72,
          indicatorColor: BrandPalette.teal.withValues(alpha: 0.12),
          onDestinationSelected: (int index) {
            setState(() {
              _section = AppSection.values[index];
            });
          },
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 24),
              selectedIcon: Icon(Icons.dashboard, color: BrandPalette.teal),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, size: 24),
              selectedIcon: Icon(Icons.inventory_2, color: BrandPalette.teal),
              label: 'Items',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, size: 24),
              selectedIcon: Icon(Icons.receipt_long, color: BrandPalette.teal),
              label: 'Bills',
            ),
            NavigationDestination(
              icon: Icon(Icons.contacts_outlined, size: 24),
              selectedIcon: Icon(Icons.contacts, color: BrandPalette.teal),
              label: 'Parties',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_rounded, size: 24),
              selectedIcon: Icon(Icons.menu_open_rounded, color: BrandPalette.teal),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewSection extends StatelessWidget {
  const OverviewSection({
    super.key,
    required this.businesses,
    required this.products,
    required this.invoices,
  });

  final List<BusinessRecord> businesses;
  final List<Product> products;
  final List<InvoiceRecord> invoices;

  @override
  Widget build(BuildContext context) {
    final int activeBusinesses = businesses
        .where(
          (BusinessRecord business) =>
              business.status == BusinessStatus.onboarded ||
              business.status == BusinessStatus.extended,
        )
        .length;

    final int attemptedDeliveries = invoices.fold<int>(
      0,
      (int sum, InvoiceRecord invoice) => sum + invoice.channels.length,
    );

    final int successfulDeliveries = invoices.fold<int>(0, (
      int sum,
      InvoiceRecord invoice,
    ) {
      int successCount = 0;

      if (invoice.channels.contains(DeliveryChannel.whatsApp) &&
          invoice.customerPhone.isNotEmpty) {
        successCount += 1;
      }

      if (invoice.channels.contains(DeliveryChannel.sms) &&
          invoice.customerPhone.isNotEmpty) {
        successCount += 1;
      }

      if (invoice.channels.contains(DeliveryChannel.email) &&
          invoice.customerEmail.isNotEmpty) {
        successCount += 1;
      }

      return sum + successCount;
    });

    final double deliveryRate = attemptedDeliveries == 0
        ? 100
        : (successfulDeliveries / attemptedDeliveries) * 100;

    final ProfitAndLossReport pnl = ReportingService.instance.generatePnL(invoices);

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        const SectionIntro(
          eyebrow: 'Platform Overview',
          title: 'Advanced ERP Dashboard',
          description:
              'Admin controls all onboarded businesses. Business owners scan products and track live profit margins, GST, and inventory levels.',
          hintPill: 'Realtime command center',
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            StaggeredReveal(
              index: 0,
              child: MetricCard(
                title: 'Gross Profit',
                value: '₹${pnl.grossProfit.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                accentColor: BrandPalette.teal,
              ),
            ),
            StaggeredReveal(
              index: 1,
              child: MetricCard(
                title: 'Net Sales',
                value: '₹${pnl.netSales.toStringAsFixed(0)}',
                icon: Icons.point_of_sale,
                accentColor: BrandPalette.navy,
              ),
            ),
            StaggeredReveal(
              index: 2,
              child: MetricCard(
                title: 'Total Taxes',
                value: '₹${pnl.totalTaxes.toStringAsFixed(0)}',
                icon: Icons.request_quote,
                accentColor: BrandPalette.coral,
              ),
            ),
            StaggeredReveal(
              index: 3,
              child: MetricCard(
                title: 'Active Businesses',
                value: '$activeBusinesses',
                icon: Icons.apartment,
                accentColor: BrandPalette.teal,
              ),
            ),
            StaggeredReveal(
              index: 4,
              child: MetricCard(
                title: 'Products Indexed',
                value: '${products.length}',
                icon: Icons.inventory_2,
                accentColor: BrandPalette.navy,
              ),
            ),
            StaggeredReveal(
              index: 5,
              child: MetricCard(
                title: 'Delivery Success',
                value: '${deliveryRate.toStringAsFixed(1)}%',
                icon: Icons.mark_email_read,
                accentColor: BrandPalette.sun,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Launch Priority',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const PriorityPoint(
                  icon: Icons.rocket_launch,
                  text: 'Onboard businesses with status controls',
                ),
                const PriorityPoint(
                  icon: Icons.qr_code_2,
                  text: 'Product catalog with barcode and QR support',
                ),
                const PriorityPoint(
                  icon: Icons.photo_camera,
                  text: 'Camera-style scan input and customer capture',
                ),
                const PriorityPoint(
                  icon: Icons.send_to_mobile,
                  text:
                      'Public invoice link with WhatsApp, Email, and SMS delivery',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Recent Invoices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (invoices.isEmpty)
                  Text(
                    'No invoices generated yet.',
                    style: TextStyle(
                      color: BrandPalette.ink.withValues(alpha: 0.65),
                    ),
                  )
                else
                  ...invoices.take(5).map((InvoiceRecord invoice) {
                    final String channels = invoice.channels
                        .map((DeliveryChannel channel) => channel.label)
                        .join(', ');

                    return Column(
                      children: <Widget>[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: BrandPalette.teal.withValues(alpha: 0.14),
                            ),
                            child: const Icon(
                              Icons.receipt,
                              color: BrandPalette.teal,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            '${invoice.id} - Rs ${invoice.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${invoice.customerName} | $channels | ${formatDateTime(invoice.createdAt)}',
                          ),
                        ),
                        if (invoice != invoices.take(5).last)
                          Divider(
                            height: 1,
                            color: BrandPalette.navy.withValues(alpha: 0.08),
                          ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: accentColor),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BrandPalette.ink.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PriorityPoint extends StatelessWidget {
  const PriorityPoint({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandPalette.mint.withValues(alpha: 0.8),
            ),
            child: Icon(icon, size: 16, color: BrandPalette.navy),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class AdminSection extends StatefulWidget {
  const AdminSection({
    super.key,
    required this.businesses,
    required this.onAddBusiness,
    required this.onUpdateBusiness,
  });

  final List<BusinessRecord> businesses;
  final AddBusinessCallback onAddBusiness;
  final void Function(BusinessRecord updated) onUpdateBusiness;

  @override
  State<AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends State<AdminSection> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  BillingPlan _selectedPlan = BillingPlan.free;

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  void _onboardBusiness() {
    final String businessName = _businessNameController.text.trim();
    final String ownerName = _ownerNameController.text.trim();

    if (businessName.isEmpty || ownerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business name and owner name are required.'),
        ),
      );
      return;
    }

    widget.onAddBusiness(
      businessName: businessName,
      ownerName: ownerName,
      plan: _selectedPlan,
    );

    setState(() {
      _businessNameController.clear();
      _ownerNameController.clear();
      _selectedPlan = BillingPlan.free;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business onboarded successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        const SectionIntro(
          eyebrow: 'Operations',
          title: 'Admin Console',
          description:
              'Manage all onboarded businesses with lifecycle actions: onboard, suspend, deactivate, and extend.',
          hintPill: 'Business governance',
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          index: 0,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Onboard New Business',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _businessNameController,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 230,
                        child: TextField(
                          controller: _ownerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Owner Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<BillingPlan>(
                          initialValue: _selectedPlan,
                          decoration: const InputDecoration(
                            labelText: 'Plan',
                            border: OutlineInputBorder(),
                          ),
                          items: BillingPlan.values
                              .map(
                                (BillingPlan plan) =>
                                    DropdownMenuItem<BillingPlan>(
                                      value: plan,
                                      child: Text(plan.label),
                                    ),
                              )
                              .toList(),
                          onChanged: (BillingPlan? plan) {
                            if (plan == null) {
                              return;
                            }
                            setState(() {
                              _selectedPlan = plan;
                            });
                          },
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _onboardBusiness,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Onboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          index: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Business Lifecycle Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                        BrandPalette.mint.withValues(alpha: 0.44),
                      ),
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Business')),
                        DataColumn(label: Text('Owner')),
                        DataColumn(label: Text('Plan')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Valid Till')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: widget.businesses.map((BusinessRecord record) {
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(Text(record.businessName)),
                            DataCell(Text(record.ownerName)),
                            DataCell(
                              DropdownButton<BillingPlan>(
                                value: record.plan,
                                onChanged: (BillingPlan? plan) {
                                  if (plan == null) {
                                    return;
                                  }
                                  widget.onUpdateBusiness(
                                    record.copyWith(plan: plan),
                                  );
                                },
                                items: BillingPlan.values
                                    .map(
                                      (BillingPlan plan) =>
                                          DropdownMenuItem<BillingPlan>(
                                            value: plan,
                                            child: Text(plan.label),
                                          ),
                                    )
                                    .toList(),
                              ),
                            ),
                            DataCell(
                              DropdownButton<BusinessStatus>(
                                value: record.status,
                                onChanged: (BusinessStatus? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  widget.onUpdateBusiness(
                                    record.copyWith(status: value),
                                  );
                                },
                                items: BusinessStatus.values
                                    .map(
                                      (BusinessStatus status) =>
                                          DropdownMenuItem<BusinessStatus>(
                                            value: status,
                                            child: Text(status.label),
                                          ),
                                    )
                                    .toList(),
                              ),
                            ),
                            DataCell(Text(formatDate(record.validTill))),
                            DataCell(
                              TextButton(
                                onPressed: () {
                                  widget.onUpdateBusiness(
                                    record.copyWith(
                                      status: BusinessStatus.extended,
                                      validTill: record.validTill.add(
                                        const Duration(days: 30),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Extend 30d'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OwnerAuthSection extends StatefulWidget {
  const OwnerAuthSection({
    super.key,
    required this.authService,
    required this.onLoggedIn,
  });

  final OwnerAuthService authService;
  final ValueChanged<OwnerAuthSession> onLoggedIn;

  @override
  State<OwnerAuthSection> createState() => _OwnerAuthSectionState();
}

class _OwnerAuthSectionState extends State<OwnerAuthSection> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _normalizedPhone;
  String? _requestId;
  String? _debugOtp;
  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final String? phone = normalizeIndianPhoneNumber(_phoneController.text);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Indian phone number.')),
      );
      return;
    }

    setState(() {
      _isRequestingOtp = true;
      _debugOtp = null;
    });

    try {
      final OtpRequestResult result = await widget.authService.requestOtp(
        phoneNumber: phone,
      );

      setState(() {
        _normalizedPhone = phone;
        _requestId = result.requestId;
        _debugOtp = result.debugOtp;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${formatIndianPhoneForDisplay(phone)}.'),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final String otp = _otpController.text.trim();
    final String? requestId = _requestId;
    final String? phone = _normalizedPhone;

    if (requestId == null || phone == null) {
      return;
    }

    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP sent to your phone.')),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final OwnerAuthSession session = await widget.authService.verifyOtp(
        phoneNumber: phone,
        requestId: requestId,
        otp: otp,
      );

      if (!mounted) {
        return;
      }

      widget.onLoggedIn(session);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${session.displayPhone}')),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        const SectionIntro(
          eyebrow: 'Owner Access',
          title: 'Business Owner Login',
          description:
              'Use phone number OTP login for signup and sign-in using 2factor authentication.',
          hintPill: 'India-first phone onboarding',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: BrandPalette.teal.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: BrandPalette.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Step 1: Request OTP',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: 270,
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '9876543210 or +91 9876543210',
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _isRequestingOtp ? null : _requestOtp,
                      icon: _isRequestingOtp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sms),
                      label: Text(_isRequestingOtp ? 'Sending...' : 'Send OTP'),
                    ),
                  ],
                ),
                if (_requestId != null) ...<Widget>[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: BrandPalette.sun.withValues(alpha: 0.23),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: BrandPalette.navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Step 2: Verify OTP',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'OTP',
                            hintText: '6-digit code',
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _isVerifyingOtp ? null : _verifyOtp,
                        icon: _isVerifyingOtp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_user),
                        label: Text(
                          _isVerifyingOtp ? 'Verifying...' : 'Verify & Login',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _isRequestingOtp ? null : _requestOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ],
                  ),
                ],
                if (_debugOtp != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: BrandPalette.coral.withValues(alpha: 0.14),
                    ),
                    child: Text(
                      'Dev OTP (remove in production): $_debugOtp',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text(
                  'Production Note',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10),
                Text(
                  'Keep 2factor API keys on server-side only. The Flutter app should call your backend auth endpoints, and the backend should talk to 2factor.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OwnerSection extends StatefulWidget {
  const OwnerSection({
    super.key,
    required this.ownerSession,
    required this.onLogout,
    required this.products,
    required this.invoices,
    required this.onAddProduct,
    required this.onGenerateInvoiceLink,
    required this.onCreateInvoice,
  });

  final OwnerAuthSession ownerSession;
  final VoidCallback onLogout;
  final List<Product> products;
  final List<InvoiceRecord> invoices;
  final AddProductCallback onAddProduct;
  final String Function() onGenerateInvoiceLink;
  final void Function(InvoiceRecord invoice) onCreateInvoice;

  @override
  State<OwnerSection> createState() => _OwnerSectionState();
}

class _OwnerSectionState extends State<OwnerSection> {
  final List<CartItem> _cart = <CartItem>[];

  final TextEditingController _scanController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productCodesController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerEmailController =
      TextEditingController();

  bool _sendWhatsApp = true;
  bool _sendEmail = true;
  bool _sendSms = true;
  bool _isInterState = false;
  String _invoiceLink = '';

  @override
  void dispose() {
    _scanController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productCodesController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    super.dispose();
  }

  double get _total => _cart.fold<double>(
    0,
    (double sum, CartItem line) => sum + line.finalAmount,
  );

  Product? _findProductByCode(String code) {
    for (final Product product in widget.products) {
      for (final String productCode in product.codes) {
        if (productCode.toLowerCase() == code.toLowerCase()) {
          return product;
        }
      }
    }

    return null;
  }

  void _addToCart(Product product) {
    final int existingIndex = _cart.indexWhere(
      (CartItem line) => line.product.id == product.id,
    );

    setState(() {
      if (existingIndex == -1) {
        _cart.add(CartItem(product: product, quantity: 1));
      } else {
        final CartItem existingLine = _cart[existingIndex];
        _cart[existingIndex] = existingLine.copyWith(
          quantity: existingLine.quantity + 1,
        );
      }
    });
  }

  void _changeQuantity(String productId, int delta) {
    final int index = _cart.indexWhere(
      (CartItem line) => line.product.id == productId,
    );
    if (index == -1) {
      return;
    }

    final int nextQuantity = _cart[index].quantity + delta;
    setState(() {
      if (nextQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(quantity: nextQuantity);
      }
    });
  }

  void _scanCode() {
    final String code = _scanController.text.trim();
    if (code.isEmpty) {
      return;
    }

    final Product? found = _findProductByCode(code);
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product found for scanned code.')),
      );
      return;
    }

    _addToCart(found);
    _scanController.clear();
  }

  void _addProductToCatalog() {
    final String name = _productNameController.text.trim();
    final double? price = double.tryParse(_productPriceController.text.trim());
    final List<String> codes = _productCodesController.text
        .split(RegExp(r'[,\n]'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (name.isEmpty || price == null || codes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product name, valid price, and at least one barcode or QR code are required.',
          ),
        ),
      );
      return;
    }

    final String? error = widget.onAddProduct(
      name: name,
      price: price,
      codes: codes,
    );

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      _productNameController.clear();
      _productPriceController.clear();
      _productCodesController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product added to catalog.')));
  }

  void _createInvoiceLink() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add products before generating invoice.'),
        ),
      );
      return;
    }

    setState(() {
      _invoiceLink = widget.onGenerateInvoiceLink();
    });
  }

  Set<DeliveryChannel> _selectedChannels() {
    return <DeliveryChannel>{
      if (_sendWhatsApp) DeliveryChannel.whatsApp,
      if (_sendEmail) DeliveryChannel.email,
      if (_sendSms) DeliveryChannel.sms,
    };
  }

  void _sendInvoice() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add products before sending invoice.')),
      );
      return;
    }

    if (_invoiceLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate invoice link first.')),
      );
      return;
    }

    final Set<DeliveryChannel> channels = _selectedChannels();
    if (channels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one delivery channel.')),
      );
      return;
    }

    final String phone = _customerPhoneController.text.trim();
    final String email = _customerEmailController.text.trim();

    if ((channels.contains(DeliveryChannel.whatsApp) ||
            channels.contains(DeliveryChannel.sms)) &&
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is required for WhatsApp or SMS.'),
        ),
      );
      return;
    }

    if (channels.contains(DeliveryChannel.email) && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required for Email delivery.')),
      );
      return;
    }

    final String customerName = _customerNameController.text.trim().isEmpty
        ? 'Walk-in Customer'
        : _customerNameController.text.trim();

    final InvoiceRecord invoice = InvoiceRecord(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      customerName: customerName,
      customerPhone: phone,
      customerEmail: email,
      total: _total,
      lines: _cart.map((CartItem line) => line.copyWith()).toList(),
      channels: channels,
      publicLink: _invoiceLink,
      isInterState: _isInterState,
    );

    widget.onCreateInvoice(invoice);

    setState(() {
      _cart.clear();
      _invoiceLink = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invoice sent via ${channels.map((DeliveryChannel channel) => channel.label).join(', ')}.',
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Store", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              "Owner",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: BrandPalette.coral),
          onPressed: () async {
            await ApiService.clearToken();
            WebSocketService.instance.disconnect();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        const SectionIntro(
          eyebrow: 'Store Console',
          title: 'Business Owner Billing',
          description:
              'Scan barcode or QR value to fetch product details, bill quickly, and share with customers.',
          hintPill: 'Mobile-first billing flow',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildProfileHeader(),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          index: 0,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Product Catalog',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _productNameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _productPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 340,
                        child: TextField(
                          controller: _productCodesController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode or QR values (comma separated)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _addProductToCatalog,
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Products available: ${widget.products.length}'),
                  const SizedBox(height: 8),
                  ...widget.products.take(6).map((Product product) {
                    final bool isLowStock = product.currentStock <= product.lowStockAlertLevel;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(product.name),
                      subtitle: Text('Codes: ${product.codes.join(', ')} | Stock: ${product.currentStock}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Rs ${product.price.toStringAsFixed(2)}'),
                          if (product.taxRate != TaxRate.exempt)
                            Text('+${product.taxRate.percentage}% GST', style: const TextStyle(fontSize: 10, color: BrandPalette.teal)),
                          if (isLowStock)
                            const Text('Low Stock', style: TextStyle(fontSize: 10, color: BrandPalette.coral)),
                        ]
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          index: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Scan and Build Cart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _scanController,
                          decoration: const InputDecoration(
                            hintText: 'Enter barcode or QR value',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _scanCode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Add'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _cart.clear();
                            _invoiceLink = '';
                          });
                        },
                        child: const Text('Clear Cart'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Cart Items: ${_cart.length}'),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      children: [
                        if (_cart.isEmpty)
                          const Text('No products in cart yet.')
                        else
                          ..._cart.map((CartItem item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Unit Rs ${item.product.price.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _changeQuantity(item.product.id, -1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () =>
                                  _changeQuantity(item.product.id, 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            SizedBox(
                              width: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Rs ${item.finalAmount.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.taxAmount > 0)
                                    Text(
                                      '+ Rs ${item.taxAmount.toStringAsFixed(2)} Tax',
                                      style: const TextStyle(fontSize: 10, color: BrandPalette.teal),
                                    )
                                ]
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                      ],
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Rs ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          index: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Customer Details and Delivery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customerEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: _isInterState,
                        onChanged: (bool value) {
                          setState(() {
                            _isInterState = value;
                          });
                        },
                        activeThumbColor: BrandPalette.teal,
                      ),
                      const SizedBox(width: 8),
                      const Text('Inter-State Sale (Apply IGST instead of CGST/SGST)'),
                    ]
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: <Widget>[
                      FilterChip(
                        selected: _sendWhatsApp,
                        label: const Text('WhatsApp'),
                        onSelected: (bool value) {
                          setState(() {
                            _sendWhatsApp = value;
                          });
                        },
                      ),
                      FilterChip(
                        selected: _sendEmail,
                        label: const Text('Email'),
                        onSelected: (bool value) {
                          setState(() {
                            _sendEmail = value;
                          });
                        },
                      ),
                      FilterChip(
                        selected: _sendSms,
                        label: const Text('SMS'),
                        onSelected: (bool value) {
                          setState(() {
                            _sendSms = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton(
                        onPressed: _createInvoiceLink,
                        child: const Text('Generate Public Invoice Link'),
                      ),
                      OutlinedButton(
                        onPressed: _sendInvoice,
                        child: const Text('Send to Customer'),
                      ),
                    ],
                  ),
                  if (_invoiceLink.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    SelectableText('Public Link: $_invoiceLink'),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          index: 3,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Recent Invoice History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  if (widget.invoices.isEmpty)
                    const Text('No invoices created yet.')
                  else
                    ...widget.invoices.take(6).map((InvoiceRecord invoice) {
                      final String channelSummary = invoice.channels
                          .map((DeliveryChannel channel) => channel.label)
                          .join(', ');

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${invoice.id} - Rs ${invoice.total.toStringAsFixed(2)}',
                        ),
                        subtitle: Text(
                          '${invoice.customerName} | $channelSummary | ${formatDateTime(invoice.createdAt)}',
                        ),
                        trailing: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BrandPalette.teal.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.link,
                            size: 18,
                            color: BrandPalette.teal,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PlansSection extends StatelessWidget {
  const PlansSection({
    super.key,
    required this.businesses,
    required this.invoices,
  });

  final List<BusinessRecord> businesses;
  final List<InvoiceRecord> invoices;

  @override
  Widget build(BuildContext context) {
    final int freeBusinesses = businesses
        .where((BusinessRecord business) => business.plan == BillingPlan.free)
        .length;
    final int basicBusinesses = businesses
        .where((BusinessRecord business) => business.plan == BillingPlan.basic)
        .length;
    final int premiumBusinesses = businesses
        .where(
          (BusinessRecord business) => business.plan == BillingPlan.premium,
        )
        .length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        SectionIntro(
          eyebrow: 'Monetization',
          title: 'Billing Plans',
          description:
              'Free, Basic, and Premium plans with feature gating. Total invoices generated in app: ${invoices.length}.',
          hintPill: 'Upgrade moments',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            StaggeredReveal(
              index: 0,
              child: PlanCard(
                name: 'Free',
                price: 'Rs 0 / month',
                subscribers: '$freeBusinesses active businesses',
                accentColor: const Color(0xFF7B8A95),
                features: const <String>[
                  '100 invoices per month',
                  'Single user',
                  'Basic barcode scan',
                  'Watermarked invoice link',
                ],
              ),
            ),
            StaggeredReveal(
              index: 1,
              child: PlanCard(
                name: 'Basic',
                price: 'Rs 799 / month',
                subscribers: '$basicBusinesses active businesses',
                accentColor: BrandPalette.teal,
                features: const <String>[
                  '2,000 invoices per month',
                  'WhatsApp and Email sharing',
                  'Customer history',
                  'Simple analytics dashboard',
                ],
              ),
            ),
            StaggeredReveal(
              index: 2,
              child: PlanCard(
                name: 'Premium',
                price: 'Rs 1,999 / month',
                subscribers: '$premiumBusinesses active businesses',
                accentColor: BrandPalette.sun,
                features: const <String>[
                  'Unlimited invoices',
                  'Multi-store support',
                  'Advanced analytics and alerts',
                  'Priority support and API access',
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.name,
    required this.price,
    required this.subscribers,
    required this.accentColor,
    required this.features,
  });

  final String name;
  final String price;
  final String subscribers;
  final Color accentColor;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accentColor.withValues(alpha: 0.18),
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: accentColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.75),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Live',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    color: BrandPalette.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 26,
                    color: BrandPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subscribers),
                const SizedBox(height: 14),
                ...features.map(
                  (String feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.check_circle, size: 17, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    foregroundColor: BrandPalette.navy,
                    backgroundColor: accentColor.withValues(alpha: 0.2),
                  ),
                  child: Text('Choose $name'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionIntro extends StatelessWidget {
  const SectionIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.hintPill,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String hintPill;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: BrandPalette.mint.withValues(alpha: 0.62),
              ),
              child: Text(
                eyebrow.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BrandPalette.navy,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 34,
                color: BrandPalette.navy,
              ),
            ),
            const SizedBox(height: 10),
            Text(description),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BrandPalette.navy.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.bolt, color: BrandPalette.sun, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    hintPill,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int delay = index * 70;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 22),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}

class BrandedBackdrop extends StatelessWidget {
  const BrandedBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Container(color: BrandPalette.pageBase),
        ),
        // Glassmorphic Mesh Orbs
        Positioned(
          top: -150,
          right: -100,
          child: _MeshOrb(size: 500, color: BrandPalette.teal.withValues(alpha: 0.1)),
        ),
        Positioned(
          bottom: -200,
          left: -150,
          child: _MeshOrb(size: 600, color: BrandPalette.sun.withValues(alpha: 0.08)),
        ),
        Positioned(
          top: 100,
          left: -100,
          child: _MeshOrb(size: 400, color: BrandPalette.coral.withValues(alpha: 0.05)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _MeshOrb extends StatelessWidget {
  const _MeshOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class SoftGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = BrandPalette.navy.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    const double gap = 28;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
