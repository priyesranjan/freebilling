import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../core/core.dart';
import '../services/sync_service.dart';
import '../widgets/premium_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bulk_import_wizard.dart';

class ItemsSection extends StatefulWidget {
  final bool isLoading;
  final List<Product> products;
  final String? Function({
    required String name, 
    required double sellingPrice, 
    String? imageUrl,
  })? onAddProduct;
  final void Function(Product)? onUpdateProduct;
  final void Function(String)? onDeleteProduct;

  const ItemsSection({
    super.key, 
    this.isLoading = false,
    required this.products, 
    this.onAddProduct,
    this.onUpdateProduct,
    this.onDeleteProduct,
  });

  @override
  State<ItemsSection> createState() => _ItemsSectionState();
}

class _ItemsSectionState extends State<ItemsSection> {
  String _searchQuery = '';
  String _filter = 'All'; // All, Low Stock, In Stock

  List<Product> get filteredProducts {
    return widget.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.codes.any((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Low Stock' && p.currentStock <= p.lowStockAlertLevel && p.lowStockAlertLevel > 0) ||
          (_filter == 'In Stock' && p.currentStock > 0);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get lowStockCount => widget.products.where((p) => p.currentStock <= p.lowStockAlertLevel && p.lowStockAlertLevel > 0).length;

  @override
  Widget build(BuildContext context) {
    final items = filteredProducts;

    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: Text('Items (${widget.products.length})'),
        elevation: 0,
        backgroundColor: BrandPalette.pageBase,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Bulk Import Items',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showBulkImportOptions(context);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search items or barcode...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: const Icon(Icons.qr_code_scanner, color: BrandPalette.navy),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: ['All', 'Low Stock', 'In Stock'].map((f) {
                    final isSelected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? BrandPalette.navy : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? BrandPalette.navy : Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (f == 'Low Stock') ...[
                                const Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                f == 'Low Stock' ? 'Low Stock ($lowStockCount)' : f,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_filter == 'Low Stock' && lowStockCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                      label: const Text('Reorder from Distributor (WhatsApp)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrandPalette.coral,
                        side: const BorderSide(color: BrandPalette.coral),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _sendReorderWhatsApp(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: widget.isLoading
          ? ListView.builder(itemCount: 8, itemBuilder: (context, index) => const SkeletonListTile())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No items found.', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                final isLowStock = product.currentStock <= product.lowStockAlertLevel && product.lowStockAlertLevel > 0;
                final isOutOfStock = product.currentStock <= 0;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isOutOfStock
                          ? Colors.red.shade300
                          : isLowStock
                              ? BrandPalette.coral.withValues(alpha: 0.5)
                              : Colors.grey.shade200,
                      width: (isLowStock || isOutOfStock) ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showItemSettings(context, product),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              image: product.imageUrl != null
                                  ? DecorationImage(image: FileImage(File(product.imageUrl!)), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: product.imageUrl == null
                                ? const Icon(Icons.image, color: Colors.grey, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text('₹${product.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF0DAB76), fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddItemSheet(context);
        },
        backgroundColor: BrandPalette.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final sellingPriceCtrl = TextEditingController();
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: StatefulBuilder(
          builder: (ctx2, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final xfile = await picker.pickImage(source: ImageSource.camera);
                  if (xfile != null) {
                    setModalState(() => selectedImagePath = xfile.path);
                  }
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    image: selectedImagePath != null 
                        ? DecorationImage(image: FileImage(File(selectedImagePath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: selectedImagePath == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Take Photo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: sellingPriceCtrl, 
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: 'Price (₹)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl, 
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Item Name (Optional)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0DAB76),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final sp = double.tryParse(sellingPriceCtrl.text) ?? 0.0;
                    if (sp <= 0) return;
                    
                    final name = nameCtrl.text.trim().isEmpty ? 'Item ₹$sp' : nameCtrl.text.trim();

                    final error = widget.onAddProduct?.call(
                      name: name,
                      sellingPrice: sp,
                      imageUrl: selectedImagePath,
                    );

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                      return;
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save (सेव करें)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemSettings(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: BrandPalette.navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory_2, color: BrandPalette.navy)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('₹${product.price} | Stock: ${product.currentStock.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ]),
              ],
            ),
            const Divider(height: 24),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit, color: BrandPalette.navy), title: const Text('Edit Item'), onTap: () {
              Navigator.pop(ctx);
              _showEditItemSheet(context, product);
            }),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.add_box, color: BrandPalette.teal), title: const Text('Add / Adjust Stock'), onTap: () {
              Navigator.pop(ctx);
              _showAdjustStockSheet(context, product);
            }),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: const Text('Set Low Stock Alert'),
              subtitle: Text('Current alert: ${product.lowStockAlertLevel.toStringAsFixed(0)} units'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.qr_code), title: const Text('Print Barcode'), onTap: () => Navigator.pop(ctx)),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.history), title: const Text('Stock History'), onTap: () => Navigator.pop(ctx)),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delete_outline, color: BrandPalette.coral), title: const Text('Delete Item', style: TextStyle(color: BrandPalette.coral)), onTap: () {
              Navigator.pop(ctx);
              widget.onDeleteProduct?.call(product.id);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted')));
            }),
          ],
        ),
      ),
    );
  }

  void _showEditItemSheet(BuildContext context, Product product) {
    final nameCtrl = TextEditingController(text: product.name);
    final mrpCtrl = TextEditingController(text: product.mrp.toString());
    final sellingPriceCtrl = TextEditingController(text: product.sellingPrice.toString());
    final codeCtrl = TextEditingController(text: product.codes.isNotEmpty ? product.codes.first : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Edit Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: mrpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP', border: OutlineInputBorder(), prefixText: '₹ ')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: sellingPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price *', border: OutlineInputBorder(), prefixText: '₹ ')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Item Code / Barcode (Optional)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.qr_code_scanner, color: BrandPalette.teal))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final mrp = double.tryParse(mrpCtrl.text) ?? 0;
                  final sp = double.tryParse(sellingPriceCtrl.text) ?? 0;
                  final code = codeCtrl.text.trim();
                  if (name.isEmpty || sp <= 0) return;
                  
                  final updated = product.copyWith(
                    name: name,
                    mrp: mrp,
                    sellingPrice: sp,
                    codes: code.isNotEmpty ? [code] : [],
                    syncState: EntityState.pendingUpdate,
                  );
                  widget.onUpdateProduct?.call(updated);
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(backgroundColor: BrandPalette.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Update Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustStockSheet(BuildContext context, Product product) {
    final stockCtrl = TextEditingController();
    bool isAdding = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Adjust Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 8),
              Text('Current Stock: ${product.currentStock.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Add Stock (+)')),
                  ButtonSegment(value: false, label: Text('Reduce Stock (-)')),
                ],
                selected: {isAdding},
                onSelectionChanged: (s) => setS(() => isAdding = s.first),
              ),
              const SizedBox(height: 16),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final qty = double.tryParse(stockCtrl.text) ?? 0;
                    if (qty <= 0) return;
                    
                    final newBatch = ProductBatch(
                      batchNumber: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
                      mfgDate: DateTime.now(),
                      expiryDate: null,
                      stockCount: isAdding ? qty : -qty,
                    );
                    
                    final updated = product.copyWith(
                      batches: [...product.batches, newBatch],
                      syncState: EntityState.pendingUpdate,
                    );
                    widget.onUpdateProduct?.call(updated);
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(backgroundColor: BrandPalette.coral, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Update Stock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendReorderWhatsApp() {
    final lowStockItems = widget.products.where((p) => p.currentStock <= p.lowStockAlertLevel && p.lowStockAlertLevel > 0).toList();
    if (lowStockItems.isEmpty) return;

    String message = 'Namaste, this is an order for ${AppSettings.instance.businessName}:\n\n';
    for (final item in lowStockItems) {
      message += '• ${item.name} (Current: ${item.currentStock.toStringAsFixed(0)})\n';
    }
    message += '\nPlease send these items at the earliest. Thank you!';

    final Uri whatsappUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  }

  void _showBulkImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Import Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: BrandPalette.teal),
              title: const Text('Import from Excel / CSV'),
              onTap: () {
                Navigator.pop(ctx);
                _openImportWizard('excel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner, color: BrandPalette.navy),
              title: const Text('Scan PDF or Catalog (AI)'),
              subtitle: const Text('Extract items automatically from your PDF catalogs.'),
              onTap: () {
                Navigator.pop(ctx);
                _openImportWizard('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: BrandPalette.coral),
              title: const Text('Take Photo of Menu/List (AI)'),
              subtitle: const Text('Point camera at any printed list to extract items.'),
              onTap: () {
                Navigator.pop(ctx);
                _openImportWizard('photo');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openImportWizard(String method) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BulkImportWizard(
          method: method,
          onProductsExtracted: (products) {
            for (final p in products) {
              widget.onAddProduct?.call(
                name: p.name,
                sellingPrice: p.sellingPrice,
                imageUrl: p.imageUrl,
              );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully imported ${products.length} items!'), backgroundColor: BrandPalette.teal),
            );
          },
        ),
      ),
    );
  }
}
