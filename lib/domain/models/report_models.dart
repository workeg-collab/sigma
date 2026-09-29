import 'account.dart';

/// Trial Balance row model supporting both "By Totals" and "By Balances"
class TrialBalanceItem {
  final Account account;
  final double openingDebit;
  final double openingCredit;
  final double movementDebit;
  final double movementCredit;
  final double closingDebit;
  final double closingCredit;

  TrialBalanceItem({
    required this.account,
    this.openingDebit = 0.0,
    this.openingCredit = 0.0,
    this.movementDebit = 0.0,
    this.movementCredit = 0.0,
    this.closingDebit = 0.0,
    this.closingCredit = 0.0,
  });

  // For Totals
  double get totalDebit => openingDebit + movementDebit;
  double get totalCredit => openingCredit + movementCredit;
  double get difference => (totalDebit - totalCredit).abs();
}

/// Trial Balance Report container
class TrialBalanceReport {
  final List<TrialBalanceItem> items;
  final double totalOpeningDebit;
  final double totalOpeningCredit;
  final double totalMovementDebit;
  final double totalMovementCredit;
  final double totalClosingDebit;
  final double totalClosingCredit;
  final bool isBalanced;

  TrialBalanceReport({
    required this.items,
    required this.totalOpeningDebit,
    required this.totalOpeningCredit,
    required this.totalMovementDebit,
    required this.totalMovementCredit,
    required this.totalClosingDebit,
    required this.totalClosingCredit,
    required this.isBalanced,
  });
}

/// General Ledger and Account Statement row item
class LedgerRow {
  final int? journalEntryId;
  final String date;
  final String entryNumber;
  final String description;
  final String? projectName;
  final String? analyticalName;
  final String? unitName;
  final double quantity;
  final double unitPrice;
  final double debit;
  final double credit;
  final double runningBalance;
  final String? contractorName;
  final String? supplierName;
  final String? customerName;

  LedgerRow({
    this.journalEntryId,
    required this.date,
    required this.entryNumber,
    required this.description,
    this.projectName,
    this.analyticalName,
    this.unitName,
    this.quantity = 0.0,
    this.unitPrice = 0.0,
    this.debit = 0.0,
    this.credit = 0.0,
    required this.runningBalance,
    this.contractorName,
    this.supplierName,
    this.customerName,
  });
}

/// Project cost and profitability breakdown
class ProjectCostReport {
  final int projectId;
  final String projectCode;
  final String projectName;
  final String? client;
  final double budget;
  final double revenue;
  
  // Categorized Costs
  final double directMaterials;
  final double labor;
  final double equipment;
  final double subcontractors;
  final double transportation;
  final double maintenance;
  final double siteExpenses;
  final double generalExpenses;
  final double otherCosts;

  final double totalCost;
  final double grossProfit;
  final double profitMargin; // percentage 0-100

  // Cost by Analytical item
  final Map<String, double> costByAnalyticalItem;
  // Cost by Account
  final Map<String, double> costByAccount;

  ProjectCostReport({
    required this.projectId,
    required this.projectCode,
    required this.projectName,
    this.client,
    this.budget = 0.0,
    required this.revenue,
    required this.directMaterials,
    required this.labor,
    required this.equipment,
    required this.subcontractors,
    required this.transportation,
    required this.maintenance,
    required this.siteExpenses,
    required this.generalExpenses,
    required this.otherCosts,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMargin,
    this.costByAnalyticalItem = const {},
    this.costByAccount = const {},
  });
}

/// Contractor Ledger row
class ContractorLedgerRow {
  final int? journalEntryId;
  final String date;
  final String entryNumber;
  final String description;
  final String? projectName;
  final double debit;  // Paid to contractor
  final double credit; // المستحق للمقاول (Work done)
  final double runningBalance;

  ContractorLedgerRow({
    this.journalEntryId,
    required this.date,
    required this.entryNumber,
    required this.description,
    this.projectName,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
}

/// Financial Statements
class IncomeStatementReport {
  final double grossSales;
  final double salesReturns;
  final double netSales;

  final double openingInventory;
  final double purchases;
  final double purchaseReturns;
  final double directProjectCosts;
  final double costOfSales;

  final double grossProfit;

  final double generalAdminExpenses;
  final double operatingExpenses;
  final double siteExpenses;
  final double totalOperatingExpenses;

  final double operatingProfit;

  final double otherIncome;
  final double depreciationExpense;
  final double profitBeforeTax;

  final double taxExpense;
  final double netProfit;

  // Granular details
  final Map<String, double> revenueDetails;
  final Map<String, double> costDetails;
  final Map<String, double> expenseDetails;

  IncomeStatementReport({
    required this.grossSales,
    required this.salesReturns,
    required this.netSales,
    required this.openingInventory,
    required this.purchases,
    required this.purchaseReturns,
    required this.directProjectCosts,
    required this.costOfSales,
    required this.grossProfit,
    required this.generalAdminExpenses,
    required this.operatingExpenses,
    required this.siteExpenses,
    required this.totalOperatingExpenses,
    required this.operatingProfit,
    required this.otherIncome,
    required this.depreciationExpense,
    required this.profitBeforeTax,
    required this.taxExpense,
    required this.netProfit,
    this.revenueDetails = const {},
    this.costDetails = const {},
    this.expenseDetails = const {},
  });
}

class BalanceSheetSectionItem {
  final String code;
  final String name;
  final double amount;

  BalanceSheetSectionItem({required this.code, required this.name, required this.amount});
}

class BalanceSheetReport {
  // Assets
  final List<BalanceSheetSectionItem> currentAssets;
  final double totalCurrentAssets;
  final List<BalanceSheetSectionItem> fixedAssets;
  final double totalFixedAssets;
  final double accumulatedDepreciation;
  final double netFixedAssets;
  final double totalAssets;

  // Liabilities
  final List<BalanceSheetSectionItem> currentLiabilities;
  final double contractorBalances;
  final double taxLiabilities;
  final double totalCurrentLiabilities;
  final List<BalanceSheetSectionItem> longTermLiabilities;
  final double totalLongTermLiabilities;
  final double totalLiabilities;

  // Equity
  final double capital;
  final double partnersCurrentAccounts;
  final double retainedEarnings;
  final double currentYearProfit;
  final double totalEquity;

  final double totalLiabilitiesAndEquity;
  final bool isBalanced;
  final double difference;

  BalanceSheetReport({
    required this.currentAssets,
    required this.totalCurrentAssets,
    required this.fixedAssets,
    required this.totalFixedAssets,
    required this.accumulatedDepreciation,
    required this.netFixedAssets,
    required this.totalAssets,
    required this.currentLiabilities,
    required this.contractorBalances,
    required this.taxLiabilities,
    required this.totalCurrentLiabilities,
    required this.longTermLiabilities,
    required this.totalLongTermLiabilities,
    required this.totalLiabilities,
    required this.capital,
    required this.partnersCurrentAccounts,
    required this.retainedEarnings,
    required this.currentYearProfit,
    required this.totalEquity,
    required this.totalLiabilitiesAndEquity,
    required this.isBalanced,
    required this.difference,
  });
}

/// Cash & Bank Position
class CashBankPositionItem {
  final int accountId;
  final String code;
  final String name;
  final String type; // 'cash' or 'bank'
  final double openingBalance;
  final double debitMovement;
  final double creditMovement;
  final double currentBalance;

  CashBankPositionItem({
    required this.accountId,
    required this.code,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.debitMovement,
    required this.creditMovement,
    required this.currentBalance,
  });
}
