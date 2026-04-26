import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import '../services/services.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:typed_data';

enum InvoiceFilter { all, paid, unpaid }

class InvoicesSection extends StatefulWidget {
  final List<InvoiceRecord> invoices;
  final void Function(InvoiceRecord)? onCreateInvoice;
  final List<Product>? products;
  final List<PartyRecord>? parties;
  final String Function()? generateInvoiceLink;

  const InvoicesSection({
    super.key,
    required this.invoices,
    this.onCreateInvoice,
    this.products,
    this.parties,
    this.generateInvoiceLink,
  });

  @override
  State<InvoicesSection> createState() => _InvoicesSectionState();
}

class _InvoicesSectionState extends State<InvoicesSection> {
  InvoiceFilter _filter = InvoiceFilter.all;
  DocumentType _docType = DocumentType.invoice;

  List<InvoiceRecord> get filtered {
    var list = widget.invoices.where((i) => i.type == _docType).toList();
    switch (_filter) {
      case InvoiceFilter.all:
        return list;
      case InvoiceFilter.paid:
        return list.where((i) => i.paymentMode != PaymentMode.credit).toList();
      case InvoiceFilter.unpaid:
        return list.where((i) => i.paymentMode == PaymentMode.credit).toList();
    }
  }

  double get totalAmount => widget.invoices.fold(0, (s, i) => s + i.total);
  double get todayAmount => widget.invoices
      .where((i) => isSameDate(i.createdAt, DateTime.now()))
      .fold(0, (s, i) => s + i.total);

  @override
  Widget build(BuildContext context) {
    final bills = filtered;

    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Bills & Invoices'),
        elevation: 0,
        backgroundColor: BrandPalette.pageBase,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: InvoiceFilter.values.map((f) {
                final isSelected = _filter == f;
                final label = f == InvoiceFilter.all ? 'All (${widget.invoices.length})'
                    : f == InvoiceFilter.paid ? 'Paid' : 'Unpaid';
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _filter = f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? BrandPalette.navy : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? BrandPalette.navy : Colors.grey.shade300),
                    ),
                    child: Text(label, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    )),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (AppSettings.instance.enableQuotations)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SegmentedButton<DocumentType>(
                segments: const [
                  ButtonSegment(value: DocumentType.invoice, label: Text('Bills/Invoices'), icon: Icon(Icons.receipt_long)),
                  ButtonSegment(value: DocumentType.quotation, label: Text('Quotations'), icon: Icon(Icons.description_outlined)),
                ],
                selected: {_docType},
                onSelectionChanged: (Set<DocumentType> newSelection) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _docType = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: BrandPalette.navy,
                ),
              ),
            ),
          // Summary banner
          if (widget.invoices.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [BrandPalette.teal, Color(0xFF15A89E)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Sales', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ]),
                  ),
                  Container(width: 1, height: 36, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Today's Sales", style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('₹${todayAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ]),
                  ),
                ],
              ),
            ),
          Expanded(
            child: bills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .moveY(begin: -5, end: 5, duration: 1000.ms, curve: Curves.easeInOut),
                        const SizedBox(height: 16),
                        Text(
                          _filter == InvoiceFilter.all ? 'No bills yet.\nTap "Create Bill" to get started!' : 'No ${_filter.name} bills found.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ).animate().fadeIn(duration: 500.ms),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final inv = bills[index];
                      final isCredit = inv.paymentMode == PaymentMode.credit;
                      final statusColor = isCredit ? BrandPalette.coral : BrandPalette.teal;
                      final statusLabel = isCredit ? 'UNPAID' : 'PAID';

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showInvoiceDetail(context, inv),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: BrandPalette.navy.withValues(alpha: 0.08),
                                  child: Text(
                                    inv.customerName.isNotEmpty ? inv.customerName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: BrandPalette.navy, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inv.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(formatDateTime(inv.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(inv.paymentMode.name.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${inv.total.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandPalette.navy)),
                                    const SizedBox(height: 4),
                                    // Share button
                                    InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Invoice link copied!'), duration: Duration(seconds: 1)),
                                        );
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.share, size: 12, color: BrandPalette.teal),
                                          SizedBox(width: 4),
                                          Text('Share', style: TextStyle(color: BrandPalette.teal, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showCreateBillSheet(context);
        },
        backgroundColor: BrandPalette.coral,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_docType == DocumentType.quotation ? 'Create Quotation' : 'Create Bill', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showInvoiceDetail(BuildContext context, InvoiceRecord inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: BrandPalette.navy),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Invoice #${inv.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  Text('₹${inv.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: BrandPalette.teal)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _printOrSharePdf(context, inv),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print / Save PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrandPalette.navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _shareOnWhatsApp(context, inv),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  if (inv.paymentMode == PaymentMode.credit) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _generatePaymentLink(context, inv),
                        icon: const Icon(Icons.payment),
                        label: const Text('Generate Payment Link'),
                        style: FilledButton.styleFrom(
                          backgroundColor: BrandPalette.navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                  if (inv.type == DocumentType.quotation) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // close sheet
                          if (widget.onCreateInvoice != null) {
                            // Call the creation flow with the quotation to be converted
                            widget.onCreateInvoice!(inv);
                          }
                        },
                        icon: const Icon(Icons.transform),
                        label: const Text('Convert to Bill'),
                        style: FilledButton.styleFrom(
                          backgroundColor: BrandPalette.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Customer', inv.customerName),
                  _detailRow('Phone', inv.customerPhone.isEmpty ? '-' : inv.customerPhone),
                  _detailRow('Date', formatDateTime(inv.createdAt)),
                  _detailRow('Payment', inv.paymentMode.name.toUpperCase()),
                  _detailRow('Items', '${inv.lines.length} items'),
                  _detailRow('Tax', '₹${inv.totalTaxAmount.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: inv.lines.map((line) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line.product.name),
                  subtitle: Text('₹${line.unitPrice} × ${line.quantity}'),
                  trailing: Text('₹${line.finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printOrSharePdf(BuildContext context, InvoiceRecord inv) async {
    try {
      final business = BusinessRecord(
        id: 'B1', businessName: 'My Store', ownerName: 'Store Owner',
        plan: BillingPlan.premium, status: BusinessStatus.onboarded, validTill: DateTime.now()
      );
      
      final String format = AppSettings.instance.invoiceFormat;
      final Uint8List pdfBytes;
      
      if (format == 'A4') {
        pdfBytes = await A4PdfService.generateA4Invoice(inv);
      } else {
        pdfBytes = await PdfInvoiceService.generateInvoice(inv, business);
      }
      
      await Printing.sharePdf(bytes: pdfBytes, filename: 'invoice_${inv.id}.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  void _shareOnWhatsApp(BuildContext context, InvoiceRecord inv) async {
    if (inv.customerPhone.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer phone number is required to share via WhatsApp.')));
       return;
    }
    
    final String text = 'Hello ${inv.customerName},\n\nThank you for your purchase!\nYour Invoice #${inv.id} for Rs. ${inv.total.toStringAsFixed(2)} is confirmed.\n\nThank you!';
    final Uri whatsappUri = Uri.parse('https://wa.me/91${inv.customerPhone}?text=${Uri.encodeComponent(text)}');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp. Make sure it is installed.')));
    }
  }

  void _generatePaymentLink(BuildContext context, InvoiceRecord inv) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final url = await RazorpayService.generatePaymentLink(inv);
      Navigator.pop(context); // Close loading
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment Link Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(url, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              const SizedBox(height: 16),
              const Text('This link has also been sent to the customer via SMS/Email by Razorpay automatically.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              child: const Text('Open Link'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showCreateBillSheet(BuildContext context, [InvoiceRecord? initialQuotation]) {
    int _currentStep = 0;
    String _searchQuery = '';
    final customerNameCtrl = TextEditingController(text: initialQuotation?.customerName ?? '');
    final customerPhoneCtrl = TextEditingController(text: initialQuotation?.customerPhone ?? '');
    final customerEmailCtrl = TextEditingController(text: initialQuotation?.customerEmail ?? '');
    final customerGstCtrl = TextEditingController(text: initialQuotation?.customerGstin ?? '');
    final customerAddressCtrl = TextEditingController();
    
    final discountCtrl = TextEditingController(text: initialQuotation?.discountAmount.toStringAsFixed(0) ?? '0');
    final loyaltyPointsCtrl = TextEditingController(text: initialQuotation?.loyaltyPointsUsed.toString() ?? '0');
    PartyRecord? selectedParty;
    
    final List<CartItem> cartItems = initialQuotation?.lines.toList() ?? [];
    PaymentMode paymentMode = initialQuotation?.paymentMode ?? PaymentMode.cash;
    DocumentType creatingType = initialQuotation == null ? _docType : DocumentType.invoice; // Converting always makes an invoice

    if (widget.products == null || widget.products!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items first before creating a bill!'), backgroundColor: BrandPalette.coral),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          void listener() {
            final phone = customerPhoneCtrl.text.trim();
            if (phone.length >= 10 && widget.parties != null) {
              final existing = widget.parties!.where((p) => p.phone == phone).firstOrNull;
              if (existing != null) {
                if (customerNameCtrl.text.isEmpty) customerNameCtrl.text = existing.name;
                if (selectedParty != existing) {
                  setS(() => selectedParty = existing);
                }
              } else if (selectedParty != null) {
                setS(() => selectedParty = null);
              }
            } else if (selectedParty != null) {
              setS(() => selectedParty = null);
            }
          }
          
          customerPhoneCtrl.removeListener(listener);
          customerPhoneCtrl.addListener(listener);

          final total = cartItems.fold(0.0, (s, i) => s + i.finalAmount);
          
          Widget buildItemsStep() {
            final filtered = widget.products!.where((p) {
              return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                     p.codes.any((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()));
            }).toList();

            return Column(
              children: [
                TextField(
                  autofocus: true,
                  onChanged: (val) => setS(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search Product Name or Scan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: BrandPalette.teal),
                      onPressed: () => _showScannerOverlay(ctx2, widget.products!, cartItems, setS),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (_searchQuery.isNotEmpty)
                  Container(
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                    child: filtered.isEmpty
                        ? Center(child: Text('No items found', style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              return ListTile(
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('₹${p.price}', style: const TextStyle(fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle, color: BrandPalette.teal),
                                  onPressed: () {
                                    setS(() {
                                      final existing = cartItems.indexWhere((c) => c.product.id == p.id);
                                      if (existing >= 0) {
                                        cartItems[existing] = cartItems[existing].copyWith(quantity: cartItems[existing].quantity + 1);
                                      } else {
                                        cartItems.add(CartItem(product: p, quantity: 1));
                                      }
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                Row(
                  children: [
                    const Text('Cart Items', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const Spacer(),
                    Text('${cartItems.length} items', style: const TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.teal)),
                  ],
                ),
                const SizedBox(height: 8),
                if (cartItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Text('Search or scan items to add them to the bill.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  )
                else
                  ...cartItems.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: BrandPalette.navy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_2, size: 20, color: BrandPalette.navy),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('₹${item.unitPrice}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: BrandPalette.coral),
                              onPressed: () => setS(() {
                                if (item.quantity > 1) {
                                  final idx = cartItems.indexWhere((c) => c.product.id == item.product.id);
                                  cartItems[idx] = item.copyWith(quantity: item.quantity - 1);
                                } else {
                                  cartItems.removeWhere((c) => c.product.id == item.product.id);
                                }
                              }),
                            ),
                            Text('${item.quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20, color: BrandPalette.teal),
                              onPressed: () => setS(() {
                                final idx = cartItems.indexWhere((c) => c.product.id == item.product.id);
                                cartItems[idx] = item.copyWith(quantity: item.quantity + 1);
                              }),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                          onPressed: () => setS(() => cartItems.removeWhere((c) => c.product.id == item.product.id)),
                        ),
                      ],
                    ),
                  )),
              ],
            ).animate().fadeIn();
          }

          Widget buildCustomerStep() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  maxLength: 10,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.phone), hintText: 'Enter 10-digit number', border: OutlineInputBorder(), counterText: ''),
                ),
                const SizedBox(height: 16),
                if (customerPhoneCtrl.text.length == 10) ...[
                  if (selectedParty != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: BrandPalette.mint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: BrandPalette.teal)),
                      child: Row(
                        children: [
                          const CircleAvatar(backgroundColor: BrandPalette.teal, child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedParty!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  'Balance: ₹${selectedParty!.balance.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: selectedParty!.balance >= 0 ? BrandPalette.teal : BrandPalette.coral),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: BrandPalette.teal),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0)
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('New Customer Details', style: TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.coral)),
                        const SizedBox(height: 12),
                        TextField(controller: customerNameCtrl, decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                        const SizedBox(height: 12),
                        TextField(controller: customerEmailCtrl, decoration: const InputDecoration(labelText: 'Email Address (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
                        const SizedBox(height: 12),
                        TextField(controller: customerGstCtrl, decoration: const InputDecoration(labelText: 'GSTIN (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business))),
                        const SizedBox(height: 12),
                        TextField(controller: customerAddressCtrl, decoration: const InputDecoration(labelText: 'Billing Address (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)), maxLines: 2),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                ],
              ],
            ).animate().fadeIn();
          }

          Widget buildPaymentStep() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loyalty & Discounts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: loyaltyPointsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Redeem Points', border: OutlineInputBorder(), prefixIcon: Icon(Icons.star, size: 16)))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.discount, size: 16)))),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Select Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                SegmentedButton<PaymentMode>(
                  segments: const [
                    ButtonSegment(value: PaymentMode.cash, label: Text('Cash'), icon: Icon(Icons.money, size: 14)),
                    ButtonSegment(value: PaymentMode.upi, label: Text('Online'), icon: Icon(Icons.qr_code_scanner, size: 14)),
                    ButtonSegment(value: PaymentMode.credit, label: Text('Dues'), icon: Icon(Icons.credit_card, size: 14)),
                  ],
                  selected: {paymentMode},
                  onSelectionChanged: (s) => setS(() => paymentMode = s.first),
                ),
              ],
            ).animate().fadeIn();
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(ctx).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.6,
              maxChildSize: 1.0,
              expand: false,
              builder: (ctx3, scroll) => Column(
                children: [
                  Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        if (_currentStep > 0)
                          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setS(() => _currentStep--))
                        else
                          const SizedBox(width: 48), // Spacer to balance
                        Expanded(
                          child: Text(
                            _currentStep == 0 ? '1. Add Items' : _currentStep == 1 ? '2. Customer Info' : '3. Payment', 
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  // Progress Bar
                  Row(
                    children: [
                      Expanded(child: Container(height: 3, color: BrandPalette.teal)),
                      Expanded(child: Container(height: 3, color: _currentStep >= 1 ? BrandPalette.teal : Colors.grey.shade200)),
                      Expanded(child: Container(height: 3, color: _currentStep >= 2 ? BrandPalette.teal : Colors.grey.shade200)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        if (_currentStep == 0) buildItemsStep(),
                        if (_currentStep == 1) buildCustomerStep(),
                        if (_currentStep == 2) buildPaymentStep(),
                      ],
                    ),
                  ),
                  // Bottom Bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: BrandPalette.teal)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _currentStep == 0 && cartItems.isEmpty ? Colors.grey : BrandPalette.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14)
                            ),
                            onPressed: (_currentStep == 0 && cartItems.isEmpty) ? null : () async {
                              if (_currentStep < 2) {
                                if (_currentStep == 1 && customerPhoneCtrl.text.length == 10 && selectedParty == null && customerNameCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter customer name'), backgroundColor: BrandPalette.coral));
                                  return;
                                }
                                setS(() => _currentStep++);
                              } else {
                                final disc = double.tryParse(discountCtrl.text) ?? 0.0;
                                final points = int.tryParse(loyaltyPointsCtrl.text) ?? 0;
                                final finalTotal = total - disc;

                                if (paymentMode == PaymentMode.upi) {
                                  final success = await _showDynamicQRDialog(context, finalTotal);
                                  if (!success) return; // Payment cancelled or failed
                                }

                                final invoice = InvoiceRecord(
                                  id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                                  createdAt: DateTime.now(),
                                  customerName: customerNameCtrl.text.trim().isEmpty ? 'Walk-in Customer' : customerNameCtrl.text.trim(),
                                  customerPhone: customerPhoneCtrl.text.trim(),
                                  customerEmail: customerEmailCtrl.text.trim(),
                                  customerGstin: customerGstCtrl.text.trim(),
                                  total: finalTotal,
                                  lines: List.from(cartItems),
                                  channels: const {},
                                  publicLink: widget.generateInvoiceLink?.call() ?? '',
                                  type: creatingType,
                                  paymentMode: paymentMode,
                                  loyaltyPointsUsed: points,
                                  discountAmount: disc,
                                );
                                widget.onCreateInvoice?.call(invoice);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Bill created successfully!'), backgroundColor: BrandPalette.teal),
                                );
                              }
                            },
                            child: Text(
                              _currentStep == 0 ? 'Next: Add Customer' : 
                              _currentStep == 1 ? 'Next: Payment' : 
                              paymentMode == PaymentMode.upi ? 'Generate Razorpay QR' : 'Confirm & Save Bill',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProductPicker(BuildContext context, List<Product> products, List<CartItem> cart, StateSetter setParentState) {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final filtered = products.where((p) {
            return p.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                   p.codes.any((c) => c.toLowerCase().contains(searchQuery.toLowerCase()));
          }).toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: FractionallySizedBox(
              heightFactor: 0.8,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Add Item to Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search or Scan Barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: BrandPalette.teal),
                        onPressed: () => _showScannerOverlay(ctx2, products, cart, setParentState),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('No items found', style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              final isOutOfStock = p.currentStock <= 0;
                              return ListTile(
                                leading: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: BrandPalette.navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.inventory_2, size: 20, color: BrandPalette.navy),
                                ),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('₹${p.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600)),
                                trailing: Text(
                                  isOutOfStock ? 'Out of Stock' : '${p.currentStock.toStringAsFixed(0)} in stock', 
                                  style: TextStyle(fontSize: 12, color: isOutOfStock ? Colors.red : BrandPalette.teal, fontWeight: FontWeight.w500)
                                ),
                                onTap: () {
                                  setParentState(() {
                                    final existing = cart.indexWhere((c) => c.product.id == p.id);
                                    if (existing >= 0) {
                                      cart[existing] = cart[existing].copyWith(quantity: cart[existing].quantity + 1);
                                    } else {
                                      cart.add(CartItem(product: p, quantity: 1));
                                    }
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showScannerOverlay(BuildContext context, List<Product> products, List<CartItem> cart, StateSetter setParentState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('Scan Barcode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final code = barcode.rawValue;
                      if (code != null) {
                        final product = products.where((p) => p.codes.contains(code)).firstOrNull;
                        if (product != null) {
                          setParentState(() {
                            final existing = cart.indexWhere((c) => c.product.id == product.id);
                            if (existing >= 0) {
                              cart[existing] = cart[existing].copyWith(quantity: cart[existing].quantity + 1);
                            } else {
                              cart.add(CartItem(product: product, quantity: 1));
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added ${product.name}'), backgroundColor: BrandPalette.teal, duration: 1.seconds),
                          );
                          return;
                        }
                      }
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Point camera at any product barcode', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDynamicQRDialog(BuildContext context, double amount) async {
    int timeLeft = 60;
    bool isSuccess = false;
    Timer? timer;
    
    // UPI Deep Link (Replace with actual business VPA)
    final String upiUrl = 'upi://pay?pa=priyes@upi&pn=${AppSettings.instance.businessName}&am=${amount.toStringAsFixed(2)}&cu=INR';

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (isSuccess) {
              t.cancel();
              return;
            }
            if (timeLeft > 0) {
              setS(() => timeLeft--);
            } else {
              t.cancel();
              Navigator.pop(ctx, false);
            }
          });

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isSuccess 
                ? Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 80).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 20),
                        const Text('Payment Received', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Razorpay Header Mock
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF02042B), // Razorpay Dark Blue
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.security, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            const Text('Secured by Razorpay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(AppSettings.instance.businessName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF02042B))),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                              ),
                              child: QrImageView(
                                data: upiUrl,
                                version: QrVersions.auto,
                                size: 180.0,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer, color: Colors.grey, size: 16),
                                const SizedBox(width: 6),
                                Text('QR Expires in $timeLeft s', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: OutlinedButton(onPressed: () { timer?.cancel(); Navigator.pop(ctx, false); }, child: const Text('Cancel'))),
                                const SizedBox(width: 12),
                                Expanded(child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3395FF)), // Razorpay Blue
                                  onPressed: () { 
                                    setS(() => isSuccess = true);
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (ctx.mounted) Navigator.pop(ctx, true);
                                    });
                                  }, 
                                  child: const Text('Mock Pay')
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          );
        },
      ),
    ) ?? false;
  }
}
