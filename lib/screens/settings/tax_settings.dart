import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';

class TaxSettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const TaxSettingsScreen({super.key, required this.settings});
  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  late TextEditingController _gstinCtrl;
  @override
  void initState() {
    super.initState();
    _gstinCtrl = TextEditingController(text: widget.settings.gstin);
  }
  @override
  void dispose() { _gstinCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Taxes & GST'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('GST Registration'),
          _card([
            _toggle('GST Registered Business', widget.settings.businessGstinEnabled,
              (v) => setState(() => widget.settings.businessGstinEnabled = v)),
            if (widget.settings.businessGstinEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _gstinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN',
                    hintText: '22AAAAA0000A1Z5',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          _sectionHeader('Tax Calculation Method'),
          _card([
            RadioListTile<String>(
              value: 'exclusive',
              groupValue: widget.settings.defaultTaxType,
              title: const Text('Tax Exclusive'),
              subtitle: const Text('Tax is added on top of the price'),
              onChanged: (v) => setState(() => widget.settings.defaultTaxType = v!),
              activeColor: BrandPalette.teal,
            ),
            RadioListTile<String>(
              value: 'inclusive',
              groupValue: widget.settings.defaultTaxType,
              title: const Text('Tax Inclusive'),
              subtitle: const Text('Tax is included in the price'),
              onChanged: (v) => setState(() => widget.settings.defaultTaxType = v!),
              activeColor: BrandPalette.teal,
            ),
          ]),
          const SizedBox(height: 16),
          _sectionHeader('GST Rates Available'),
          _card(
            TaxRate.values.map((rate) {
              final label = rate.percentage == 0 ? 'Exempt (0%)' : 'GST ${rate.percentage.toInt()}%';
              return ListTile(
                leading: const Icon(Icons.percent, color: BrandPalette.navy, size: 20),
                title: Text(label),
                trailing: const Icon(Icons.check, color: BrandPalette.teal),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy, padding: const EdgeInsets.symmetric(vertical: 14)),
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

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    value: value,
    onChanged: onChanged,
    activeColor: BrandPalette.teal,
  );

  void _save() {
    widget.settings.gstin = _gstinCtrl.text.trim().toUpperCase();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tax settings saved!'), backgroundColor: BrandPalette.teal),
    );
  }
}
