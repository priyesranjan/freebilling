import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';
import '../../services/catalog_service.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  late TextEditingController _pincodeCtrl;
  
  String? _localLogoPath;
  String? _localSignaturePath;
  
  String _selectedCategory = 'Kirana / General Store';
  String _selectedBusinessType = 'Retail';
  String _selectedState = 'Maharashtra';
  String _selectedDistrict = 'Mumbai City';
  String _selectedCity = 'Mumbai';
  String _selectedInvoiceFormat = 'POS';
  String _selectedInvoiceTheme = 'standard';
  List<String> _selectedCertifications = [];

  final List<String> _formats = ['POS', 'A4'];
  final List<String> _themes = ['standard', 'modern', 'professional'];
  final List<String> _availableCertifications = ['MSME', 'GST Verified', 'ISO 9001:2015', 'FSSAI', 'MCA', 'Hallmark', 'Agmark'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.settings.businessName);
    _addressCtrl = TextEditingController(text: widget.settings.businessAddress);
    _phoneCtrl = TextEditingController(text: widget.settings.businessPhone);
    _emailCtrl = TextEditingController(text: widget.settings.businessEmail);
    _gstinCtrl = TextEditingController(text: widget.settings.gstin);
    _pincodeCtrl = TextEditingController(text: widget.settings.pincode);
    
    _localLogoPath = widget.settings.businessLogo;
    _localSignaturePath = widget.settings.businessSignature;
    
    if (IndianGeography.businessCategories.contains(widget.settings.businessCategory)) {
      _selectedCategory = widget.settings.businessCategory;
    } else if (widget.settings.businessCategory.isNotEmpty) {
      _selectedCategory = IndianGeography.businessCategories.first; // Fallback
    }

    if (IndianGeography.businessTypes.contains(widget.settings.businessType)) {
      _selectedBusinessType = widget.settings.businessType;
    }

    if (IndianGeography.stateDistricts.keys.contains(widget.settings.state)) {
      _selectedState = widget.settings.state;
    }

    if (widget.settings.district.isNotEmpty) _selectedDistrict = widget.settings.district;
    if (widget.settings.city.isNotEmpty) _selectedCity = widget.settings.city;

    if (_formats.contains(widget.settings.invoiceFormat)) {
      _selectedInvoiceFormat = widget.settings.invoiceFormat;
    }
    
    if (_themes.contains(widget.settings.invoiceTheme)) {
      _selectedInvoiceTheme = widget.settings.invoiceTheme;
    }
    
    _selectedCertifications = List.from(widget.settings.certifications);
  }

  Future<void> _importSmartCatalog() async {
    try {
      final items = CatalogService.getCatalogForCategory(_selectedCategory);
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No catalog available for this category.')));
        return;
      }
      
      final box = Hive.box<Product>('products');
      for (var p in items) {
        await box.put(p.id, p);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported ${items.length} $_selectedCategory items!'), backgroundColor: BrandPalette.teal),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing catalog: $e'), backgroundColor: BrandPalette.coral));
    }
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

  Future<void> _pickSignature() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _localSignaturePath = image.path;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose();
    _phoneCtrl.dispose(); _emailCtrl.dispose(); _gstinCtrl.dispose();
    _pincodeCtrl.dispose();
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
          const SizedBox(height: 16),
          _sectionHeader('Business Profile & Catalogs'),
          DropdownButtonFormField<String>(
            value: _selectedBusinessType,
            decoration: InputDecoration(labelText: 'Business Type', prefixIcon: const Icon(Icons.store), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
            items: IndianGeography.businessTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedBusinessType = v!),
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _selectedCategory),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return IndianGeography.businessCategories;
              }
              return IndianGeography.businessCategories.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _selectedCategory = selection;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: 'Business Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search categories...',
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.download, color: BrandPalette.teal),
            label: Text('Import "$_selectedCategory" Smart Catalog', style: const TextStyle(color: BrandPalette.teal)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: BrandPalette.teal)),
            onPressed: _importSmartCatalog,
          ),
          const SizedBox(height: 20),
          _sectionHeader('Business Information'),
          _buildTextField(_nameCtrl, 'Business Name *', Icons.store),
          const SizedBox(height: 12),
          _buildTextField(_phoneCtrl, 'Phone Number', Icons.phone, inputType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField(_emailCtrl, 'Email Address', Icons.email, inputType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField(_addressCtrl, 'Billing Address', Icons.location_on, maxLines: 2),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: InputDecoration(labelText: 'State', prefixIcon: const Icon(Icons.map), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
            items: IndianGeography.stateDistricts.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedState = v!;
                _selectedDistrict = IndianGeography.stateDistricts[_selectedState]!.first;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: IndianGeography.stateDistricts[_selectedState]!.contains(_selectedDistrict) ? _selectedDistrict : IndianGeography.stateDistricts[_selectedState]!.first,
                  decoration: InputDecoration(labelText: 'District', prefixIcon: const Icon(Icons.location_city), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
                  items: IndianGeography.stateDistricts[_selectedState]!.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedDistrict = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: _selectedCity),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') return IndianGeography.popularCities.take(5);
                    return IndianGeography.popularCities.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) => setState(() => _selectedCity = selection),
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        labelText: 'City',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(_pincodeCtrl, 'Pin Code', Icons.pin_drop, inputType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionHeader('Signature / Stamp (For Invoices)'),
          InkWell(
            onTap: _pickSignature,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BrandPalette.navy.withValues(alpha: 0.2)),
              ),
              child: _localSignaturePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_localSignaturePath!), fit: BoxFit.contain),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw, color: BrandPalette.teal, size: 32),
                        SizedBox(height: 8),
                        Text('Tap to upload Signature / Stamp', style: TextStyle(color: BrandPalette.teal)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Invoice Print Format'),
          DropdownButtonFormField<String>(
            value: _selectedInvoiceFormat,
            decoration: InputDecoration(labelText: 'Receipt Layout', prefixIcon: const Icon(Icons.receipt), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
            items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f == 'POS' ? 'Thermal Receipt (80mm)' : 'A4 Standard Invoice'))).toList(),
            onChanged: (v) => setState(() => _selectedInvoiceFormat = v!),
          ),
          if (_selectedInvoiceFormat == 'A4') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedInvoiceTheme,
              decoration: InputDecoration(labelText: 'Invoice Theme (A4)', prefixIcon: const Icon(Icons.color_lens), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
              items: _themes.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _selectedInvoiceTheme = v!),
            ),
          ],
          const SizedBox(height: 20),
          _sectionHeader('Certifications / Badges'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCertifications.map((cert) {
              final isSelected = _selectedCertifications.contains(cert);
              return FilterChip(
                label: Text(cert),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCertifications.add(cert);
                    } else {
                      _selectedCertifications.remove(cert);
                    }
                  });
                },
                selectedColor: BrandPalette.teal.withValues(alpha: 0.2),
                checkmarkColor: BrandPalette.teal,
              );
            }).toList(),
          ),
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

  Future<void> _save() async {
    widget.settings.businessName = _nameCtrl.text.trim();
    widget.settings.businessAddress = _addressCtrl.text.trim();
    widget.settings.businessPhone = _phoneCtrl.text.trim();
    widget.settings.businessEmail = _emailCtrl.text.trim();
    widget.settings.gstin = _gstinCtrl.text.trim();
    widget.settings.pincode = _pincodeCtrl.text.trim();
    
    widget.settings.businessCategory = _selectedCategory;
    widget.settings.businessType = _selectedBusinessType;
    widget.settings.state = _selectedState;
    widget.settings.district = _selectedDistrict;
    widget.settings.city = _selectedCity;
    
    widget.settings.invoiceFormat = _selectedInvoiceFormat;
    widget.settings.invoiceTheme = _selectedInvoiceTheme;
    widget.settings.certifications = _selectedCertifications;
    widget.settings.businessLogo = _localLogoPath;
    widget.settings.businessSignature = _localSignaturePath;
    
    // Save locally
    await widget.settings.save();
    
    // Sync with backend
    try {
      await ApiService.updateBusinessProfile(widget.settings);
    } catch (e) {
      debugPrint('Failed to sync profile to backend: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved locally, but failed to sync to cloud: $e'), backgroundColor: BrandPalette.coral),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business details saved to cloud!'), backgroundColor: BrandPalette.teal),
      );
    }
  }
}
