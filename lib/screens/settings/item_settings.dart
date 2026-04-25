import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/core.dart';
import '../../enums/enums.dart';

class ItemSettingsScreen extends StatefulWidget {
  final AppSettings settings;
  const ItemSettingsScreen({super.key, required this.settings});
  @override
  State<ItemSettingsScreen> createState() => _ItemSettingsScreenState();
}

class _ItemSettingsScreenState extends State<ItemSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Item Settings'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Enable Item
          _toggle(
            'Enable Item',
            'Manage your product and service catalog',
            s.enableItems,
            (v) => setState(() => s.enableItems = v),
          ),
          _divider(),

          // Item Type (Dropdown)
          _dropdownTile(
            'Item Type',
            'Choose what type of items you sell',
            s.itemType.label,
            onTap: () => _showItemTypePicker(context, s),
          ),
          _divider(),

          // Barcode Scanning
          _toggle(
            'Barcode scanning for items',
            'Scan barcodes to add items quickly',
            s.barcodeScanning,
            (v) => setState(() => s.barcodeScanning = v),
          ),
          _divider(),

          // Stock Maintenance
          _toggle(
            'Stock maintenance',
            'Track and manage item stock levels',
            s.stockMaintenance,
            (v) => setState(() => s.stockMaintenance = v),
          ),
          _divider(),

          // Manufacturing (Premium)
          _premiumToggle(
            'Manufacturing',
            'Create items from raw materials',
            s.enableManufacturing,
            (v) => setState(() => s.enableManufacturing = v),
          ),
          _divider(),

          // Item Units
          _toggle(
            'Item Units',
            'Enable units like kg, pcs, litre, etc.',
            s.enableItemUnits,
            (v) => setState(() => s.enableItemUnits = v),
          ),
          _divider(),

          // Default Unit
          _toggle(
            'Default Unit',
            'Set a default unit for all items',
            s.useDefaultUnit,
            (v) => setState(() => s.useDefaultUnit = v),
          ),
          _divider(),

          // Item Category
          _toggle(
            'Item Category',
            'Organise items by category',
            s.enableItemCategory,
            (v) => setState(() => s.enableItemCategory = v),
          ),
          _divider(),

          // Party Wise Item Rate (Premium)
          _premiumToggle(
            'Party wise item rate',
            'Set different prices for each party',
            s.partyWiseItemRate,
            (v) => setState(() => s.partyWiseItemRate = v),
          ),
          _divider(),

          // Wholesale Price (Premium)
          _premiumToggle(
            'Wholesale Price',
            'Set wholesale prices for bulk buyers',
            s.enableWholesalePrice,
            (v) => setState(() => s.enableWholesalePrice = v),
          ),
          _divider(),

          // Quantity Decimal Places
          _quantityTile(s),
          _divider(),

          // Item Wise Tax
          _toggle(
            'Item wise tax',
            'Set different tax rates per item',
            s.itemWiseTax,
            (v) => setState(() => s.itemWiseTax = v),
          ),
          _divider(),

          // Calculate Tax based on MRP
          _toggle(
            'Calculate Tax based on MRP',
            'Tax calculated on Maximum Retail Price',
            s.calculateTaxOnMrp,
            (v) => setState(() => s.calculateTaxOnMrp = v),
          ),
          _divider(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: BrandPalette.teal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _premiumToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 10, color: Colors.purple.shade700),
                const SizedBox(width: 2),
                Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
              ],
            ),
          ),
        ],
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          if (v) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upgrade to Pro to unlock this feature!'), backgroundColor: Colors.purple),
            );
          } else {
            onChanged(v);
          }
        },
        activeColor: BrandPalette.teal,
      ),
    );
  }

  Widget _dropdownTile(String title, String subtitle, String value, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _quantityTile(AppSettings s) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: const Text('Quantity (Upto Decimal places)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text('Currently: ${s.quantityDecimalPlaces} decimal places', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () => setState(() { if (s.quantityDecimalPlaces > 0) s.quantityDecimalPlaces--; }),
          ),
          Text('${s.quantityDecimalPlaces}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => setState(() { if (s.quantityDecimalPlaces < 4) s.quantityDecimalPlaces++; }),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 16, color: Colors.grey.shade200);

  void _showItemTypePicker(BuildContext context, AppSettings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Item Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...ItemType.values.map((type) => RadioListTile<ItemType>(
            value: type,
            groupValue: s.itemType,
            title: Text(type.label),
            onChanged: (v) {
              setState(() => s.itemType = v!);
              Navigator.pop(ctx);
            },
            activeColor: BrandPalette.teal,
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
