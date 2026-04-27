import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../core/core.dart';
import '../enums/enums.dart';

class AllTransactionsScreen extends StatelessWidget {
  final List<InvoiceRecord> invoices;
  final List<ExpenseRecord> expenses;

  const AllTransactionsScreen({
    super.key,
    required this.invoices,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    // Merge both lists into a single chronological timeline
    final List<dynamic> timeline = [...invoices, ...expenses]
      ..sort((a, b) {
        final dateA = (a is InvoiceRecord) ? a.createdAt : (a as ExpenseRecord).date;
        final dateB = (b is InvoiceRecord) ? b.createdAt : (b as ExpenseRecord).date;
        return dateB.compareTo(dateA); // Newest first
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: timeline.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No transactions found.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final item = timeline[index];

                if (item is InvoiceRecord) {
                  return _buildInvoiceCard(item);
                } else if (item is ExpenseRecord) {
                  return _buildExpenseCard(item);
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _buildInvoiceCard(InvoiceRecord inv) {
    final bool isCredit = inv.paymentMode == PaymentMode.credit;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.customerName.isEmpty ? 'Walk-in Customer' : inv.customerName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                ),
                Text(
                  'Sale #${inv.id.substring(inv.id.length > 5 ? inv.id.length - 5 : 0)} • ${formatDate(inv.createdAt)}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+ ₹${inv.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
              if (isCredit)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('DUE', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('PAID', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseRecord exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_upward, color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.category.name.toUpperCase(),
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                ),
                Text(
                  'Expense • ${formatDate(exp.date)}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
                if (exp.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(exp.note, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )
              ],
            ),
          ),
          Text('- ₹${exp.amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
