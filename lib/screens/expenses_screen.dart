import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/core.dart';
import '../enums/enums.dart';

class ExpensesScreen extends StatefulWidget {
  final List<ExpenseRecord> expenses;
  final void Function(ExpenseRecord)? onAddExpense;
  const ExpensesScreen({super.key, this.expenses = const [], this.onAddExpense});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late List<ExpenseRecord> _expenses;
  ReportPeriod _period = ReportPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    _expenses = List.from(widget.expenses.isEmpty ? [
      ExpenseRecord(id: '1', date: DateTime.now(), amount: 1500, category: ExpenseCategory.transport, paymentMode: PaymentMode.cash, note: 'Delivery charges'),
      ExpenseRecord(id: '2', date: DateTime.now().subtract(const Duration(days: 2)), amount: 8000, category: ExpenseCategory.rent, paymentMode: PaymentMode.upi, note: 'Monthly rent'),
      ExpenseRecord(id: '3', date: DateTime.now().subtract(const Duration(days: 5)), amount: 2200, category: ExpenseCategory.utilities, paymentMode: PaymentMode.cash, note: 'Electricity bill'),
    ] : widget.expenses);
  }

  double get totalExpenses => _expenses.fold(0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE97A63), Color(0xFFD4634D)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Expenses', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('₹${totalExpenses.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
                      Text('${_expenses.length} entries this period', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                // Period selector
                DropdownButton<ReportPeriod>(
                  value: _period,
                  dropdownColor: BrandPalette.coral,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: ReportPeriod.values.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.label, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (v) => setState(() => _period = v!),
                ),
              ],
            ),
          ),
          // Category breakdown chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: ExpenseCategory.values.map((cat) {
                final amount = _expenses.where((e) => e.category == cat).fold(0.0, (s, e) => s + e.amount);
                if (amount == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('${cat.icon} ${cat.label}: ₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ),
          // Expense list
          Expanded(
            child: _expenses.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No expenses recorded', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _expenses.length,
                  itemBuilder: (context, i) {
                    final exp = _expenses[i];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: BrandPalette.coral.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(exp.category.icon, style: const TextStyle(fontSize: 22))),
                        ),
                        title: Text(exp.category.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (exp.note.isNotEmpty) Text(exp.note, style: const TextStyle(fontSize: 12)),
                            Text(formatDate(exp.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${exp.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandPalette.coral)),
                            Text(exp.paymentMode.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context),
        backgroundColor: BrandPalette.coral,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    ExpenseCategory selectedCat = ExpenseCategory.other;
    PaymentMode selectedPayment = PaymentMode.cash;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder(), prefixText: '₹ ', prefixIcon: Icon(Icons.currency_rupee)),
              ),
              const SizedBox(height: 12),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = selectedCat == cat;
                  return GestureDetector(
                    onTap: () => setS(() => selectedCat = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? BrandPalette.coral : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? BrandPalette.coral : Colors.grey.shade300),
                      ),
                      child: Text('${cat.icon} ${cat.label}', style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              SegmentedButton<PaymentMode>(
                segments: const [
                  ButtonSegment(value: PaymentMode.cash, label: Text('Cash')),
                  ButtonSegment(value: PaymentMode.upi, label: Text('UPI')),
                  ButtonSegment(value: PaymentMode.credit, label: Text('Credit')),
                ],
                selected: {selectedPayment},
                onSelectionChanged: (s) => setS(() => selectedPayment = s.first),
              ),
              const SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Expense'),
                  style: FilledButton.styleFrom(backgroundColor: BrandPalette.coral, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    final amt = double.tryParse(amtCtrl.text) ?? 0;
                    if (amt <= 0) return;
                    final expense = ExpenseRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: DateTime.now(),
                      amount: amt,
                      category: selectedCat,
                      paymentMode: selectedPayment,
                      note: noteCtrl.text.trim(),
                    );
                    setState(() => _expenses.insert(0, expense));
                    widget.onAddExpense?.call(expense);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('₹${amt.toStringAsFixed(0)} expense saved!'), backgroundColor: BrandPalette.teal),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
