import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../core/core.dart';

class HomeSection extends StatelessWidget {
  final List<BusinessRecord> businesses;
  final List<Product> products;
  final List<InvoiceRecord> invoices;
  final List<PartyRecord> parties;
  final List<ExpenseRecord> expenses;
  final VoidCallback? onAddSale;

  const HomeSection({
    super.key,
    required this.businesses,
    required this.products,
    required this.invoices,
    this.parties = const [],
    this.expenses = const [],
    this.onAddSale,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate live totals from real data
    final double toGet = parties
        .where((p) => p.balance > 0)
        .fold(0.0, (sum, p) => sum + p.balance);
    final double toGive = parties
        .where((p) => p.balance < 0)
        .fold(0.0, (sum, p) => sum + p.balance.abs());

    final double todaySales = invoices
        .where((i) => isSameDate(i.createdAt, DateTime.now()))
        .fold(0.0, (sum, i) => sum + i.total);

    final double totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final double stockValue = products.fold(0.0, (sum, p) => sum + (p.price * p.currentStock));
    final double netProfit = todaySales - (totalExpenses / 30); // Rough estimate for dashboard

    final int lowStockCount =
        products.where((p) => p.currentStock <= p.lowStockAlertLevel && p.lowStockAlertLevel > 0).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's sales banner
          _buildTodayBanner(context, todaySales, lowStockCount),
          const SizedBox(height: 16),
          // Business Pulse & Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Analytics', style: Theme.of(context).textTheme.titleMedium),
              const Icon(Icons.show_chart, color: BrandPalette.teal, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          _buildPulseCards(context, netProfit, stockValue, totalExpenses),
          const SizedBox(height: 16),
          _buildSalesChart(context),
          const SizedBox(height: 24),
          // Khata summary
          Text('Khata Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildSummaryCards(context, toGive, toGet),
          const SizedBox(height: 24),
          // Quick actions
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          // Recent transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
              if (invoices.isNotEmpty)
                Text('${invoices.length} bills', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecentTransactions(context),
        ],
      ),
    );
  }

  Widget _buildPulseCards(BuildContext context, double profit, double stock, double expense) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPulseCard(context, 'Net Profit', profit, profit >= 0 ? BrandPalette.teal : BrandPalette.coral, Icons.trending_up),
          const SizedBox(width: 12),
          _buildPulseCard(context, 'Stock Value', stock, BrandPalette.navy, Icons.inventory_2),
          const SizedBox(width: 12),
          _buildPulseCard(context, 'Total Expenses', expense, BrandPalette.coral, Icons.account_balance_wallet),
        ],
      ),
    );
  }

  Widget _buildPulseCard(BuildContext context, String title, double amount, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: BrandPalette.navy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
                  Widget text;
                  switch (value.toInt()) {
                    case 0: text = const Text('Mon', style: style); break;
                    case 2: text = const Text('Wed', style: style); break;
                    case 4: text = const Text('Fri', style: style); break;
                    case 6: text = const Text('Sun', style: style); break;
                    default: text = const Text('', style: style); break;
                  }
                  return SideTitleWidget(meta: meta, child: text);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(value == 0 ? '0' : '${value.toInt()}k', style: const TextStyle(color: Colors.grey, fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 5,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 1),
                FlSpot(1, 1.5),
                FlSpot(2, 1.4),
                FlSpot(3, 3.4),
                FlSpot(4, 2),
                FlSpot(5, 2.2),
                FlSpot(6, 4.5),
              ],
              isCurved: true,
              color: BrandPalette.teal,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: BrandPalette.teal.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayBanner(BuildContext context, double todaySales, int lowStockCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandPalette.navy, Color(0xFF1D5070)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Sales", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '₹${todaySales.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (lowStockCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: BrandPalette.coral.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('$lowStockCount Low Stock', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, double toGive, double toGet) {
    return Row(
      children: [
        Expanded(child: _buildCard(context, 'To Give', toGive, BrandPalette.coral, Icons.arrow_upward)),
        const SizedBox(width: 16),
        Expanded(child: _buildCard(context, 'To Get', toGet, BrandPalette.teal, Icons.arrow_downward)),
      ],
    );
  }

  Widget _buildCard(BuildContext context, String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: BrandPalette.ink, fontSize: 24),
          ),
          if (amount == 0)
            Text('All clear! 🎉', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionButton(context, Icons.add_shopping_cart, 'Add Sale', BrandPalette.navy, onAddSale)),
        Expanded(child: _buildActionButton(context, Icons.inventory_2, 'Add Purchase', BrandPalette.teal, null)),
        Expanded(child: _buildActionButton(context, Icons.account_balance_wallet, 'Add Expense', BrandPalette.coral, null)),
        Expanded(child: _buildActionButton(context, Icons.people, 'Add Party', BrandPalette.sun, null)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label coming soon!'), duration: const Duration(seconds: 1)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    if (invoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text('No transactions yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Tap "Add Sale" to create your first bill!', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    final recent = invoices.take(5).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final inv = recent[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: BrandPalette.mint,
              child: Text(
                inv.customerName.isNotEmpty ? inv.customerName[0].toUpperCase() : '?',
                style: const TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(inv.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(formatDate(inv.createdAt), style: const TextStyle(fontSize: 11)),
            trailing: Text(
              '₹${inv.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.teal, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
