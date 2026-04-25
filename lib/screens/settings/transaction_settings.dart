import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';

class TransactionSettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const TransactionSettingsScreen({super.key, required this.settings});
  @override
  State<TransactionSettingsScreen> createState() => _TransactionSettingsScreenState();
}

class _TransactionSettingsScreenState extends State<TransactionSettingsScreen> {
  late TextEditingController _prefixCtrl;
  late int _nextNumber;
  late PaymentMode _defaultPayment;

  @override
  void initState() {
    super.initState();
    _prefixCtrl = TextEditingController(text: widget.settings.invoicePrefix);
    _nextNumber = widget.settings.invoiceNextNumber;
    _defaultPayment = PaymentMode.cash;
  }

  @override
  void dispose() { _prefixCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Transaction Settings'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card([
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Invoice Number Format', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _prefixCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prefix',
                        hintText: 'INV',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => setState(() { if (_nextNumber > 1) _nextNumber--; }),
                            ),
                            Text('$_nextNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _nextNumber++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Preview: ${_prefixCtrl.text.isEmpty ? 'INV' : _prefixCtrl.text}-${_nextNumber.toString().padLeft(4, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.navy),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _card([
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Default Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            ),
            ...PaymentMode.values.map((mode) {
              return RadioListTile<PaymentMode>(
                value: mode,
                groupValue: _defaultPayment,
                title: Text(mode.name.toUpperCase()),
                onChanged: (v) => setState(() => _defaultPayment = v!),
                activeColor: BrandPalette.teal,
              );
            }),
          ]),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  void _save() {
    widget.settings.invoicePrefix = _prefixCtrl.text.trim().isEmpty ? 'INV' : _prefixCtrl.text.trim();
    widget.settings.invoiceNextNumber = _nextNumber;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction settings saved!'), backgroundColor: BrandPalette.teal),
    );
  }
}
