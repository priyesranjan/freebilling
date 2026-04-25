import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice(InvoiceRecord invoice, BusinessRecord business) async {
    final pdf = pw.Document();

    // In a real app, you might want to load custom fonts here to support ₹ symbol and other characters nicely.
    // For now, we use default fonts.

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice, business),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(invoice),
              pw.SizedBox(height: 20),
              _buildInvoiceTable(invoice),
              pw.Divider(),
              _buildTotal(invoice),
              pw.SizedBox(height: 30),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(InvoiceRecord invoice, BusinessRecord business) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(business.businessName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Phone: ${business.ownerName}'), // Using ownerName as placeholder for phone if not present
            // If BusinessRecord had address/email, add them here.
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
            pw.Text('Invoice #: ${invoice.id}'),
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(invoice.createdAt)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(InvoiceRecord invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.SizedBox(height: 4),
        pw.Text('Name: ${invoice.customerName.isEmpty ? "Walk-in Customer" : invoice.customerName}'),
        if (invoice.customerPhone.isNotEmpty) pw.Text('Phone: ${invoice.customerPhone}'),
      ],
    );
  }

  static pw.Widget _buildInvoiceTable(InvoiceRecord invoice) {
    return pw.TableHelper.fromTextArray(
      headers: ['Item', 'Qty', 'Price', 'Total'],
      data: invoice.lines.map((item) {
        return [
          item.product.name,
          item.quantity.toString(),
          item.unitPrice.toStringAsFixed(2),
          (item.quantity * item.unitPrice).toStringAsFixed(2),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotal(InvoiceRecord invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('Grand Total: ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            'Rs. ${invoice.total.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
        pw.Text('Powered by ERP Bill Platform', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ],
    );
  }
}
