import '../models/models.dart';

class ProfitAndLossReport {
  const ProfitAndLossReport({
    required this.totalSales,
    required this.totalTaxes,
    required this.netSales,
    required this.costOfGoodsSold,
    required this.grossProfit,
  });

  final double totalSales;
  final double totalTaxes;
  final double netSales;
  final double costOfGoodsSold;
  final double grossProfit;
}

class ReportingService {
  ReportingService._privateConstructor();
  static final ReportingService instance = ReportingService._privateConstructor();

  ProfitAndLossReport generatePnL(List<InvoiceRecord> invoices) {
    double totalSales = 0.0;
    double totalTaxes = 0.0;
    double costOfGoodsSold = 0.0; // In a full ERP, this comes from Purchase Orders/Batches

    for (var invoice in invoices) {
      totalSales += invoice.total;
      totalTaxes += invoice.totalTaxAmount;
      
      for (var line in invoice.lines) {
        // Mock COGS as 70% of sale price for now until Purchase flows are built
        costOfGoodsSold += (line.finalAmount * 0.70); 
      }
    }

    final double netSales = totalSales - totalTaxes;
    final double grossProfit = netSales - costOfGoodsSold;

    return ProfitAndLossReport(
      totalSales: totalSales,
      totalTaxes: totalTaxes,
      netSales: netSales,
      costOfGoodsSold: costOfGoodsSold,
      grossProfit: grossProfit,
    );
  }
}
