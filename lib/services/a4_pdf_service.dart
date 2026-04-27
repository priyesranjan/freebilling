import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'dart:io';

class A4PdfService {
  static pw.ImageProvider? signatureImage;

  static Future<Uint8List> generateA4Invoice(InvoiceRecord invoice) async {
    final pdf = pw.Document();

    final settings = AppSettings.instance;
    final businessName = settings.businessName;
    final businessAddress = settings.businessAddress;
    final businessPhone = settings.businessPhone;
    final gstin = settings.gstin;

    if (settings.businessSignature != null) {
      final file = File(settings.businessSignature!);
      if (file.existsSync()) {
        signatureImage = pw.MemoryImage(file.readAsBytesSync());
      }
    } else {
      signatureImage = null;
    }

    final theme = settings.invoiceTheme;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          if (theme == 'modern') return _buildModernLayout(invoice, businessName, businessAddress, businessPhone, gstin);
          if (theme == 'professional') return _buildProfessionalLayout(invoice, businessName, businessAddress, businessPhone, gstin);
          return _buildStandardLayout(invoice, businessName, businessAddress, businessPhone, gstin);
        },
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _buildStandardLayout(InvoiceRecord invoice, String name, String address, String phone, String gstin) {
    return [
      _buildHeader(name, address, phone, gstin, invoice.type),
      pw.SizedBox(height: 20),
      _buildInvoiceInfo(invoice),
      pw.SizedBox(height: 30),
      _buildTable(invoice),
      pw.SizedBox(height: 20),
      _buildTotals(invoice),
      pw.SizedBox(height: 20),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildQRCode(invoice),
              pw.SizedBox(width: 20),
              _buildCertifications(),
            ]
          ),
          if (signatureImage != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Image(signatureImage!, height: 50, fit: pw.BoxFit.contain),
                pw.SizedBox(height: 4),
                pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 20),
      _buildFooter(),
    ];
  }

  static pw.Widget _buildHeader(String name, String address, String phone, String gstin, DocumentType type) {
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
            pw.Text(type == DocumentType.quotation ? 'QUOTATION / ESTIMATE' : 'TAX INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
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

  static pw.Widget _buildQRCode(InvoiceRecord invoice) {
    final link = invoice.publicLink.isNotEmpty ? invoice.publicLink : 'http://nu1p4y93k9miuofk9jn5z4za.91.108.111.194.sslip.io/invoice/${invoice.id}';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('Scan to view online bill', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 6),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: link,
          width: 70,
          height: 70,
        ),
      ],
    );
  }

  static pw.Widget _buildCertifications() {
    final certs = AppSettings.instance.certifications;
    if (certs.isEmpty) return pw.SizedBox();

    return pw.Row(
      children: certs.map((c) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue900, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
          child: pw.Text(c, style: pw.TextStyle(fontSize: 8, color: PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
        );
      }).toList(),
    );
  }

  static List<pw.Widget> _buildModernLayout(InvoiceRecord invoice, String name, String address, String phone, String gstin) {
    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        color: PdfColors.indigo600,
        alignment: pw.Alignment.center,
        child: pw.Text(invoice.type == DocumentType.quotation ? 'QUOTATION' : 'SALES BILL', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(height: 10),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
           pw.Column(
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
               pw.Text(name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
               pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
               pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 10)),
             ]
           ),
           pw.Column(
             crossAxisAlignment: pw.CrossAxisAlignment.end,
             children: [
               if (gstin.isNotEmpty) pw.Text('GSTIN: $gstin', style: const pw.TextStyle(fontSize: 10)),
               pw.Text('Invoice No: ${invoice.id.substring(0, 12)}', style: const pw.TextStyle(fontSize: 10)),
               pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(invoice.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
             ]
           ),
        ]
      ),
      pw.SizedBox(height: 15),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(6),
        color: PdfColors.indigo600,
        child: pw.Text('Bill To:', style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(height: 6),
      pw.Text(invoice.customerName.isEmpty ? 'Walk-in Customer' : invoice.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      if (invoice.customerPhone.isNotEmpty) pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
      pw.SizedBox(height: 20),
      _buildModernTable(invoice),
      pw.SizedBox(height: 20),
      _buildTotals(invoice), // Reuse standard totals for now
      pw.SizedBox(height: 20),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              _buildQRCode(invoice),
              pw.SizedBox(width: 20),
              _buildCertifications(),
            ]
          ),
          if (signatureImage != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Image(signatureImage!, height: 50, fit: pw.BoxFit.contain),
                pw.SizedBox(height: 4),
                pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 20),
      _buildFooter(),
    ];
  }

  static pw.Widget _buildModernTable(InvoiceRecord invoice) {
    final headers = ['S.No', 'Goods Description', 'Qty', 'MRP', 'Amount'];
    final data = invoice.lines.asMap().entries.map((e) {
      final item = e.value;
      return [
        (e.key + 1).toString(),
        item.product.name,
        item.quantity.toStringAsFixed(0),
        item.unitPrice.toStringAsFixed(2),
        item.finalAmount.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.indigo200, width: 1),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo500),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: { 0: pw.Alignment.center, 1: pw.Alignment.centerLeft, 2: pw.Alignment.center, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight },
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  static List<pw.Widget> _buildProfessionalLayout(InvoiceRecord invoice, String name, String address, String phone, String gstin) {
    return [
      pw.Container(
        alignment: pw.Alignment.center,
        child: pw.Text(invoice.type == DocumentType.quotation ? 'QUOTATION' : 'TAX INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
        child: pw.Column(
          children: [
            // Top Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company Details
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 1))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                        if (gstin.isNotEmpty) pw.Text('GSTIN: $gstin', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                // Invoice Details
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Invoice No:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(invoice.id.substring(0, 12), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ]
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Dated:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(DateFormat('dd-MMM-yyyy').format(invoice.createdAt), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ]
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Mode of Payment:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(invoice.paymentMode.name.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                          ]
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            ),
            pw.Divider(color: PdfColors.black, thickness: 1, height: 0),
            // Buyer Section
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Buyer:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(invoice.customerName.isEmpty ? 'Walk-in Customer' : invoice.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  if (invoice.customerPhone.isNotEmpty) pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty) pw.Text('GSTIN: ${invoice.customerGstin}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ]
              ),
            ),
          ]
        ),
      ),
      pw.SizedBox(height: 10),
      _buildProfessionalTable(invoice),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Amount Chargeable (in words):', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('INR ${invoice.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildCertifications(),
                pw.SizedBox(height: 10),
                _buildQRCode(invoice),
              ]
            ),
            if (signatureImage != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('for $name', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Image(signatureImage!, height: 50, fit: pw.BoxFit.contain),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
          ]
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Text('This is a Computer Generated Invoice', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    ];
  }

  static pw.Widget _buildProfessionalTable(InvoiceRecord invoice) {
    final headers = ['Sl No.', 'Description of Goods', 'Qty', 'Rate', 'Amount'];
    final data = invoice.lines.asMap().entries.map((e) {
      final item = e.value;
      return [
        (e.key + 1).toString(),
        item.product.name,
        item.quantity.toStringAsFixed(0),
        item.unitPrice.toStringAsFixed(2),
        item.finalAmount.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: { 0: pw.Alignment.center, 1: pw.Alignment.centerLeft, 2: pw.Alignment.center, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight },
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }
}
