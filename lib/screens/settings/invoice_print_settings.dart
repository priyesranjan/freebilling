import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';
import '../../enums/enums.dart';

class InvoicePrintSettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const InvoicePrintSettingsScreen({super.key, required this.settings});
  @override
  State<InvoicePrintSettingsScreen> createState() => _InvoicePrintSettingsScreenState();
}

class _InvoicePrintSettingsScreenState extends State<InvoicePrintSettingsScreen> {
  late TextEditingController _termsCtrl;
  @override
  void initState() {
    super.initState();
    _termsCtrl = TextEditingController(text: widget.settings.termsAndConditions);
  }
  @override
  void dispose() { _termsCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Invoice Print Settings'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Paper Size'),
          _card([
            ...PaperSize.values.map((size) => RadioListTile<PaperSize>(
              value: size,
              groupValue: widget.settings.paperSize,
              title: Text(size.label),
              subtitle: _paperSubtitle(size),
              onChanged: (v) => setState(() => widget.settings.paperSize = v!),
              activeColor: BrandPalette.teal,
            )),
          ]),
          const SizedBox(height: 16),
          _sectionHeader('Invoice Options'),
          _card([
            _toggle('Show Business Logo', widget.settings.showLogo, (v) => setState(() => widget.settings.showLogo = v)),
            _toggle('Show Signature Line', widget.settings.showSignature, (v) => setState(() => widget.settings.showSignature = v)),
          ]),
          const SizedBox(height: 16),
          _sectionHeader('Terms & Conditions'),
          TextField(
            controller: _termsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter terms & conditions that will appear on invoices...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
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

  Widget? _paperSubtitle(PaperSize size) {
    switch (size) {
      case PaperSize.thermal80mm: return const Text('For thermal printers, most common');
      case PaperSize.thermal58mm: return const Text('For smaller thermal printers');
      case PaperSize.a4: return const Text('Standard A4 paper');
      case PaperSize.a5: return const Text('Half A4 size');
    }
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
    widget.settings.termsAndConditions = _termsCtrl.text;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print settings saved!'), backgroundColor: BrandPalette.teal),
    );
  }
}
