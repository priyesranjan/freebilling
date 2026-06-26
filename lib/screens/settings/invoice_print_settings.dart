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
  late TextEditingController _spiritualHeaderCtrl;
  late bool _showSpiritualHeader;

  @override
  void initState() {
    super.initState();
    _termsCtrl = TextEditingController(text: widget.settings.termsAndConditions);
    _spiritualHeaderCtrl = TextEditingController(text: widget.settings.spiritualHeaderText);
    _showSpiritualHeader = widget.settings.showSpiritualHeader;
  }
  @override
  void dispose() { 
    _termsCtrl.dispose(); 
    _spiritualHeaderCtrl.dispose();
    super.dispose(); 
  }

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
            _toggle('Show Spiritual Header', _showSpiritualHeader, (v) => setState(() => _showSpiritualHeader = v)),
          ]),
          if (_showSpiritualHeader) ...[
            const SizedBox(height: 16),
            _sectionHeader('Spiritual Header Text'),
            _card([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _spiritualHeaderCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. !! SHREE GANESHYA NAMAH !!',
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 4),
                    const Text('Popular Presets:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        '!! SHREE GANESHYA NAMAH !!',
                        '!! JAI SHREE RAM !!',
                        '!! BISMILLAH !!',
                        '!! WAHEGURU !!',
                      ].map((preset) => ActionChip(
                        label: Text(preset, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onPressed: () {
                          setState(() {
                            _spiritualHeaderCtrl.text = preset;
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          _sectionHeader('Custom Footer / Terms & Conditions'),
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

  Future<void> _save() async {
    widget.settings.termsAndConditions = _termsCtrl.text.trim();
    widget.settings.showSpiritualHeader = _showSpiritualHeader;
    widget.settings.spiritualHeaderText = _spiritualHeaderCtrl.text.trim();
    await widget.settings.save();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print settings saved!'), backgroundColor: BrandPalette.teal),
      );
    }
  }
}
