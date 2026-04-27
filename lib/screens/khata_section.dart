import 'package:flutter/material.dart';
import 'dart:math';
import '../models/models.dart';
import '../enums/enums.dart';
import '../core/core.dart';
import 'package:url_launcher/url_launcher.dart';

class KhataSection extends StatefulWidget {
  final List<PartyRecord> parties;
  final List<InvoiceRecord> invoices;
  final void Function(PartyRecord)? onPartyAdded;

  const KhataSection({super.key, this.parties = const [], this.invoices = const [], this.onPartyAdded});

  @override
  State<KhataSection> createState() => _KhataSectionState();
}

class _KhataSectionState extends State<KhataSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _customerPage = 1;
  int _supplierPage = 1;
  static const int _pageSize = 20;

  List<PartyRecord> get _parties => widget.parties;

  double get totalToGet => _parties.where((p) => p.balance > 0).fold(0, (s, p) => s + p.balance);
  double get totalToGive => _parties.where((p) => p.balance < 0).fold(0, (s, p) => s + p.balance.abs());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Khata & Ledger'),
        elevation: 0,
        backgroundColor: BrandPalette.pageBase,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: BrandPalette.navy,
          labelColor: BrandPalette.navy,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'CUSTOMERS  ₹${totalToGet.toStringAsFixed(0)}'),
            Tab(text: 'SUPPLIERS  ₹${totalToGive.toStringAsFixed(0)}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPartyList(PartyType.customer),
          _buildPartyList(PartyType.supplier),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPartySheet(context),
        backgroundColor: BrandPalette.navy,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Party', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPartyList(PartyType type) {
    final parties = _parties.where((p) => p.type == type).toList();
    final total = type == PartyType.customer ? totalToGet : totalToGive;
    final color = type == PartyType.customer ? BrandPalette.teal : BrandPalette.coral;
    final label = type == PartyType.customer ? 'You will get' : 'You will give';

    return Column(
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total $label', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text('₹${total.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
            ],
          ),
        ),
        if (parties.isEmpty)
          const Expanded(child: Center(child: Text('No parties added yet.')))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 80),
              itemCount: parties.take((type == PartyType.customer ? _customerPage : _supplierPage) * _pageSize).length + (parties.length > (type == PartyType.customer ? _customerPage : _supplierPage) * _pageSize ? 1 : 0),
              itemBuilder: (context, index) {
                final paginated = parties.take((type == PartyType.customer ? _customerPage : _supplierPage) * _pageSize).toList();
                
                if (index == paginated.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          if (type == PartyType.customer) _customerPage++;
                          else _supplierPage++;
                        }),
                        icon: const Icon(Icons.expand_more),
                        label: Text('Load more (${parties.length - paginated.length} remaining)'),
                      ),
                    ),
                  );
                }

                final party = paginated[index];
                final isToGet = party.balance > 0;
                final pColor = isToGet ? const Color(0xFF0DAB76) : const Color(0xFFE05252);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    onTap: () => _openLedger(context, party),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF1A6FE3).withOpacity(0.08),
                            child: Text(party.name[0].toUpperCase(),
                              style: const TextStyle(color: Color(0xFF1A6FE3), fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(party.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${party.balance.abs().toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: pColor)),
                              Text(isToGet ? 'To Get' : 'To Give',
                                style: TextStyle(fontSize: 10, color: pColor, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // WhatsApp button
                          InkWell(
                            onTap: () {
                              if (party.phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone number missing!'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              final String text = isToGet 
                                ? 'Namaste ${party.name}, a friendly reminder from ${AppSettings.instance.businessName} regarding your pending balance of ₹${party.balance.abs().toStringAsFixed(0)}. Please settle it at your earliest convenience. Thank you!'
                                : 'Namaste ${party.name}, this is regarding the balance of ₹${party.balance.abs().toStringAsFixed(0)} we owe you. We are processing it. Thank you!';
                              final Uri whatsappUri = Uri.parse('https://wa.me/91${party.phone}?text=${Uri.encodeComponent(text)}');
                              launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chat, color: Colors.green, size: 18),
                            ),
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
    );
  }

  void _openLedger(BuildContext context, PartyRecord party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _LedgerSheet(party: party, parties: widget.parties, invoices: widget.invoices, scrollController: scrollController),
      ),
    );
  }

  void _showAddPartySheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    PartyType selectedType = PartyType.customer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Party', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SegmentedButton<PartyType>(
                  segments: const [
                    ButtonSegment(value: PartyType.customer, label: Text('Customer'), icon: Icon(Icons.person)),
                    ButtonSegment(value: PartyType.supplier, label: Text('Supplier'), icon: Icon(Icons.store)),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) => setModalState(() => selectedType = s.first),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: balanceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(
                  labelText: selectedType == PartyType.customer ? 'Opening Balance (To Get)' : 'Opening Balance (To Give)',
                  border: const OutlineInputBorder(),
                  prefixText: '₹ ',
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final bal = double.tryParse(balanceCtrl.text) ?? 0.0;
                      final party = PartyRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        type: selectedType,
                        balance: selectedType == PartyType.customer ? bal : -bal,
                      );
                      setState(() => _parties.add(party));
                      widget.onPartyAdded?.call(party);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${party.name} added to Khata!'), backgroundColor: BrandPalette.teal),
                      );
                    },
                    child: const Text('Add Party'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Ledger Detail Sheet ---
class _LedgerSheet extends StatefulWidget {
  final PartyRecord party;
  final List<PartyRecord> parties;
  final List<InvoiceRecord> invoices;
  final ScrollController scrollController;

  const _LedgerSheet({required this.party, required this.parties, required this.invoices, required this.scrollController});

  @override
  State<_LedgerSheet> createState() => _LedgerSheetState();
}

class _LedgerSheetState extends State<_LedgerSheet> {
  final List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    // 1. Add opening balance
    _transactions.add({'type': 'open', 'amount': widget.party.balance.abs(), 'date': DateTime.now().subtract(const Duration(days: 30)), 'note': 'Opening Balance', 'invoice': null});
    
    // 2. Add invoices related to this party
    final partyInvoices = widget.invoices.where((i) => i.customerPhone == widget.party.phone || i.customerName == widget.party.name).toList();
    for (var inv in partyInvoices) {
      final isIn = widget.party.type == PartyType.supplier; // If supplier gave us bill, we owe them (in). If we gave customer bill, they owe us (in).
      // Wait, standard accounting: Sale to customer increases their balance (they owe us). Purchase from supplier increases our debt.
      // Let's just log the invoice.
      _transactions.add({
        'type': widget.party.type == PartyType.customer ? 'sale' : 'purchase',
        'amount': inv.total,
        'date': inv.createdAt,
        'note': 'Bill #${inv.id.substring(max(0, inv.id.length - 6))}',
        'invoice': inv,
      });
      // If payment was made on the bill, log the payment
      if (inv.paymentMode != PaymentMode.credit) {
        _transactions.add({
          'type': widget.party.type == PartyType.customer ? 'in' : 'out',
          'amount': inv.total,
          'date': inv.createdAt,
          'note': 'Payment for Bill #${inv.id.substring(max(0, inv.id.length - 6))} (${inv.paymentMode.name.toUpperCase()})',
          'invoice': null,
        });
      }
    }
    
    // 3. Sort by date descending
    _transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  @override
  Widget build(BuildContext context) {
    final isToGet = widget.party.balance > 0;
    final color = isToGet ? const Color(0xFF0DAB76) : const Color(0xFFE05252);

    return Column(
      children: [
        // Handle
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: const Color(0xFF1A6FE3).withOpacity(0.08),
                child: Text(widget.party.name[0], style: const TextStyle(color: Color(0xFF1A6FE3), fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.party.phone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${widget.party.balance.abs().toStringAsFixed(0)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(isToGet ? 'You will get' : 'You will give',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _recordPayment(context, 'in'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Payment In'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0DAB76), foregroundColor: Colors.white, elevation: 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _recordPayment(context, 'out'),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Payment Out'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE05252), foregroundColor: Colors.white, elevation: 0),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 24),
        // Transaction list
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _transactions.length,
            reverse: true, // Chat lists usually start from bottom
            itemBuilder: (context, i) {
              final tx = _transactions[i];
              final type = tx['type'] as String;
              
              // Logic for "You Gave" (Red, Left) vs "You Got" (Green, Right)
              final isYouGot = type == 'in' || type == 'purchase' || (type == 'open' && widget.party.balance < 0);
              final isYouGave = type == 'out' || type == 'sale' || (type == 'open' && widget.party.balance >= 0);
              
              final isRightSide = isYouGot; // "You Got" on right, "You Gave" on left
              final bubbleColor = isYouGot ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE); // Light green vs Light red
              final textColor = isYouGot ? const Color(0xFF2E7D32) : const Color(0xFFC62828); // Dark green vs Dark red
              
              final invoice = tx['invoice'] as InvoiceRecord?;
              
              String actionText = isYouGot ? 'You Got' : 'You Gave';
              if (type == 'sale') actionText = 'Dues Added (Bill)';
              if (type == 'purchase') actionText = 'Bill Added';

              return Align(
                alignment: isRightSide ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: InkWell(
                    onTap: invoice != null ? () {
                      // Navigate to invoice detail in the future
                    } : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isRightSide ? const Radius.circular(4) : const Radius.circular(16),
                          bottomLeft: !isRightSide ? const Radius.circular(4) : const Radius.circular(16),
                        ),
                        border: Border.all(color: textColor.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isYouGot ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: textColor),
                              const SizedBox(width: 4),
                              Text(actionText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('₹${tx['amount'].toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                          const SizedBox(height: 6),
                          if (tx['note'] != null && tx['note'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
                              child: Text(tx['note'], style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                            ),
                          if (invoice != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long, size: 12, color: textColor.withValues(alpha: 0.8)),
                                const SizedBox(width: 4),
                                Text('View Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.8))),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(formatDate(tx['date']), style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _recordPayment(BuildContext context, String direction) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    PaymentMode selectedMode = PaymentMode.cash;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx2, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(direction == 'in' ? 'Record Payment In' : 'Record Payment Out', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: amtCtrl, 
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 16),
              Text('Payment Mode', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<PaymentMode>(
                segments: const [
                  ButtonSegment(value: PaymentMode.cash, label: Text('Cash'), icon: Icon(Icons.money)),
                  ButtonSegment(value: PaymentMode.upi, label: Text('UPI'), icon: Icon(Icons.qr_code_scanner)),
                  ButtonSegment(value: PaymentMode.bankTransfer, label: Text('Bank'), icon: Icon(Icons.account_balance)),
                ],
                selected: {selectedMode},
                onSelectionChanged: (s) => setModalState(() => selectedMode = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF1A6FE3).withOpacity(0.1),
                  selectedForegroundColor: const Color(0xFF1A6FE3),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl, 
                decoration: InputDecoration(
                  labelText: 'Note (optional)', 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: direction == 'in' ? const Color(0xFF0DAB76) : const Color(0xFFE05252),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final amt = double.tryParse(amtCtrl.text) ?? 0;
                    if (amt <= 0) return;
                    setState(() {
                      _transactions.insert(0, {
                        'type': direction,
                        'amount': amt,
                        'date': DateTime.now(),
                        'note': noteCtrl.text.isEmpty ? (direction == 'in' ? 'Payment Received' : 'Payment Sent') : noteCtrl.text,
                        'invoice': null,
                      });
                      // Update party balance
                      final idx = widget.parties.indexWhere((p) => p.id == widget.party.id);
                      if (idx != -1) {
                        final newBalance = widget.party.balance + (direction == 'in' ? -amt : amt);
                        widget.parties[idx] = widget.party.copyWith(balance: newBalance);
                      }
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('₹${amt.toStringAsFixed(0)} recorded!'), backgroundColor: const Color(0xFF0DAB76)),
                    );
                  },
                  child: const Text('Save Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
