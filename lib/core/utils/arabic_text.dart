class ArabicTextHelper {
  /// Normalizes Arabic text for flexible search:
  /// - Converts أ, إ, آ to ا
  /// - Converts ة to ه
  /// - Converts ى to ي
  /// - Removes Tashkeel (harakat)
  /// - Trims and lowercases
  static String normalize(String text) {
    if (text.isEmpty) return '';
    
    var result = text.trim().toLowerCase();
    
    // Remove Tashkeel
    final tashkeel = RegExp(r'[\u064B-\u0652]');
    result = result.replaceAll(tashkeel, '');
    
    // Normalize Alef
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');
    
    // Normalize Teh Marbuta
    result = result.replaceAll('ة', 'ه');
    
    // Normalize Yaa
    result = result.replaceAll('ى', 'ي');
    
    return result;
  }

  /// Checks if source contains query in normalized Arabic form
  static bool containsNormalized(String source, String query) {
    if (query.trim().isEmpty) return true;
    final normSource = normalize(source);
    final normQuery = normalize(query);
    return normSource.contains(normQuery);
  }
}
