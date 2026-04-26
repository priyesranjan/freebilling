import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/core.dart';
import 'settings/general_settings.dart';
import 'settings/transaction_settings.dart';
import 'settings/invoice_print_settings.dart';
import 'settings/tax_settings.dart';
import 'settings/item_settings.dart';
import 'settings/reminder_settings.dart';
import 'settings/google_business_settings_screen.dart';
import 'settings/integration_settings.dart';
import 'settings/business_features_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          _buildSettingsTile(context,
            icon: Icons.settings,
            title: 'General',
            isNew: true,
            onTap: () => _push(context, GeneralSettingsScreen(settings: settings)),
          ),
          _buildSettingsTile(context,
            icon: Icons.business_center_outlined,
            title: 'Business Features',
            isNew: true,
            onTap: () => _push(context, BusinessFeaturesScreen(settings: settings)),
          ),
          _buildSettingsTile(context,
            icon: Icons.swap_vert_circle_outlined,
            title: 'Transaction',
            isNew: true,
            onTap: () => _push(context, TransactionSettingsScreen(settings: settings)),
          ),
          _buildSettingsTile(context,
            icon: Icons.print_outlined,
            title: 'Invoice Print',
            onTap: () => _push(context, InvoicePrintSettingsScreen(settings: settings)),
          ),
          _buildSettingsTile(context,
            icon: Icons.percent,
            title: 'Taxes & GST',
            isNew: true,
            onTap: () => _push(context, TaxSettingsScreen(settings: settings)),
          ),
          _buildSettingsTile(context,
            icon: Icons.people_outlined,
            title: 'User Management',
            onTap: () => _showComingSoon(context, 'User Management'),
          ),
          _buildSettingsTile(context,
            icon: Icons.message_outlined,
            title: 'Transaction SMS',
            onTap: () => _showComingSoon(context, 'Transaction SMS'),
          ),
          _buildSettingsTile(context,
            icon: Icons.notifications_outlined,
            title: 'Reminders',
            onTap: () => _push(context, ReminderSettingsScreen(settings: settings)),
          ),
          _buildSettingsTile(context,
            icon: Icons.people_alt_outlined,
            title: 'Party',
            onTap: () => _showComingSoon(context, 'Party Settings'),
          ),
          _buildSettingsTile(context,
            icon: Icons.inventory_2_outlined,
            title: 'Item',
            onTap: () => _push(context, ItemSettingsScreen(settings: settings)),
          ),
          const Divider(height: 1),
          _buildSettingsTile(context,
            icon: Icons.hub_outlined,
            title: 'API Integrations',
            isNew: true,
            onTap: () => _push(context, IntegrationSettingsScreen(settings: settings)),
          ),
          _buildSettingsTile(context,
            icon: Icons.store_mall_directory_outlined,
            title: 'Google Business Profile',
            isNew: true,
            onTap: () => _push(context, const GoogleBusinessSettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    bool isNew = false,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: BrandPalette.navy, size: 22),
          title: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              if (isNew) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: BrandPalette.coral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        Divider(height: 1, indent: 56, color: Colors.grey.shade200),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title settings coming soon!'), duration: const Duration(seconds: 2)),
    );
  }
}
