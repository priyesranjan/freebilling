import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';

class IntegrationSettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const IntegrationSettingsScreen({super.key, required this.settings});

  @override
  State<IntegrationSettingsScreen> createState() => _IntegrationSettingsScreenState();
}

class _IntegrationSettingsScreenState extends State<IntegrationSettingsScreen> {
  late TextEditingController _rzpIdCtrl;
  late TextEditingController _rzpSecretCtrl;
  late TextEditingController _twoFactorCtrl;
  late TextEditingController _waTokenCtrl;
  late TextEditingController _waPhoneIdCtrl;

  @override
  void initState() {
    super.initState();
    _rzpIdCtrl = TextEditingController(text: widget.settings.razorpayKeyId);
    _rzpSecretCtrl = TextEditingController(text: widget.settings.razorpayKeySecret);
    _twoFactorCtrl = TextEditingController(text: widget.settings.twoFactorApiKey);
    _waTokenCtrl = TextEditingController(text: widget.settings.whatsappApiToken);
    _waPhoneIdCtrl = TextEditingController(text: widget.settings.whatsappPhoneNumberId);
  }

  @override
  void dispose() {
    _rzpIdCtrl.dispose();
    _rzpSecretCtrl.dispose();
    _twoFactorCtrl.dispose();
    _waTokenCtrl.dispose();
    _waPhoneIdCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.settings.razorpayKeyId = _rzpIdCtrl.text.trim();
    widget.settings.razorpayKeySecret = _rzpSecretCtrl.text.trim();
    widget.settings.twoFactorApiKey = _twoFactorCtrl.text.trim();
    widget.settings.whatsappApiToken = _waTokenCtrl.text.trim();
    widget.settings.whatsappPhoneNumberId = _waPhoneIdCtrl.text.trim();
    widget.settings.save();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Integrations Saved!'), backgroundColor: BrandPalette.teal),
    );
    Navigator.pop(context);
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BrandPalette.navy),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BrandPalette.navy)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('API Integrations'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.teal)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Securely connect your ERP to external platforms.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          _buildSection('Payment Gateway (Razorpay)', Icons.payment, [
            const Text('Enable dynamic payment links for due invoices.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildTextField(_rzpIdCtrl, 'Key ID'),
            _buildTextField(_rzpSecretCtrl, 'Key Secret', obscureText: true),
          ]),

          _buildSection('SMS Marketing (2Factor.in)', Icons.sms, [
            const Text('Send OTPs and marketing blasts to your customers.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildTextField(_twoFactorCtrl, 'API Key', obscureText: true),
          ]),

          _buildSection('WhatsApp Cloud API', Icons.message, [
            const Text('Automatically send A4 PDF invoices to customers.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildTextField(_waTokenCtrl, 'Permanent Access Token', obscureText: true),
            _buildTextField(_waPhoneIdCtrl, 'Phone Number ID'),
          ]),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save API Keys'),
              style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          )
        ],
      ),
    );
  }
}
