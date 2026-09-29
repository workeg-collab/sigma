class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, this.errors = const []});

  factory ValidationResult.success() => ValidationResult(isValid: true);
  factory ValidationResult.failure(List<String> errors) => ValidationResult(isValid: false, errors: errors);

  String get errorSummary => errors.join('\n');
}

class AccountingValidators {
  static const double epsilon = 0.0001;

  /// Validates whether a number is effectively zero
  static bool isZero(double value) => value.abs() < epsilon;

  /// Validates equality of two amounts
  static bool areEqual(double a, double b) => (a - b).abs() < epsilon;

  /// Validates a single journal line
  static List<String> validateJournalLine({
    required int? accountId,
    required double debit,
    required double credit,
    bool requiresProject = false,
    int? projectId,
    bool requiresAnalytical = false,
    int? analyticalItemId,
  }) {
    final List<String> errors = [];

    if (accountId == null || accountId <= 0) {
      errors.add('يجب اختيار الحساب المالي');
    }

    if (debit < 0 || credit < 0) {
      errors.add('لا يمكن إدخال مبالغ سالبة');
    }

    if (debit > 0 && credit > 0) {
      errors.add('لا يمكن إدخال مدين ودائن في نفس السطر');
    }

    if (debit <= 0 && credit <= 0) {
      errors.add('يجب إدخال مبلغ مدين أو دائن');
    }

    if (requiresProject && (projectId == null || projectId <= 0)) {
      errors.add('هذا الحساب يتطلب تحديد المشروع التابع له');
    }

    if (requiresAnalytical && (analyticalItemId == null || analyticalItemId <= 0)) {
      errors.add('هذا الحساب يتطلب تحديد بند التوجيه التحليلي');
    }

    return errors;
  }
}
