import 'package:flutter/material.dart';
import '../models/models.dart';
import '../enums/enums.dart';
import '../core/core.dart';

class KhataSection extends StatefulWidget {
  final List<PartyRecord> parties;
  final void Function(PartyRecord)? onPartyAdded;

  const KhataSection({super.key, this.parties = const [], this.onPartyAdded});

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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                final isToGet = party.balance > 0;
                final pColor = isToGet ? BrandPalette.teal : BrandPalette.coral;

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
                            backgroundColor: BrandPalette.navy.withValues(alpha: 0.1),
                            child: Text(party.name[0].toUpperCase(),
                              style: const TextStyle(color: BrandPalette.navy, fontWeight: FontWeight.bold, fontSize: 16)),
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
                                style: TextStyle(fontSize: 10, color: pColor)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // WhatsApp button
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('WhatsApp reminder sent to ${party.name}!'),
                                  backgroundColor: Colors.green),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
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
        builder: (context, scrollController) => _LedgerSheet(party: party, scrollController: scrollController),
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
  final ScrollController scrollController;

  const _LedgerSheet({required this.party, required this.scrollController});

  @override
  State<_LedgerSheet> createState() => _LedgerSheetState();
}

class _LedgerSheetState extends State<_LedgerSheet> {
  final List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    // Add opening balance as first transaction
    _transactions.add({'type': 'open', 'amount': widget.party.balance.abs(), 'date': DateTime.now().subtract(const Duration(days: 30)), 'note': 'Opening Balance'});
  }

  @override
  Widget build(BuildContext context) {
    final isToGet = widget.party.balance > 0;
    final color = isToGet ? BrandPalette.teal : BrandPalette.coral;

    return Column(
      children: [
        // Handle
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: BrandPalette.navy.withValues(alpha: 0.1),
                child: Text(widget.party.name[0], style: const TextStyle(color: BrandPalette.navy, fontWeight: FontWeight.bold, fontSize: 16))),
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
                    style: TextStyle(color: color, fontSize: 11)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: BrandPalette.teal, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _recordPayment(context, 'out'),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Payment Out'),
                  style: ElevatedButton.styleFrom(backgroundColor: BrandPalette.coral, foregroundColor: Colors.white),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _transactions.length,
            itemBuilder: (context, i) {
              final tx = _transactions[i];
              final isIn = tx['type'] == 'in' || tx['type'] == 'open';
              final txColor = isIn ? BrandPalette.teal : BrandPalette.coral;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: txColor.withValues(alpha: 0.1),
                  child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: txColor, size: 16),
                ),
                title: Text(tx['note'] ?? '', style: const TextStyle(fontSize: 14)),
                subtitle: Text(formatDate(tx['date']), style: const TextStyle(fontSize: 11)),
                trailing: Text('₹${tx['amount'].toStringAsFixed(0)}', style: TextStyle(color: txColor, fontWeight: FontWeight.bold)),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(direction == 'in' ? 'Record Payment In' : 'Record Payment Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: direction == 'in' ? BrandPalette.teal : BrandPalette.coral),
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt <= 0) return;
              setState(() {
                _transactions.insert(0, {
                  'type': direction,
                  'amount': amt,
                  'date': DateTime.now(),
                  'note': noteCtrl.text.isEmpty ? (direction == 'in' ? 'Payment Received' : 'Payment Sent') : noteCtrl.text,
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('₹${amt.toStringAsFixed(0)} recorded!'), backgroundColor: BrandPalette.teal),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
