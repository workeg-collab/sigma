import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../domain/models/journal_entry.dart';
import '../../domain/models/journal_line.dart';
import '../../data/repositories/journal_repository.dart';
import '../../core/services/audit_service.dart';

class JournalProvider extends ChangeNotifier {
  final JournalRepository _journalRepo;
  final AuditService _auditService;

  JournalProvider({
    JournalRepository? journalRepo,
    required AuditService auditService,
  })  : _journalRepo = journalRepo ?? JournalRepository(),
        _auditService = auditService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => _entries;

  // Filter criteria
  String? filterDateFrom;
  String? filterDateTo;
  int? filterProjectId;
  String? filterStatus = 'all';
  String? filterSearch;

  // Active Editing Entry
  JournalEntry? activeEntry;
  List<JournalLine> activeLines = [];
  Map<int, List<String>> lineValidationErrors = {};

  double get currentTotalDebit => activeLines.fold(0.0, (sum, l) => sum + l.debit);
  double get currentTotalCredit => activeLines.fold(0.0, (sum, l) => sum + l.credit);
  double get currentDifference => (currentTotalDebit - currentTotalCredit).abs();
  bool get isCurrentBalanced => currentDifference < 0.0001 && activeLines.isNotEmpty;

  Future<String> getNextEntryNumber() => _journalRepo.getNextEntryNumber();
  Future<int> createJournalEntry(JournalEntry entry) => _journalRepo.createJournalEntry(entry);

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _journalRepo.getJournalEntries(
        dateFrom: filterDateFrom,
        dateTo: filterDateTo,
        projectId: filterProjectId,
        status: filterStatus,
        search: filterSearch,
      );
    } catch (e) {
      debugPrint('Error loading journal entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilters({String? from, String? to, int? project, String? status, String? search}) {
    filterDateFrom = from;
    filterDateTo = to;
    filterProjectId = project;
    filterStatus = status;
    filterSearch = search;
    loadEntries();
  }

  void resetFilters() {
    filterDateFrom = null;
    filterDateTo = null;
    filterProjectId = null;
    filterStatus = 'all';
    filterSearch = null;
    loadEntries();
  }

  /// Initializes a new empty entry for creation
  Future<void> initNewEntry({int? defaultProjectId}) async {
    final nextNumber = await _journalRepo.getNextEntryNumber();
    activeEntry = JournalEntry(
      entryNumber: nextNumber,
      date: DateTime.now().toIso8601String().substring(0, 10),
      description: '',
      projectId: defaultProjectId,
      status: JournalStatus.draft,
    );

    activeLines = [
      JournalLine(lineNumber: 1, accountId: 0, debit: 0.0, credit: 0.0, projectId: defaultProjectId),
      JournalLine(lineNumber: 2, accountId: 0, debit: 0.0, credit: 0.0, projectId: defaultProjectId),
    ];
    lineValidationErrors.clear();
    notifyListeners();
  }

  /// Loads an existing entry for viewing or editing
  Future<void> loadEntryForEdit(int entryId) async {
    _isLoading = true;
    notifyListeners();

    final entry = await _journalRepo.getJournalEntryById(entryId);
    if (entry != null) {
      activeEntry = entry;
      activeLines = List.from(entry.lines);
      lineValidationErrors.clear();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Line item manipulation
  void addLine({int? projectId}) {
    final newLineNumber = activeLines.length + 1;
    activeLines.add(
      JournalLine(
        lineNumber: newLineNumber,
        accountId: 0,
        projectId: projectId ?? activeEntry?.projectId,
        debit: 0.0,
        credit: 0.0,
      ),
    );
    validateLines();
    notifyListeners();
  }

  void duplicateLine(int index) {
    if (index >= 0 && index < activeLines.length) {
      final source = activeLines[index];
      final newLine = source.copyWith(
        id: null,
        lineNumber: activeLines.length + 1,
      );
      activeLines.add(newLine);
      validateLines();
      notifyListeners();
    }
  }

  void removeLine(int index) {
    if (activeLines.length > 2 && index >= 0 && index < activeLines.length) {
      activeLines.removeAt(index);
      for (int i = 0; i < activeLines.length; i++) {
        activeLines[i] = activeLines[i].copyWith(lineNumber: i + 1);
      }
      validateLines();
      notifyListeners();
    }
  }

  void updateLine(int index, JournalLine line) {
    if (index >= 0 && index < activeLines.length) {
      activeLines[index] = line;
      validateLines();
      notifyListeners();
    }
  }

  void validateLines() {
    lineValidationErrors.clear();
    for (int i = 0; i < activeLines.length; i++) {
      final line = activeLines[i];
      final errs = AccountingValidators.validateJournalLine(
        accountId: line.accountId,
        debit: line.debit,
        credit: line.credit,
      );
      if (errs.isNotEmpty) {
        lineValidationErrors[i] = errs;
      }
    }
  }

  Future<void> saveCurrentEntry({bool postImmediately = false, String? username}) async {
    if (activeEntry == null) return;

    validateLines();
    if (postImmediately) {
      if (!isCurrentBalanced) {
        throw Exception('لا يمكن ترحيل قيد غير متزن! الفرق الحالي: $currentDifference');
      }
      if (lineValidationErrors.isNotEmpty) {
        throw Exception('يرجى تصحيح الأخطاء في أسطر القيد قبل الترحيل.');
      }
    }

    final entryToSave = activeEntry!.copyWith(
      status: postImmediately ? JournalStatus.posted : JournalStatus.draft,
      postedBy: postImmediately ? (username ?? 'المستخدم') : null,
      postedAt: postImmediately ? DateTime.now().toIso8601String() : null,
      lines: activeLines,
    );

    if (activeEntry!.id == null) {
      await _journalRepo.createJournalEntry(entryToSave);
      await _auditService.log(
        action: postImmediately ? 'Posted Journal Entry' : 'Created Draft Journal Entry',
        recordType: 'JournalEntry',
        recordId: entryToSave.entryNumber,
        details: entryToSave.description,
      );
    } else {
      await _journalRepo.updateDraftJournalEntry(entryToSave);
      if (postImmediately) {
        await _journalRepo.postJournalEntry(activeEntry!.id!, postedBy: username ?? 'المستخدم');
      }
      await _auditService.log(
        action: postImmediately ? 'Posted Journal Entry' : 'Updated Draft Journal Entry',
        recordType: 'JournalEntry',
        recordId: entryToSave.entryNumber,
        details: entryToSave.description,
      );
    }

    await loadEntries();
  }

  Future<void> postEntry(int entryId, {required String postedBy}) async {
    await _journalRepo.postJournalEntry(entryId, postedBy: postedBy);
    await _auditService.log(
      action: 'Posted Journal Entry',
      recordType: 'JournalEntry',
      recordId: entryId.toString(),
      details: 'تم ترحيل القيد بواسطة $postedBy',
    );
    await loadEntries();
  }

  Future<void> cancelEntry(int entryId, {required String cancelledBy, required String reason}) async {
    await _journalRepo.cancelJournalEntry(entryId, cancelledBy: cancelledBy, reason: reason);
    await _auditService.log(
      action: 'Cancelled Journal Entry',
      recordType: 'JournalEntry',
      recordId: entryId.toString(),
      details: 'سبب الإلغاء: $reason بواسطة $cancelledBy',
    );
    await loadEntries();
  }

  Future<void> deleteDraft(int entryId) async {
    await _journalRepo.deleteDraftEntry(entryId);
    await _auditService.log(
      action: 'Deleted Draft Entry',
      recordType: 'JournalEntry',
      recordId: entryId.toString(),
      details: 'تم حذف مسودة القيد',
    );
    await loadEntries();
  }
}
