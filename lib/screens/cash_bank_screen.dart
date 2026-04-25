import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/core.dart';

class CashBankScreen extends StatefulWidget {
  const CashBankScreen({super.key});
  @override
  State<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends State<CashBankScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<BankAccount> _accounts = [
    const BankAccount(id: '1', bankName: 'State Bank of India', accountNumber: '****4521', ifscCode: 'SBIN0001234', accountHolderName: 'My Business', currentBalance: 45000),
    const BankAccount(id: '2', bankName: 'HDFC Bank', accountNumber: '****9873', ifscCode: 'HDFC0001234', accountHolderName: 'My Business', currentBalance: 12500),
  ];

  double _cashInHand = 3500.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Cash & Bank'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: BrandPalette.navy,
          labelColor: BrandPalette.navy,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Bank Accounts'),
            Tab(text: 'Cash In-Hand'),
            Tab(text: 'Cheques'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBankAccounts(),
          _buildCashInHand(),
          _buildCheques(),
        ],
      ),
    );
  }

  Widget _buildBankAccounts() {
    final total = _accounts.fold(0.0, (s, a) => s + a.currentBalance);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [BrandPalette.navy, Color(0xFF1D5070)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Bank Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
                Text('${_accounts.length} accounts', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ])),
              const Icon(Icons.account_balance, color: Colors.white54, size: 36),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: _accounts.length,
            itemBuilder: (ctx, i) {
              final acc = _accounts[i];
              return Card(
                elevation: 0, margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: BrandPalette.navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.account_balance, color: BrandPalette.navy),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(acc.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${acc.accountNumber} • ${acc.ifscCode}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ])),
                      Text('₹${acc.currentBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: BrandPalette.teal)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCashInHand() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [BrandPalette.teal, Color(0xFF15A89E)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Icon(Icons.wallet, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text('Cash In-Hand', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('₹${_cashInHand.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _adjustCash(context, true),
              icon: const Icon(Icons.add),
              label: const Text('Cash In'),
              style: ElevatedButton.styleFrom(backgroundColor: BrandPalette.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _adjustCash(context, false),
              icon: const Icon(Icons.remove),
              label: const Text('Cash Out'),
              style: ElevatedButton.styleFrom(backgroundColor: BrandPalette.coral, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildCheques() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('Cheque Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('Track received and issued cheques', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Cheque'),
          style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy),
        ),
      ]),
    );
  }

  void _adjustCash(BuildContext context, bool isIn) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIn ? 'Cash In' : 'Cash Out'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isIn ? BrandPalette.teal : BrandPalette.coral),
            onPressed: () {
              final amt = double.tryParse(ctrl.text) ?? 0;
              if (amt > 0) {
                setState(() => _cashInHand += isIn ? amt : -amt);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
