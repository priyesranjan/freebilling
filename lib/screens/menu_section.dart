import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/core.dart';
import 'settings_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'cash_bank_screen.dart';

class MenuSection extends StatefulWidget {
  final List<InvoiceRecord> invoices;
  final List<ExpenseRecord> expenses;
  final List<Product> products;
  final Function(ExpenseRecord) onAddExpense;
  final Function(AppSettings) onUpdateSettings;

  const MenuSection({
    super.key,
    required this.invoices,
    required this.expenses,
    required this.products,
    required this.onAddExpense,
    required this.onUpdateSettings,
  });

  @override
  State<MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<MenuSection> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      body: ListView(
        children: [
          // ── Profile Header ──────────────────────────────────────────
          _buildProfileHeader(context, settings),

          // ── My Business ─────────────────────────────────────────────
          _sectionCard('My Business', [
            _expandableTile(
              context, 'sale', Icons.currency_rupee_outlined, 'Sale', children: [
                _subItem(context, Icons.receipt_long, 'Sale Invoice', () => _pushTab(context, 2)),
                _subItem(context, Icons.description_outlined, 'Sale Order', () {}),
                _subItem(context, Icons.note_outlined, 'Estimate / Quotation', () {}),
                _subItem(context, Icons.undo, 'Sale Return', () {}),
              ],
            ),
            _divider(),
            _expandableTile(
              context, 'purchase', Icons.shopping_cart_outlined, 'Purchase', children: [
                _subItem(context, Icons.receipt, 'Purchase Bill', () {}),
                _subItem(context, Icons.shopping_bag_outlined, 'Purchase Order', () {}),
                _subItem(context, Icons.undo, 'Purchase Return', () {}),
              ],
            ),
            _divider(),
            _navTile(context, Icons.account_balance_wallet_outlined, 'Expenses', null,
              () => _push(context, ExpensesScreen(expenses: widget.expenses, onAddExpense: widget.onAddExpense))),
            _divider(),
            _navTile(context, Icons.storefront_outlined, 'My Online Store', null, () => _showComingSoon(context, 'Online Store')),
            _divider(),
            _navTile(context, Icons.bar_chart_outlined, 'Reports', null,
              () => _push(context, ReportsScreen(invoices: widget.invoices, expenses: widget.expenses, products: widget.products))),
          ]),

          // ── Cash & Bank ─────────────────────────────────────────────
          _sectionCard('Cash & Bank', [
            _navTile(context, Icons.account_balance_outlined, 'Bank Accounts', null, () => _push(context, const CashBankScreen())),
            _divider(),
            _navTile(context, Icons.wallet_outlined, 'Cash In-Hand', null, () => _push(context, const CashBankScreen())),
            _divider(),
            _navTile(context, Icons.credit_card_outlined, 'Cheques', null, () => _push(context, const CashBankScreen())),
            _divider(),
            _navTile(context, Icons.percent_outlined, 'Loan Accounts', null, () => _showComingSoon(context, 'Loan Accounts')),
          ]),

          // ── Important Utilities ─────────────────────────────────────
          _sectionCard('Important Utilities', [
            _navTile(context, Icons.sync, 'Sync & Share', null, () => _showComingSoon(context, 'Sync & Share')),
            _divider(),
            _navTile(context, Icons.business_outlined, 'Manage Companies', null, () => _showComingSoon(context, 'Manage Companies')),
            _divider(),
            _expandableTile(context, 'backup', Icons.backup_outlined, 'Backup/Restore', children: [
              _subItem(context, Icons.cloud_upload_outlined, 'Backup to Cloud', () {}),
              _subItem(context, Icons.cloud_download_outlined, 'Restore from Cloud', () {}),
              _subItem(context, Icons.phone_android, 'Local Backup', () {}),
            ]),
            _divider(),
            _expandableTile(context, 'utilities', Icons.build_outlined, 'Utilities', isNew: true, children: [
              _subItem(context, Icons.qr_code, 'Print Barcodes', () {}),
              _subItem(context, Icons.upload_file, 'Import Items (Excel)', () {}),
              _subItem(context, Icons.download, 'Export Data', () {}),
            ]),
          ]),

          // ── Others ──────────────────────────────────────────────────
          _sectionCard('Others', [
            _navTile(context, Icons.star_outline, 'Plans & Pricing', null,
              () => _showPlansDialog(context)),
            _divider(),
            _navTile(context, Icons.computer, 'Get Desktop Billing Software', null,
              () => _showComingSoon(context, 'Desktop Software'), badge: '🔴'),
            _divider(),
            _expandableTile(context, 'grow', Icons.trending_up_outlined, 'Grow Your Business', children: [
              _subItem(context, Icons.share_outlined, 'Refer & Earn', () {}),
              _subItem(context, Icons.people_outline, 'WhatsApp Broadcast', () {}),
            ]),
            _divider(),
            _navTile(context, Icons.settings_outlined, 'Settings', null,
              () => _push(context, SettingsScreen(settings: AppSettings.instance)), isNew: true),
            _divider(),
            _expandableTile(context, 'help', Icons.headset_mic_outlined, 'Help & Support', children: [
              _subItem(context, Icons.chat_bubble_outline, 'Chat with us', () {}),
              _subItem(context, Icons.video_library_outlined, 'Tutorial Videos', () {}),
              _subItem(context, Icons.question_answer_outlined, 'FAQs', () {}),
            ]),
            _divider(),
            _navTile(context, Icons.star_rate_outlined, 'Rate this app', null, () {}),
          ]),

          // ── App Version ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text('App Version  1.0.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Profile Header Widget ───────────────────────────────────────────
  Widget _buildProfileHeader(BuildContext context, AppSettings settings) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandPalette.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.business, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.businessName.isEmpty ? 'My Business' : settings.businessName,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: BrandPalette.sun, borderRadius: BorderRadius.circular(6)),
                    child: const Text('BASIC PLAN', style: TextStyle(color: BrandPalette.navy, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _push(context, SettingsScreen(settings: AppSettings.instance)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Upgrade ✨', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _push(context, SettingsScreen(settings: AppSettings.instance)),
          ),
        ],
      ),
    );
  }

  // ── Section Card ────────────────────────────────────────────────────
  Widget _sectionCard(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Nav Tile (simple arrow) ─────────────────────────────────────────
  Widget _navTile(BuildContext context, IconData icon, String title, String? subtitle, VoidCallback onTap, {bool isNew = false, String? badge}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: BrandPalette.navy, size: 22),
      title: Row(children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        if (isNew) ...[
          const SizedBox(width: 8),
          _newBadge(),
        ],
        if (badge != null) ...[
          const SizedBox(width: 4),
          Text(badge, style: const TextStyle(fontSize: 10)),
        ],
      ]),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  // ── Expandable Tile ─────────────────────────────────────────────────
  Widget _expandableTile(BuildContext context, String id, IconData icon, String title, {List<Widget> children = const [], bool isNew = false}) {
    final isOpen = _expanded.contains(id);
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(icon, color: BrandPalette.navy, size: 22),
          title: Row(children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            if (isNew) ...[const SizedBox(width: 8), _newBadge()],
          ]),
          trailing: AnimatedRotation(
            turns: isOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
          ),
          onTap: () => setState(() {
            if (isOpen) {
              _expanded.remove(id);
            } else {
              _expanded.add(id);
            }
          }),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Container(
            color: BrandPalette.pageBase.withValues(alpha: 0.5),
            child: Column(children: children),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Sub Item (indented) ─────────────────────────────────────────────
  Widget _subItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      leading: Icon(icon, color: Colors.grey.shade600, size: 18),
      title: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, endIndent: 0, color: Colors.grey.shade100);

  Widget _newBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: BrandPalette.coral, borderRadius: BorderRadius.circular(8)),
    child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
  );

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _pushTab(BuildContext context, int tab) {
    // Navigate to invoices tab via parent shell — show snack for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switching to Invoices tab...'), duration: Duration(seconds: 1)),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), duration: const Duration(seconds: 2)),
    );
  }

  void _showPlansDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Plans & Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _planCard('FREE', 'Basic billing & invoicing', '₹0/month', Colors.grey, false),
            const SizedBox(height: 8),
            _planCard('BASIC', 'Reports, GST, Khata', '₹999/year', BrandPalette.teal, false),
            const SizedBox(height: 8),
            _planCard('PREMIUM', 'All features + Desktop', '₹1999/year', BrandPalette.navy, true),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _planCard(String name, String features, String price, Color color, bool isPopular) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(features, style: const TextStyle(fontSize: 12)),
            if (isPopular) const Text('⭐ Most Popular', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
          ])),
          Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
