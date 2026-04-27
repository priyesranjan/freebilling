import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../core/core.dart';
import '../enums/enums.dart';
import 'reports_screen.dart';
import 'website_preview_screen.dart';
import 'all_transactions_screen.dart';
import 'live_support_screen.dart';

class HomeSection extends StatelessWidget {
  final List<BusinessRecord> businesses;
  final List<Product> products;
  final List<InvoiceRecord> invoices;
  final List<PartyRecord> parties;
  final List<ExpenseRecord> expenses;
  final VoidCallback? onAddSale;
  final void Function(AppSection)? onSwitchTab;
  final VoidCallback? onViewExpenses;

  const HomeSection({
    super.key,
    required this.businesses,
    required this.products,
    required this.invoices,
    this.parties = const [],
    this.expenses = const [],
    this.onAddSale,
    this.onSwitchTab,
    this.onViewExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100), // Space for FAB
        children: [
          // Quick Links Card
          _buildQuickLinksCard(context),

          // Financial Health Cards
          _buildFinancialCards(context),

          // Sales Graph
          _buildSalesGraph(context),

          // Top Selling Products
          _buildTopProducts(context),

          // Recent Transactions Header
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
            child: Text('Recent Transactions', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          ),

          // Recent Transactions List
          ..._buildRecentTransactions(context),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddSale,
        backgroundColor: const Color(0xFFEF4444),
        icon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.currency_rupee, color: Colors.white, size: 14),
        ),
        label: const Text('Add New Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickLinksCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Links', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickLinkIcon(context, 'Sales Report', Icons.bar_chart_rounded, const Color(0xFF10B981), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen(invoices: invoices, expenses: expenses, products: products)));
              }),
              _quickLinkIcon(context, 'Add Expense', Icons.account_balance_wallet_rounded, const Color(0xFFEF4444), () => onViewExpenses?.call()),
              _quickLinkIcon(context, 'My Website', Icons.language_rounded, const Color(0xFF3B82F6), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WebsitePreviewScreen()));
              }),
              _quickLinkIcon(context, 'Show All', Icons.apps_rounded, const Color(0xFF8B5CF6), () => _showAllBottomSheet(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickLinkIcon(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 48,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFF334155)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAllBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('All Tools', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              children: [
                _bskIcon(context, 'All Txns', Icons.list_alt, Colors.blue, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AllTransactionsScreen(invoices: invoices, expenses: expenses)));
                }),
                _bskIcon(context, 'Today Sales', Icons.today, Colors.green, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen(invoices: invoices, expenses: expenses, products: products)));
                }),
                _bskIcon(context, 'Profile', Icons.person, Colors.orange, () {
                  Navigator.pop(context);
                  onSwitchTab?.call(AppSection.menu);
                }),
                _bskIcon(context, 'Google Biz', Icons.storefront, Colors.deepPurple, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Business sync coming soon!')));
                }),
                _bskIcon(context, 'Live Support', Icons.headset_mic, Colors.red, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveSupportScreen()));
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _bskIcon(BuildContext context, String label, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(backgroundColor: color.shade50, radius: 24, child: Icon(icon, color: color.shade600)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildFinancialCards(BuildContext context) {
    final double toGet = parties.where((p) => p.balance > 0).fold(0.0, (s, p) => s + p.balance);
    final double toGive = parties.where((p) => p.balance < 0).fold(0.0, (s, p) => s + p.balance.abs());
    final double monthExpenses = expenses.fold(0.0, (s, e) => s + e.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khata Book', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('You Get', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                        Text('₹${toGet.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('You Give', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                        Text('₹${toGive.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                      ]),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Expenses', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('₹${monthExpenses.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesGraph(BuildContext context) {
    // Generate dummy data or real data for the last 7 days
    final now = DateTime.now();
    final List<double> dailySales = List.filled(7, 0.0);
    for (var inv in invoices) {
      final diff = now.difference(inv.createdAt).inDays;
      if (diff >= 0 && diff < 7) {
        dailySales[6 - diff] += inv.total;
      }
    }

    final maxY = (dailySales.fold<double>(0.0, (m, v) => v > m ? v : m) * 1.2).clamp(100.0, double.infinity);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 16, 10, 16),
      padding: const EdgeInsets.all(14),
      height: 220,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales Overview (7 Days)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4, getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final date = now.subtract(Duration(days: 6 - v.toInt()));
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${date.day}/${date.month}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))));
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6, minY: 0, maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7, (i) => FlSpot(i.toDouble(), dailySales[i])),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF3B82F6).withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context) {
    if (invoices.isEmpty) return const SizedBox.shrink();

    // Calculate top selling products
    Map<String, int> productSales = {};
    for (var inv in invoices) {
      for (var line in inv.lines) {
        productSales[line.product.name] = (productSales[line.product.name] ?? 0) + line.quantity;
      }
    }
    var sortedProducts = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top3 = sortedProducts.take(3).toList();

    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Selling Items', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          ...top3.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(entry.key, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF334155)), overflow: TextOverflow.ellipsis)),
                Text('${entry.value} Sold', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Widget> _buildRecentTransactions(BuildContext context) {
    if (invoices.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('No recent transactions.', style: TextStyle(color: Colors.grey.shade500)),
          ),
        )
      ];
    }

    final recent = invoices.take(10).toList();
    return recent.map((inv) => _buildTransactionCard(inv)).toList();
  }

  Widget _buildTransactionCard(InvoiceRecord inv) {
    final bool isCredit = inv.paymentMode == PaymentMode.credit;
    // In our app, we use PartyRecord for balance. Let's find the party if they exist.
    final party = parties.where((p) => p.name == inv.customerName || p.phone == inv.customerPhone).firstOrNull;
    final double balance = party?.balance.abs() ?? (isCredit ? inv.total : 0.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Name and ID/Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  inv.customerName.isEmpty ? 'Walk-in Customer' : inv.customerName,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('#${inv.id.substring(inv.id.length > 5 ? inv.id.length - 5 : 0)}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  Text(formatDate(inv.createdAt), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Tag Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('SALE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
          ),
          const SizedBox(height: 16),

          // Bottom Row: Total, Balance, Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  Text('₹ ${inv.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  Text('₹ ${balance.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.print_outlined, size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 16),
                  const Icon(Icons.share_outlined, size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class BrandedBackdrop extends StatelessWidget {
  const BrandedBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
