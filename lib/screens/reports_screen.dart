import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/core.dart';
import '../enums/enums.dart';

class ReportsScreen extends StatefulWidget {
  final List<InvoiceRecord> invoices;
  final List<ExpenseRecord> expenses;
  final List<Product> products;
  const ReportsScreen({super.key, this.invoices = const [], this.expenses = const [], this.products = const []});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  int _selectedReport = 0;

  final List<Map<String, dynamic>> _reportTypes = [
    {'icon': Icons.trending_up, 'title': 'Sales Report', 'color': const Color(0xFF1F8A86)},
    {'icon': Icons.account_balance, 'title': 'Profit & Loss', 'color': const Color(0xFF14344A)},
    {'icon': Icons.receipt, 'title': 'GST Report', 'color': const Color(0xFFF1B15C)},
    {'icon': Icons.inventory, 'title': 'Stock Summary', 'color': const Color(0xFF6B4EFF)},
  ];

  double get totalSales => widget.invoices.fold(0, (s, i) => s + i.total);
  double get totalExpenses => widget.expenses.fold(0, (s, e) => s + e.amount);
  double get profit => totalSales - totalExpenses;
  double get totalTax => widget.invoices.fold(0, (s, i) => s + i.totalTaxAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          DropdownButton<ReportPeriod>(
            value: _period,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.arrow_drop_down),
            items: ReportPeriod.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _period = v!),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: _reportTypes.asMap().entries.map((entry) {
                final isSelected = _selectedReport == entry.key;
                final report = entry.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReport = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? report['color'] as Color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? report['color'] as Color : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(report['icon'] as IconData, size: 14, color: isSelected ? Colors.white : Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(report['title'] as String, style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(child: _buildSelectedReport()),
        ],
      ),
    );
  }

  Widget _buildSelectedReport() {
    switch (_selectedReport) {
      case 0: return _buildSalesReport();
      case 1: return _buildProfitLossReport();
      case 2: return _buildGstReport();
      case 3: return _buildStockSummaryReport();
      default: return _buildSalesReport();
    }
  }

  Widget _buildSalesReport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statRow([
          _statCard('Total Sales', '₹${totalSales.toStringAsFixed(0)}', BrandPalette.teal, Icons.trending_up),
          _statCard('Total Bills', '${widget.invoices.length}', BrandPalette.navy, Icons.receipt_long),
        ]),
        const SizedBox(height: 12),
        _statRow([
          _statCard('Avg Bill Value', widget.invoices.isEmpty ? '₹0' : '₹${(totalSales / widget.invoices.length).toStringAsFixed(0)}', Colors.purple, Icons.analytics),
          _statCard('Tax Collected', '₹${totalTax.toStringAsFixed(0)}', BrandPalette.sun, Icons.percent),
        ]),
        const SizedBox(height: 16),
        if (widget.invoices.isEmpty)
          _emptyState('No sales data', 'Create bills to see sales reports')
        else ...[
          const Text('Recent Sales', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...widget.invoices.take(10).map((inv) => _transactionTile(inv.customerName, formatDate(inv.createdAt), '₹${inv.total.toStringAsFixed(0)}', BrandPalette.teal, Icons.arrow_downward)),
        ],
      ],
    );
  }

  Widget _buildProfitLossReport() {
    final isProfit = profit >= 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isProfit ? [BrandPalette.teal, const Color(0xFF15A89E)] : [BrandPalette.coral, const Color(0xFFD4634D)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Text(isProfit ? 'Net Profit' : 'Net Loss', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text('₹${profit.abs().toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36)),
            Text('For ${_period.label}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        _statRow([
          _statCard('Total Revenue', '₹${totalSales.toStringAsFixed(0)}', BrandPalette.teal, Icons.arrow_downward),
          _statCard('Total Expenses', '₹${totalExpenses.toStringAsFixed(0)}', BrandPalette.coral, Icons.arrow_upward),
        ]),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(children: [
            _plRow('Gross Revenue', totalSales, false),
            _plRow('Total Expenses', totalExpenses, true),
            const Divider(),
            _plRow(isProfit ? 'Net Profit' : 'Net Loss', profit.abs(), !isProfit, isBold: true),
          ]),
        ),
      ],
    );
  }

  Widget _buildGstReport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statRow([
          _statCard('Total Tax', '₹${totalTax.toStringAsFixed(0)}', BrandPalette.sun, Icons.percent),
          _statCard('CGST', '₹${(totalTax / 2).toStringAsFixed(0)}', Colors.orange, Icons.receipt),
        ]),
        const SizedBox(height: 12),
        _statRow([
          _statCard('SGST', '₹${(totalTax / 2).toStringAsFixed(0)}', Colors.deepOrange, Icons.receipt),
          _statCard('IGST', '₹0', Colors.red, Icons.receipt_long),
        ]),
        const SizedBox(height: 16),
        if (widget.invoices.isEmpty)
          _emptyState('No GST Data', 'Create GST-enabled bills to see this report'),
      ],
    );
  }

  Widget _buildStockSummaryReport() {
    final lowStock = widget.products.where((p) => p.currentStock <= p.lowStockAlertLevel && p.lowStockAlertLevel > 0).toList();
    final outOfStock = widget.products.where((p) => p.currentStock <= 0).toList();
    final totalStockValue = widget.products.fold(0.0, (s, p) => s + (p.price * p.currentStock));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statRow([
          _statCard('Total Items', '${widget.products.length}', BrandPalette.navy, Icons.inventory_2),
          _statCard('Stock Value', '₹${totalStockValue.toStringAsFixed(0)}', BrandPalette.teal, Icons.monetization_on),
        ]),
        const SizedBox(height: 12),
        _statRow([
          _statCard('Low Stock', '${lowStock.length}', BrandPalette.coral, Icons.warning_amber),
          _statCard('Out of Stock', '${outOfStock.length}', Colors.red, Icons.remove_circle_outline),
        ]),
        const SizedBox(height: 16),
        if (lowStock.isNotEmpty) ...[
          const Text('⚠️ Low Stock Items', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lowStock.map((p) => _transactionTile(p.name, '${p.currentStock.toStringAsFixed(0)} remaining', '₹${p.price}', BrandPalette.coral, Icons.inventory_2)),
        ],
      ],
    );
  }

  Widget _statRow(List<Widget> children) {
    return Row(children: [Expanded(child: children[0]), const SizedBox(width: 12), Expanded(child: children[1])]);
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Flexible(child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)))]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
      ]),
    );
  }

  Widget _transactionTile(String title, String subtitle, String amount, Color color, IconData icon) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  Widget _plRow(String label, double amount, bool isNegative, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 15 : 14)),
        Text('${isNegative ? '-' : ''}₹${amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 16 : 14, color: isNegative ? BrandPalette.coral : BrandPalette.teal)),
      ]),
    );
  }

  Widget _emptyState(String title, String subtitle) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.bar_chart, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
    ]),
  );
}
