import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'dart:io';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice(InvoiceRecord invoice, BusinessRecord business) async {
    final pdf = pw.Document();
    
    final settings = AppSettings.instance;
    if (settings.businessSignature != null) {
      final file = File(settings.businessSignature!);
      if (file.existsSync()) {
        signatureImage = pw.MemoryImage(file.readAsBytesSync());
      }
    } else {
      signatureImage = null;
    }

    // 80mm roll width is approx 226 points (80mm / 25.4 * 72)
    const double rollWidth = 226.77; 

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(rollWidth, double.infinity, marginAll: 10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice, business),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildCustomerInfo(invoice),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildInvoiceTable(invoice),
              pw.Divider(borderStyle: pw.BorderStyle.solid),
              _buildTotal(invoice),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildTermsAndConditions(),
              _buildQRCode(invoice),
              if (signatureImage != null)
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  margin: const pw.EdgeInsets.only(top: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Image(signatureImage!, height: 40, fit: pw.BoxFit.contain),
                      pw.SizedBox(height: 2),
                      pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              pw.SizedBox(height: 10),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.ImageProvider? signatureImage;

  static pw.Widget _buildHeader(InvoiceRecord invoice, BusinessRecord business) {
    final settings = AppSettings.instance;
    final bName = settings.businessName.isNotEmpty ? settings.businessName : business.businessName;
    final bAddress = settings.businessAddress.isNotEmpty ? settings.businessAddress : 'ADDRESS PLACEHOLDER, CITY';
    final bPhone = settings.businessPhone.isNotEmpty ? settings.businessPhone : '';
    final bGstin = settings.gstin.isNotEmpty ? settings.gstin : invoice.businessGstin;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('!! SHREE GANESHYA NAMAH !!', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text(bName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text(business.category?.toUpperCase() ?? 'FASHION & RETAIL', style: const pw.TextStyle(fontSize: 9)),
        pw.Text(bAddress, style: const pw.TextStyle(fontSize: 9)),
        if (bPhone.isNotEmpty) pw.Text('Ph: $bPhone', style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 4),
        if (bGstin != null && bGstin.isNotEmpty) pw.Text('GSTIN : $bGstin', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: pw.Text(invoice.type == DocumentType.quotation ? 'QUOTATION / ESTIMATE' : 'TAX INVOICE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(InvoiceRecord invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Invoice No/Date :', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('${invoice.id} / ${DateFormat('dd-MM-yyyy').format(invoice.createdAt)}', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Customer Name :', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(invoice.customerName.isEmpty ? 'Walk-in' : invoice.customerName.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        if (invoice.customerPhone.isNotEmpty)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Cust Mobile No :', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(invoice.customerPhone, style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        if (invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Cust GST.No. :', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(invoice.customerGstin!, style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceTable(InvoiceRecord invoice) {
    return pw.Column(
      children: [
        // Table Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(flex: 3, child: pw.Text('Product', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Amt.', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          ]
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(flex: 1, child: pw.Text('Qty.', style: const pw.TextStyle(fontSize: 8))),
            pw.Expanded(flex: 2, child: pw.Text('Barcode', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
            pw.Expanded(flex: 2, child: pw.Text('HSN Code', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
            pw.Expanded(flex: 1, child: pw.Text('GST %', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
            pw.Expanded(flex: 1, child: pw.Text('GST Amt', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
          ]
        ),
        pw.Divider(borderStyle: pw.BorderStyle.solid, thickness: 0.5),
        
        // Table Rows
        ...invoice.lines.asMap().entries.map((entry) {
          final int idx = entry.key + 1;
          final item = entry.value;
          final double basePrice = item.unitPrice - item.taxAmount;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text('$idx ${item.product.name.toUpperCase()}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text(basePrice.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text(item.finalAmount.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ]
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(flex: 1, child: pw.Text(item.quantity.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))),
                    pw.Expanded(flex: 2, child: pw.Text(item.product.codes.isNotEmpty ? item.product.codes.first : '-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                    pw.Expanded(flex: 2, child: pw.Text('-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))), // HSN placeholder
                    pw.Expanded(flex: 1, child: pw.Text('${item.product.taxRate.name}%', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                    pw.Expanded(flex: 1, child: pw.Text((item.taxAmount * item.quantity).toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                  ]
                ),
              ],
            )
          );
        }),
      ]
    );
  }

  static pw.Widget _buildTotal(InvoiceRecord invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(invoice.lines.length.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(invoice.total.toStringAsFixed(2), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            pw.Text('Rupees  ', style: const pw.TextStyle(fontSize: 9)),
            // Number to words would go here in a full implementation
            pw.Text('${invoice.total.toInt()} Only', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ]
        ),
        pw.Divider(borderStyle: pw.BorderStyle.solid, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total GST', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(':    ${invoice.totalTaxAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Net Payable', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(':    ${invoice.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]
        ),
      ]
    );
  }

  static pw.Widget _buildTermsAndConditions() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('*NO CASH REFUND. *EXCHANGE WITHIN SEVEN DAYS', style: const pw.TextStyle(fontSize: 8)),
        pw.Text(' IN GOOD CONDITION WITH BILL AND TAGS.', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('*The goods exchange will be in the same store', style: const pw.TextStyle(fontSize: 8)),
        pw.Text(' from where the goods will be purchased.', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('*NO GUARANTEE OF FABRIC, JARI & COLOUR.', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('*SUBJECT TO LOCAL JURISDICTION.', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ]
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(borderStyle: pw.BorderStyle.solid, thickness: 0.5),
        pw.Row(
          children: [
            pw.Text('SALESMEN NAME : ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text('ADMIN', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ]
        ),
        pw.Row(
          children: [
            pw.Text('TIME            : ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text(DateFormat('hh:mm a').format(DateTime.now()), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ]
        ),
        pw.Divider(borderStyle: pw.BorderStyle.solid, thickness: 0.5),
        pw.Center(
          child: pw.Text('Powered by FreeBilling Platform', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700))
        ),
      ],
    );
  }

  static pw.Widget _buildQRCode(InvoiceRecord invoice) {
    final link = invoice.publicLink.isNotEmpty ? invoice.publicLink : 'http://nu1p4y93k9miuofk9jn5z4za.91.108.111.194.sslip.io/invoice/${invoice.id}';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text('Scan to view bill online', style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: link,
            width: 60,
            height: 60,
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }
}
