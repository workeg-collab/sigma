class AuditLog {
  final int? id;
  final int? userId;
  final String username;
  final String action; // Created, Edited, Posted, Cancelled, Deleted, Backup, Restore, Login
  final String recordType; // JournalEntry, Account, Project, OpeningBalance, etc.
  final String? recordId;
  final String? details;
  final String? oldValues;
  final String? newValues;
  final String createdAt;

  AuditLog({
    this.id,
    this.userId,
    required this.username,
    required this.action,
    required this.recordType,
    this.recordId,
    this.details,
    this.oldValues,
    this.newValues,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'action': action,
      'record_type': recordType,
      'record_id': recordId,
      'details': details,
      'old_values': oldValues,
      'new_values': newValues,
      'created_at': createdAt,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      username: map['username'] as String? ?? 'النظام',
      action: map['action'] as String? ?? '',
      recordType: map['record_type'] as String? ?? '',
      recordId: map['record_id'] as String?,
      details: map['details'] as String?,
      oldValues: map['old_values'] as String?,
      newValues: map['new_values'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
