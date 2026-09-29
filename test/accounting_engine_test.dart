import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sigma/core/constants/app_constants.dart';
import 'package:sigma/core/database/database_helper.dart';
import 'package:sigma/domain/models/journal_entry.dart';
import 'package:sigma/domain/models/journal_line.dart';
import 'package:sigma/data/repositories/account_repository.dart';
import 'package:sigma/data/repositories/journal_repository.dart';
import 'package:sigma/data/repositories/fiscal_repository.dart';
import 'package:sigma/domain/services/accounting_engine.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Double-Entry Accounting & Engine Tests', () {
    late Database db;
    late AccountRepository accountRepo;
    late FiscalRepository fiscalRepo;
    late JournalRepository journalRepo;
    late AccountingEngine engine;

    setUp(() async {
      db = await DatabaseHelper.createInMemoryDatabase();
      accountRepo = AccountRepository(overrideDb: db);
      fiscalRepo = FiscalRepository(overrideDb: db);
      journalRepo = JournalRepository(overrideDb: db, fiscalRepo: fiscalRepo);
      engine = AccountingEngine(overrideDb: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial seeded accounts are loaded properly', () async {
      final accounts = await accountRepo.getAllAccounts();
      expect(accounts.isNotEmpty, isTrue);

      final cash = await accountRepo.getAccountByCode('1101');
      expect(cash, isNotNull);
      expect(cash!.nameAr, contains('الصندوق'));
      expect(cash.normalBalance, NormalBalance.debit);

      final capital = await accountRepo.getAccountByCode('3101');
      expect(capital, isNotNull);
      expect(capital!.nameAr, contains('رأس المال'));
      expect(capital.normalBalance, NormalBalance.credit);
    });

    test('Journal Posting: Balanced transaction posts successfully', () async {
      final cash = await accountRepo.getAccountByCode('1101');
      final capital = await accountRepo.getAccountByCode('3101');

      final entry = JournalEntry(
        entryNumber: 'JE-00001',
        date: '2026-01-15',
        description: 'إيداع رأس المال في الخزينة',
        status: JournalStatus.draft,
        lines: [
          JournalLine(
            accountId: cash!.id!,
            debit: 500000.0,
            credit: 0.0,
            description: 'إيداع الخزينة',
          ),
          JournalLine(
            accountId: capital!.id!,
            debit: 0.0,
            credit: 500000.0,
            description: 'رأس مال الشركاء',
          ),
        ],
      );

      final entryId = await journalRepo.createJournalEntry(entry);
      expect(entryId, greaterThan(0));

      // Post the entry
      await journalRepo.postJournalEntry(entryId, postedBy: 'admin');

      final posted = await journalRepo.getJournalEntryById(entryId);
      expect(posted!.status, JournalStatus.posted);
      expect(posted.postedBy, 'admin');

      // Check Trial Balance
      final trialBalance = await engine.getTrialBalance();
      expect(trialBalance.isBalanced, isTrue);
      expect(trialBalance.totalClosingDebit, 500000.0);
      expect(trialBalance.totalClosingCredit, 500000.0);

      // Check Balance Sheet
      final balanceSheet = await engine.getBalanceSheet();
      expect(balanceSheet.isBalanced, isTrue);
      expect(balanceSheet.totalAssets, 500000.0);
      expect(balanceSheet.totalEquity, 500000.0);
      expect(balanceSheet.totalLiabilitiesAndEquity, 500000.0);
    });

    test('Journal Posting: Unbalanced entry throws validation exception', () async {
      final cash = await accountRepo.getAccountByCode('1101');
      final capital = await accountRepo.getAccountByCode('3101');

      final entry = JournalEntry(
        entryNumber: 'JE-ERR01',
        date: '2026-02-10',
        description: 'قيد غير متزن',
        status: JournalStatus.draft,
        lines: [
          JournalLine(
            accountId: cash!.id!,
            debit: 100000.0,
            credit: 0.0,
          ),
          JournalLine(
            accountId: capital!.id!,
            debit: 0.0,
            credit: 90000.0, // Unbalanced by 10,000!
          ),
        ],
      );

      final entryId = await journalRepo.createJournalEntry(entry);

      expect(
        () async => await journalRepo.postJournalEntry(entryId, postedBy: 'admin'),
        throwsA(isA<Exception>()),
      );
    });

    test('Journal Posting: Mutual exclusivity of Debit and Credit per line', () async {
      final cash = await accountRepo.getAccountByCode('1101');
      final entry = JournalEntry(
        entryNumber: 'JE-ERR02',
        date: '2026-02-10',
        description: 'خطأ مدين ودائن في نفس السطر',
        status: JournalStatus.draft,
        lines: [
          JournalLine(
            accountId: cash!.id!,
            debit: 5000.0,
            credit: 5000.0, // Invalid!
          ),
          JournalLine(
            accountId: cash.id!,
            debit: 0.0,
            credit: 0.0,
          ),
        ],
      );

      final entryId = await journalRepo.createJournalEntry(entry);
      expect(
        () async => await journalRepo.postJournalEntry(entryId, postedBy: 'admin'),
        throwsA(isA<Exception>()),
      );
    });

    test('Posting in closed period is strictly rejected', () async {
      final cash = await accountRepo.getAccountByCode('1101');
      final capital = await accountRepo.getAccountByCode('3101');

      // Close period 1 (January)
      final periods = await fiscalRepo.getPeriodsForFiscalYear(1);
      final janPeriod = periods.first;
      await fiscalRepo.togglePeriodClosed(janPeriod.id!, true, username: 'admin');

      final entry = JournalEntry(
        entryNumber: 'JE-CLOSED',
        date: '2026-01-20', // Falls inside closed period!
        description: 'محاولة ترحيل في فترة مغلقة',
        status: JournalStatus.draft,
        lines: [
          JournalLine(accountId: cash!.id!, debit: 10000.0, credit: 0.0),
          JournalLine(accountId: capital!.id!, debit: 0.0, credit: 10000.0),
        ],
      );

      final entryId = await journalRepo.createJournalEntry(entry);

      expect(
        () async => await journalRepo.postJournalEntry(entryId, postedBy: 'admin'),
        throwsA(isA<Exception>()),
      );
    });

    test('Project cost calculation and contractor running balance', () async {
      final materials = await accountRepo.getAccountByCode('5101');
      final subAccount = await accountRepo.getAccountByCode('2102'); // مقاولين

      // Subcontractor entry for Project 1 (نيوم أكتوبر فيلات)
      final entry = JournalEntry(
        entryNumber: 'JE-PRJ01',
        date: '2026-03-01',
        description: 'أعمال نجارة مسلحة لمقاولات الأمل',
        projectId: 1,
        status: JournalStatus.draft,
        lines: [
          JournalLine(
            accountId: materials!.id!,
            projectId: 1,
            analyticalItemId: 2, // النجارة المسلحة
            quantity: 50.0,
            unitPrice: 2000.0,
            debit: 100000.0,
            credit: 0.0,
          ),
          JournalLine(
            accountId: subAccount!.id!,
            projectId: 1,
            contractorId: 1,
            debit: 0.0,
            credit: 100000.0,
          ),
        ],
      );

      final entryId = await journalRepo.createJournalEntry(entry);
      await journalRepo.postJournalEntry(entryId, postedBy: 'admin');

      // Verify Project Cost Report
      final costReport = await engine.getProjectCostReport(1);
      expect(costReport.totalCost, 100000.0);
      expect(costReport.subcontractors, 100000.0);

      // Verify Contractor statement
      final contractorStatement = await engine.getContractorStatement(1);
      expect(contractorStatement.isNotEmpty, isTrue);
      expect(contractorStatement.last.runningBalance, 100000.0);
      expect(contractorStatement.last.credit, 100000.0);
    });
  });
}
