import '../../data/repositories/audit_repository.dart';
import '../../domain/models/audit_log.dart';
import 'auth_service.dart';

class AuditService {
  final AuditRepository _auditRepo;
  final AuthService _authService;

  AuditService({AuditRepository? auditRepo, required AuthService authService})
      : _auditRepo = auditRepo ?? AuditRepository(),
        _authService = authService;

  Future<void> log({
    required String action,
    required String recordType,
    String? recordId,
    String? details,
    String? oldValues,
    String? newValues,
  }) async {
    final user = _authService.currentUser;
    await _auditRepo.log(
      userId: user?.id,
      username: user?.username ?? 'النظام',
      action: action,
      recordType: recordType,
      recordId: recordId,
      details: details,
      oldValues: oldValues,
      newValues: newValues,
    );
  }

  Future<List<AuditLog>> getLogs({String? recordType, String? action, String? search, int limit = 100}) {
    return _auditRepo.getLogs(recordType: recordType, action: action, search: search, limit: limit);
  }
}
