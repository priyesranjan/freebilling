import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GeneralSettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const GeneralSettingsScreen({super.key, required this.settings});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  String? _localLogoPath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.settings.businessName);
    _addressCtrl = TextEditingController(text: widget.settings.businessAddress);
    _phoneCtrl = TextEditingController(text: widget.settings.businessPhone);
    _emailCtrl = TextEditingController(text: widget.settings.businessEmail);
    _gstinCtrl = TextEditingController(text: widget.settings.gstin);
    _localLogoPath = widget.settings.businessLogo;
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _localLogoPath = image.path;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose();
    _phoneCtrl.dispose(); _emailCtrl.dispose(); _gstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('General Settings'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Logo
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: BrandPalette.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BrandPalette.navy.withValues(alpha: 0.2)),
                  ),
                  child: _localLogoPath != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_localLogoPath!), fit: BoxFit.cover),
                      )
                    : const Icon(Icons.business, size: 36, color: BrandPalette.navy),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Change Logo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader('Business Information'),
          _buildTextField(_nameCtrl, 'Business Name *', Icons.store),
          const SizedBox(height: 12),
          _buildTextField(_phoneCtrl, 'Phone Number', Icons.phone, inputType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField(_emailCtrl, 'Email Address', Icons.email, inputType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField(_addressCtrl, 'Business Address', Icons.location_on, maxLines: 3),
          const SizedBox(height: 20),
          _sectionHeader('Tax Information'),
          _buildTextField(_gstinCtrl, 'GSTIN (optional)', Icons.receipt_long),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrandPalette.mint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BrandPalette.teal.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: BrandPalette.teal),
                SizedBox(width: 8),
                Expanded(child: Text('GSTIN will appear on all invoices. Format: 22AAAAA0000A1Z5', style: TextStyle(fontSize: 12, color: BrandPalette.teal))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Role & Security'),
          SwitchListTile(
            title: const Text('Staff Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Hide profits and sensitive reports from employees'),
            secondary: const Icon(Icons.security, color: BrandPalette.navy),
            value: widget.settings.isStaffMode,
            activeColor: BrandPalette.teal,
            onChanged: (val) => setState(() => widget.settings.isStaffMode = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? inputType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  void _save() {
    widget.settings.businessName = _nameCtrl.text.trim();
    widget.settings.businessAddress = _addressCtrl.text.trim();
    widget.settings.businessPhone = _phoneCtrl.text.trim();
    widget.settings.businessEmail = _emailCtrl.text.trim();
    widget.settings.gstin = _gstinCtrl.text.trim();
    widget.settings.businessLogo = _localLogoPath;
    widget.settings.save();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business details saved!'), backgroundColor: BrandPalette.teal),
    );
  }
}
