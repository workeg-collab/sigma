import 'journal_line.dart';

class JournalEntry {
  final int? id;
  final String entryNumber;
  final String date; // YYYY-MM-DD
  final String description;
  final String? referenceNumber;
  final int? projectId;
  final String status; // draft, posted, cancelled
  final String? createdBy;
  final String? createdAt;
  final String? postedBy;
  final String? postedAt;
  final String? cancelledBy;
  final String? cancelledAt;
  final String? cancelReason;

  final List<JournalLine> lines;

  // Joined display fields
  final String? projectName;

  JournalEntry({
    this.id,
    required this.entryNumber,
    required this.date,
    required this.description,
    this.referenceNumber,
    this.projectId,
    this.status = 'draft',
    this.createdBy,
    this.createdAt,
    this.postedBy,
    this.postedAt,
    this.cancelledBy,
    this.cancelledAt,
    this.cancelReason,
    this.lines = const [],
    this.projectName,
  });

  double get totalDebit => lines.fold(0.0, (sum, line) => sum + line.debit);
  double get totalCredit => lines.fold(0.0, (sum, line) => sum + line.credit);
  double get difference => (totalDebit - totalCredit).abs();
  bool get isBalanced => difference < 0.0001;

  JournalEntry copyWith({
    int? id,
    String? entryNumber,
    String? date,
    String? description,
    String? referenceNumber,
    int? projectId,
    String? status,
    String? createdBy,
    String? createdAt,
    String? postedBy,
    String? postedAt,
    String? cancelledBy,
    String? cancelledAt,
    String? cancelReason,
    List<JournalLine>? lines,
    String? projectName,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      entryNumber: entryNumber ?? this.entryNumber,
      date: date ?? this.date,
      description: description ?? this.description,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      projectId: projectId ?? this.projectId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      postedBy: postedBy ?? this.postedBy,
      postedAt: postedAt ?? this.postedAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      lines: lines ?? this.lines,
      projectName: projectName ?? this.projectName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_number': entryNumber,
      'date': date,
      'description': description,
      'reference_number': referenceNumber,
      'project_id': projectId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt,
      'posted_by': postedBy,
      'posted_at': postedAt,
      'cancelled_by': cancelledBy,
      'cancelled_at': cancelledAt,
      'cancel_reason': cancelReason,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map, {List<JournalLine> lines = const []}) {
    return JournalEntry(
      id: map['id'] as int?,
      entryNumber: map['entry_number'] as String? ?? '',
      date: map['date'] as String? ?? '',
      description: map['description'] as String? ?? '',
      referenceNumber: map['reference_number'] as String?,
      projectId: map['project_id'] as int?,
      status: map['status'] as String? ?? 'draft',
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as String?,
      postedBy: map['posted_by'] as String?,
      postedAt: map['posted_at'] as String?,
      cancelledBy: map['cancelled_by'] as String?,
      cancelledAt: map['cancelled_at'] as String?,
      cancelReason: map['cancel_reason'] as String?,
      lines: lines,
      projectName: map['project_name'] as String?,
    );
  }
}
