import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../core/core.dart';

class GlobalSearchScreen extends StatefulWidget {
  final List<BusinessRecord> businesses;
  final List<Product> products;
  final List<InvoiceRecord> invoices;
  final List<PartyRecord> parties;
  final List<ExpenseRecord> expenses;

  const GlobalSearchScreen({
    super.key,
    required this.businesses,
    required this.products,
    required this.invoices,
    required this.parties,
    required this.expenses,
  });

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    List<Product> matchedProducts = [];
    List<PartyRecord> matchedParties = [];
    List<InvoiceRecord> matchedInvoices = [];

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      
      matchedProducts = widget.products.where((p) => 
        p.name.toLowerCase().contains(q) || 
        p.codes.any((c) => c.toLowerCase().contains(q))
      ).toList();

      matchedParties = widget.parties.where((p) => 
        p.name.toLowerCase().contains(q) || 
        p.phone.contains(q)
      ).toList();

      matchedInvoices = widget.invoices.where((i) => 
        i.id.toLowerCase().contains(q) || 
        i.customerName.toLowerCase().contains(q) ||
        i.customerPhone.contains(q)
      ).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products, parties, bills...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ) : null,
          ),
          onChanged: (val) => setState(() => _query = val.trim()),
        ),
      ),
      body: _query.isEmpty
        ? Center(child: Text('Type to search across your business', style: TextStyle(color: Colors.grey.shade500)))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (matchedProducts.isNotEmpty) ...[
                _buildSectionHeader('Products', Icons.inventory_2),
                ...matchedProducts.map((p) => _buildProductTile(p)),
                const SizedBox(height: 16),
              ],
              if (matchedParties.isNotEmpty) ...[
                _buildSectionHeader('Parties', Icons.people),
                ...matchedParties.map((p) => _buildPartyTile(p)),
                const SizedBox(height: 16),
              ],
              if (matchedInvoices.isNotEmpty) ...[
                _buildSectionHeader('Bills & Invoices', Icons.receipt_long),
                ...matchedInvoices.map((i) => _buildInvoiceTile(i)),
              ],
              if (matchedProducts.isEmpty && matchedParties.isEmpty && matchedInvoices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('No results found for "$_query"', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildProductTile(Product p) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Stock: ${p.currentStock.toStringAsFixed(0)} | ₹${p.sellingPrice.toStringAsFixed(0)}'),
        leading: CircleAvatar(backgroundColor: const Color(0xFF1A6FE3).withOpacity(0.1), child: const Icon(Icons.inventory_2, color: Color(0xFF1A6FE3))),
      ),
    );
  }

  Widget _buildPartyTile(PartyRecord p) {
    final isToGet = p.balance > 0;
    final pColor = isToGet ? const Color(0xFF0DAB76) : const Color(0xFFE05252);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(p.phone),
        leading: CircleAvatar(backgroundColor: pColor.withOpacity(0.1), child: Text(p.name[0], style: TextStyle(color: pColor, fontWeight: FontWeight.bold))),
        trailing: Text('₹${p.balance.abs().toStringAsFixed(0)}', style: TextStyle(color: pColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInvoiceTile(InvoiceRecord inv) {
    final isCredit = inv.paymentMode == PaymentMode.credit;
    final statusColor = isCredit ? const Color(0xFFE05252) : const Color(0xFF0DAB76);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(inv.customerName.isEmpty ? 'Walk-in Customer' : inv.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Bill #${inv.id.substring(inv.id.length > 6 ? inv.id.length - 6 : 0)}'),
        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(Icons.receipt, color: statusColor)),
        trailing: Text('₹${inv.total.toStringAsFixed(0)}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
