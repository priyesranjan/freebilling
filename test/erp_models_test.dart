import 'package:flutter_test/flutter_test.dart';
import 'package:erp_bill/models/models.dart';
import 'package:erp_bill/services/reporting_service.dart';

void main() {
  group('Advanced Inventory Tests', () {
    test('Product stock should calculate sum of all active batches', () {
      final product = Product(
        id: 'P1',
        name: 'Test Product',
        price: 100,
        codes: const ['001'],
        taxRate: TaxRate.eighteen,
        batches: [
          ProductBatch(
            batchNumber: 'B1',
            mfgDate: DateTime.now().subtract(const Duration(days: 10)),
            expiryDate: DateTime.now().add(const Duration(days: 30)),
            stockCount: 50.0,
          ),
          ProductBatch(
            batchNumber: 'B2',
            mfgDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 60)),
            stockCount: 25.0,
          ),
        ],
      );

      expect(product.currentStock, 75.0);
    });
  });

  group('GST Tax Calculation Tests', () {
    final product18 = Product(
      id: 'P18',
      name: 'Item 18%',
      price: 100,
      codes: const ['001'],
      taxRate: TaxRate.eighteen, // 18% GST
    );
    final product5 = Product(
      id: 'P5',
      name: 'Item 5%',
      price: 200,
      codes: const ['002'],
      taxRate: TaxRate.five, // 5% GST
    );

    test('CartItem tax amount should calculate correctly based on quantity', () {
      final item1 = CartItem(product: product18, quantity: 2); // 200 total, 18% tax -> 36
      final item2 = CartItem(product: product5, quantity: 1); // 200 total, 5% tax -> 10

      expect(item1.taxAmount, 36.0);
      expect(item1.finalAmount, 236.0);

      expect(item2.taxAmount, 10.0);
      expect(item2.finalAmount, 210.0);
    });

    test('InvoiceRecord Intra-State should split into CGST and SGST', () {
      final invoice = InvoiceRecord(
        id: 'INV01',
        createdAt: DateTime.now(),
        customerName: 'Local Customer',
        customerPhone: '1234567890',
        customerEmail: 'test@example.com',
        total: 446.0,
        lines: [
          CartItem(product: product18, quantity: 2), // Tax = 36
          CartItem(product: product5, quantity: 1),  // Tax = 10
        ],
        channels: {},
        publicLink: '',
        isInterState: false, // Intra-State -> Split
      );

      expect(invoice.totalTaxAmount, 46.0);
      expect(invoice.cgstAmount, 23.0); // 46 / 2
      expect(invoice.sgstAmount, 23.0);
      expect(invoice.igstAmount, 0.0);
    });

    test('InvoiceRecord Inter-State should allocate all to IGST', () {
      final invoice = InvoiceRecord(
        id: 'INV02',
        createdAt: DateTime.now(),
        customerName: 'Out-of-State Customer',
        customerPhone: '1234567890',
        customerEmail: 'test2@example.com',
        total: 446.0,
        lines: [
          CartItem(product: product18, quantity: 2), // Tax = 36
          CartItem(product: product5, quantity: 1),  // Tax = 10
        ],
        channels: {},
        publicLink: '',
        isInterState: true, // Inter-State -> IGST
      );

      expect(invoice.totalTaxAmount, 46.0);
      expect(invoice.cgstAmount, 0.0);
      expect(invoice.sgstAmount, 0.0);
      expect(invoice.igstAmount, 46.0);
    });
  });

  group('Reporting Service (P&L) Tests', () {
    final product = Product(
      id: 'P',
      name: 'Item',
      price: 100, // Pre-tax price
      codes: const ['000'],
      taxRate: TaxRate.twelve, // 12%
    );

    test('ProfitAndLossReport should correctly sum metrics', () {
      final invoice1 = InvoiceRecord(
        id: 'I1',
        createdAt: DateTime.now(),
        customerName: 'C1',
        customerPhone: 'P1',
        customerEmail: 'c1@example.com',
        total: 112.0, // 100 + 12 tax
        lines: [CartItem(product: product, quantity: 1)], // finalAmount = 112
        channels: {},
        publicLink: '',
      );
      final invoice2 = InvoiceRecord(
        id: 'I2',
        createdAt: DateTime.now(),
        customerName: 'C2',
        customerPhone: 'P2',
        customerEmail: 'c2@example.com',
        total: 224.0, // 200 + 24 tax
        lines: [CartItem(product: product, quantity: 2)], // finalAmount = 224
        channels: {},
        publicLink: '',
      );

      final pnl = ReportingService.instance.generatePnL([invoice1, invoice2]);

      expect(pnl.totalSales, 336.0); // 112 + 224
      expect(pnl.totalTaxes, 36.0); // 12 + 24
      expect(pnl.netSales, 300.0); // 336 - 36
      // COGS is currently mocked as 70% of finalAmount (336 * 0.7 = 235.2)
      expect(pnl.costOfGoodsSold, closeTo(235.2, 0.01));
      expect(pnl.grossProfit, closeTo(64.8, 0.01)); // 300 - 235.2
    });
  });
}
