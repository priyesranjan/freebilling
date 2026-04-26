import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';

class A4PdfService {
  static Future<Uint8List> generateA4Invoice(InvoiceRecord invoice) async {
    final pdf = pw.Document();

    final businessName = AppSettings.instance.businessName;
    final businessAddress = AppSettings.instance.businessAddress;
    final businessPhone = AppSettings.instance.businessPhone;
    final gstin = AppSettings.instance.gstin;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(businessName, businessAddress, businessPhone, gstin),
          pw.SizedBox(height: 20),
          _buildInvoiceInfo(invoice),
          pw.SizedBox(height: 30),
          _buildTable(invoice),
          pw.SizedBox(height: 20),
          _buildTotals(invoice),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String name, String address, String phone, String gstin) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),
            pw.Text(address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            if (gstin.isNotEmpty)
              pw.Text('GSTIN: $gstin', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Text('ORIGINAL FOR RECIPIENT', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceInfo(InvoiceRecord invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Billed To
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Billed To:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.customerName.isEmpty ? 'Walk-in Customer' : invoice.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              if (invoice.customerPhone.isNotEmpty)
                pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
              if (invoice.customerEmail != null && invoice.customerEmail!.isNotEmpty)
                pw.Text('Email: ${invoice.customerEmail}', style: const pw.TextStyle(fontSize: 10)),
              if (invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty)
                pw.Text('GSTIN: ${invoice.customerGstin}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        // Invoice Details
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildInfoRow('Invoice No:', invoice.id.substring(0, 12)),
              _buildInfoRow('Date:', DateFormat('dd MMM yyyy').format(invoice.createdAt)),
              _buildInfoRow('Time:', DateFormat('hh:mm a').format(invoice.createdAt)),
              _buildInfoRow('Payment Mode:', invoice.paymentMode.name.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(width: 8),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(InvoiceRecord invoice) {
    final headers = ['S.No', 'Item Description', 'Qty', 'Unit Price', 'Total'];

    final data = invoice.lines.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;
      return [
        index.toString(),
        item.product.name,
        item.quantity.toStringAsFixed(0),
        item.unitPrice.toStringAsFixed(2),
        item.finalAmount.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    );
  }

  static pw.Widget _buildTotals(InvoiceRecord invoice) {
    final subtotal = invoice.lines.fold(0.0, (sum, item) => sum + item.finalAmount);
    
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Subtotal:', subtotal.toStringAsFixed(2)),
            if (invoice.discountAmount > 0)
              _buildTotalRow('Discount:', '-${invoice.discountAmount.toStringAsFixed(2)}'),
            if (invoice.loyaltyPointsUsed > 0)
              _buildTotalRow('Points Redeemed:', '-${invoice.loyaltyPointsUsed.toStringAsFixed(2)}'),
            pw.Divider(color: PdfColors.grey400),
            _buildTotalRow('Grand Total:', invoice.total.toStringAsFixed(2), isGrandTotal: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, {bool isGrandTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: isGrandTotal ? 14 : 10, fontWeight: isGrandTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('Rs $amount', style: pw.TextStyle(fontSize: isGrandTotal ? 14 : 10, fontWeight: isGrandTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 4),
        pw.Text('Subject to local jurisdiction. Goods once sold will not be taken back.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    );
  }
}
