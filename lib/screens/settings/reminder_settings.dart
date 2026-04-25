import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';

class ReminderSettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const ReminderSettingsScreen({super.key, required this.settings});
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder settings saved!'), backgroundColor: BrandPalette.teal)); },
            child: const Text('Save', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Payment Reminders'),
          _card([
            SwitchListTile(
              title: const Text('Enable Payment Reminders', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Get reminded about pending payments'),
              value: s.paymentReminderEnabled,
              onChanged: (v) => setState(() => s.paymentReminderEnabled = v),
              activeColor: BrandPalette.teal,
            ),
            if (s.paymentReminderEnabled) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Remind me before due date', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => setState(() { if (s.reminderDaysBeforeDue > 1) s.reminderDaysBeforeDue--; }),
                        ),
                        Text('${s.reminderDaysBeforeDue} days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => s.reminderDaysBeforeDue++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: 16),
          _sectionHeader('WhatsApp Automation'),
          _card([
            SwitchListTile(
              title: const Text('Auto WhatsApp Reminder', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Automatically send payment reminders via WhatsApp'),
              value: s.autoWhatsAppReminder,
              onChanged: (v) => setState(() => s.autoWhatsAppReminder = v),
              activeColor: BrandPalette.teal,
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber),
                SizedBox(width: 10),
                Expanded(child: Text('WhatsApp reminders require WhatsApp credits. Purchase them from Plans & Pricing.', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
  );

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
    child: Column(children: children),
  );
}
