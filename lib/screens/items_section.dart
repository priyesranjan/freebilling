import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/core.dart';
import '../services/sync_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemsSection extends StatefulWidget {
  final List<Product> products;
  final String? Function({
    required String name, 
    required double sellingPrice, 
    required double mrp, 
    required List<String> codes,
    required double initialStock,
    required double lowStockAlertLevel,
    required TaxRate taxRate,
  })? onAddProduct;
  final void Function(Product)? onUpdateProduct;
  final void Function(String)? onDeleteProduct;

  const ItemsSection({
    super.key, 
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search items or scan barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: const Icon(Icons.qr_code_scanner, color: BrandPalette.teal),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, bottom: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      body: items.isEmpty
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: BrandPalette.navy.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2, color: BrandPalette.navy),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text('₹${product.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(color: BrandPalette.navy, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    if (product.mrp > product.sellingPrice) ...[
                                      Text('₹${product.mrp.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, decoration: TextDecoration.lineThrough)),
                                      const SizedBox(width: 4),
                                      Text('${product.offPercentage.toInt()}% OFF', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: BrandPalette.mint.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(product.taxRate.percentage == 0 ? 'Exempt' : 'GST ${product.taxRate.percentage.toInt()}%',
                                        style: const TextStyle(fontSize: 9, color: BrandPalette.teal, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isOutOfStock ? 'Out of Stock' : '${product.currentStock.toStringAsFixed(0)} units',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isOutOfStock ? Colors.red : isLowStock ? BrandPalette.coral : BrandPalette.teal,
                                ),
                              ),
                              if (isLowStock && !isOutOfStock)
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BrandPalette.coral.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Low Stock',
                                    style: TextStyle(color: BrandPalette.coral, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context),
        backgroundColor: BrandPalette.navy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final mrpCtrl = TextEditingController();
    final sellingPriceCtrl = TextEditingController();
    final initialStockCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final alertCtrl = TextEditingController();
    TaxRate selectedTax = TaxRate.exempt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx2, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Add New Item', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: mrpCtrl, 
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'MRP', border: OutlineInputBorder(), prefixText: '₹ '),
                        onChanged: (val) => setModalState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceCtrl, 
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Selling Price *', border: OutlineInputBorder(), prefixText: '₹ '),
                        onChanged: (val) => setModalState(() {}),
                      ),
                    ),
                  ],
                ),
                if (double.tryParse(mrpCtrl.text) != null && double.tryParse(sellingPriceCtrl.text) != null) ...[
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final mrp = double.tryParse(mrpCtrl.text) ?? 0;
                    final sp = double.tryParse(sellingPriceCtrl.text) ?? 0;
                    if (mrp > sp && sp > 0) {
                      final off = ((mrp - sp) / mrp) * 100;
                      return Text('Savings: ₹${(mrp - sp).toStringAsFixed(0)} (${off.toInt()}% OFF)', 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12));
                    }
                    return const SizedBox();
                  }),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: initialStockCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Opening Stock', border: OutlineInputBorder(), suffixText: 'units')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: alertCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Low Stock Alert', border: OutlineInputBorder(), suffixText: 'units')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: codeCtrl, decoration: const InputDecoration(
                  labelText: 'Barcode / SKU Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                  hintText: 'Optional',
                )),
                const SizedBox(height: 12),
                const Text('GST Tax Rate', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaxRate.values.map((rate) {
                    final label = rate.percentage == 0 ? 'Exempt' : '${rate.percentage.toInt()}%';
                    final isSelected = selectedTax == rate;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedTax = rate),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? BrandPalette.teal : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? BrandPalette.teal : Colors.grey.shade300),
                        ),
                        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || sellingPriceCtrl.text.trim().isEmpty) return;
                      
                      final codes = codeCtrl.text.trim().isEmpty ? <String>[] : [codeCtrl.text.trim()];
                      final mrp = double.tryParse(mrpCtrl.text) ?? 0.0;
                      final sp = double.tryParse(sellingPriceCtrl.text) ?? 0.0;
                      final stock = double.tryParse(initialStockCtrl.text) ?? 0.0;
                      final alert = double.tryParse(alertCtrl.text) ?? 0.0;

                      final error = widget.onAddProduct?.call(
                        name: nameCtrl.text.trim(),
                        sellingPrice: sp,
                        mrp: mrp,
                        codes: codes,
                        initialStock: stock,
                        lowStockAlertLevel: alert,
                        taxRate: selectedTax,
                      );

                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${nameCtrl.text.trim()} added!'), backgroundColor: BrandPalette.teal),
                      );
                    },
                  ),
                ),
              ],
            ),
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
}
