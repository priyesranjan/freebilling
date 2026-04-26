import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';

class BusinessFeaturesScreen extends StatefulWidget {
  final AppSettings settings;
  const BusinessFeaturesScreen({super.key, required this.settings});

  @override
  State<BusinessFeaturesScreen> createState() => _BusinessFeaturesScreenState();
}

class _BusinessFeaturesScreenState extends State<BusinessFeaturesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Business Features'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Special Categories',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Quotations & Estimates', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enable for Studios, Event Managers, and Service businesses.'),
                  secondary: const Icon(Icons.description_outlined, color: BrandPalette.navy),
                  value: widget.settings.enableQuotations,
                  activeColor: BrandPalette.teal,
                  onChanged: (val) {
                    setState(() {
                      widget.settings.enableQuotations = val;
                      widget.settings.save();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(val ? 'Quotations Enabled!' : 'Quotations Disabled!'), backgroundColor: BrandPalette.teal),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
