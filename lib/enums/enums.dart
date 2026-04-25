enum AppSection { home, items, invoices, khata, menu }

enum BillingPlan { free, basic, premium }

extension BillingPlanLabel on BillingPlan {
  String get label {
    switch (this) {
      case BillingPlan.free: return 'Free';
      case BillingPlan.basic: return 'Basic';
      case BillingPlan.premium: return 'Premium';
    }
  }
}

enum BusinessStatus { onboarded, suspended, deactivated, extended }

extension BusinessStatusLabel on BusinessStatus {
  String get label {
    switch (this) {
      case BusinessStatus.onboarded: return 'Onboarded';
      case BusinessStatus.suspended: return 'Suspended';
      case BusinessStatus.deactivated: return 'Deactivated';
      case BusinessStatus.extended: return 'Extended';
    }
  }
}

enum DeliveryChannel { whatsApp, email, sms }

extension DeliveryChannelLabel on DeliveryChannel {
  String get label {
    switch (this) {
      case DeliveryChannel.whatsApp: return 'WhatsApp';
      case DeliveryChannel.email: return 'Email';
      case DeliveryChannel.sms: return 'SMS';
    }
  }
}

enum PartyType { customer, supplier }

enum LedgerTransactionType { paymentIn, paymentOut, sale, purchase }

// --- New Enums for Vyapar-grade features ---

enum ExpenseCategory {
  transport,
  rent,
  salary,
  utilities,
  marketing,
  office,
  maintenance,
  food,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.transport: return 'Transport';
      case ExpenseCategory.rent: return 'Rent';
      case ExpenseCategory.salary: return 'Salary';
      case ExpenseCategory.utilities: return 'Utilities';
      case ExpenseCategory.marketing: return 'Marketing';
      case ExpenseCategory.office: return 'Office Supplies';
      case ExpenseCategory.maintenance: return 'Maintenance';
      case ExpenseCategory.food: return 'Food & Beverage';
      case ExpenseCategory.other: return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.transport: return '🚗';
      case ExpenseCategory.rent: return '🏠';
      case ExpenseCategory.salary: return '👨‍💼';
      case ExpenseCategory.utilities: return '💡';
      case ExpenseCategory.marketing: return '📣';
      case ExpenseCategory.office: return '🖊️';
      case ExpenseCategory.maintenance: return '🔧';
      case ExpenseCategory.food: return '🍽️';
      case ExpenseCategory.other: return '📦';
    }
  }
}

enum PaperSize { thermal80mm, thermal58mm, a4, a5 }

extension PaperSizeLabel on PaperSize {
  String get label {
    switch (this) {
      case PaperSize.thermal80mm: return 'Thermal 80mm';
      case PaperSize.thermal58mm: return 'Thermal 58mm';
      case PaperSize.a4: return 'A4 Paper';
      case PaperSize.a5: return 'A5 Paper';
    }
  }
}

enum ItemType { products, services, both }

extension ItemTypeLabel on ItemType {
  String get label {
    switch (this) {
      case ItemType.products: return 'Products Only';
      case ItemType.services: return 'Services Only';
      case ItemType.both: return 'Products and Services';
    }
  }
}

enum ReportPeriod { today, thisWeek, thisMonth, lastMonth, thisYear, custom }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today: return 'Today';
      case ReportPeriod.thisWeek: return 'This Week';
      case ReportPeriod.thisMonth: return 'This Month';
      case ReportPeriod.lastMonth: return 'Last Month';
      case ReportPeriod.thisYear: return 'This Year';
      case ReportPeriod.custom: return 'Custom Range';
    }
  }
}