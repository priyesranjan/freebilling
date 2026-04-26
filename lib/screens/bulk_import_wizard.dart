import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../core/core.dart';
import 'dart:async';

class BulkImportWizard extends StatefulWidget {
  final void Function(List<Product>) onProductsExtracted;
  final String method; // 'excel', 'pdf', 'photo'

  const BulkImportWizard({
    super.key,
    required this.onProductsExtracted,
    required this.method,
  });

  @override
  State<BulkImportWizard> createState() => _BulkImportWizardState();
}

class _BulkImportWizardState extends State<BulkImportWizard> {
  int _step = 0; // 0 = uploading, 1 = analyzing, 2 = review
  List<Product> _extractedProducts = [];

  @override
  void initState() {
    super.initState();
    _startMockExtraction();
  }

  void _startMockExtraction() async {
    // Simulate uploading
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _step = 1);

    // Simulate AI extraction
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Generate mock products based on a "Studio" catalog vibe
    _extractedProducts = [
      Product(id: 'IMP-1', name: 'Pre-Wedding Shoot (Full Day)', sellingPrice: 25000, mrp: 30000, codes: ['PW-01']),
      Product(id: 'IMP-2', name: 'Drone Videography (4 Hours)', sellingPrice: 8000, mrp: 10000, codes: ['DR-02']),
      Product(id: 'IMP-3', name: 'Premium Photobook Album', sellingPrice: 5000, mrp: 6500, codes: ['AL-03']),
      Product(id: 'IMP-4', name: 'Candid Photography', sellingPrice: 15000, mrp: 18000, codes: ['CA-04']),
    ];

    setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: Text(
          widget.method == 'excel' ? 'Excel Import' :
          widget.method == 'pdf' ? 'AI PDF Scanner' : 'AI Photo Scanner'
        ),
        elevation: 0,
        backgroundColor: BrandPalette.pageBase,
        automaticallyImplyLeading: false,
        actions: [
          if (_step == 2)
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
        ],
      ),
      body: _step < 2 ? _buildLoadingStep() : _buildReviewStep(),
    );
  }

  Widget _buildLoadingStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _step == 0 ? 'Uploading file securely...' : 'AI is extracting items and prices...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BrandPalette.navy),
            ).animate().fade().slideY(begin: -0.2),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: double.infinity, height: 14, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Container(width: 100, height: 12, color: Colors.grey.shade300),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(width: 40, height: 16, color: Colors.grey.shade300),
                    ],
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .shimmer(duration: 1200.ms, color: Colors.white60),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: BrandPalette.mint.withValues(alpha: 0.4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: BrandPalette.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Extracted ${_extractedProducts.length} items successfully!',
                  style: const TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ).animate().fade(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _extractedProducts.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final p = _extractedProducts[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: BrandPalette.navy.withValues(alpha: 0.1),
                  child: const Icon(Icons.inventory_2, size: 18, color: BrandPalette.navy),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Code: ${p.codes.first}'),
                trailing: Text('₹${p.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              );
            },
          ).animate().fade().slideY(begin: 0.1),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                widget.onProductsExtracted(_extractedProducts);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: Text('Save ${_extractedProducts.length} Items to Inventory'),
              style: FilledButton.styleFrom(
                backgroundColor: BrandPalette.navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
