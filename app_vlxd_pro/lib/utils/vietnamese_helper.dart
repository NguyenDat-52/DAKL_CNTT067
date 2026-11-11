class VietnameseHelper {
  static final RegExp _vietnameseRegexA = RegExp(r'[àáảãạăằắẳẵặâầấẩẫậ]');
  static final RegExp _vietnameseRegexE = RegExp(r'[èéẻẽẹêềếểễệ]');
  static final RegExp _vietnameseRegexI = RegExp(r'[ìíỉĩị]');
  static final RegExp _vietnameseRegexO = RegExp(r'[òóỏõọôồốổỗộơờớởỡợ]');
  static final RegExp _vietnameseRegexU = RegExp(r'[ùúủũụưừứửữự]');
  static final RegExp _vietnameseRegexY = RegExp(r'[ỳýỷỹỵ]');
  static final RegExp _vietnameseRegexD = RegExp(r'[đ]');

  /// Converts a Vietnamese string into an unaccented lowercase string.
  /// Handles both accented characters and special character 'đ'.
  static String toUnaccented(String input) {
    if (input.isEmpty) return '';
    String result = input.toLowerCase();
    result = result.replaceAll(_vietnameseRegexA, 'a');
    result = result.replaceAll(_vietnameseRegexE, 'e');
    result = result.replaceAll(_vietnameseRegexI, 'i');
    result = result.replaceAll(_vietnameseRegexO, 'o');
    result = result.replaceAll(_vietnameseRegexU, 'u');
    result = result.replaceAll(_vietnameseRegexY, 'y');
    result = result.replaceAll(_vietnameseRegexD, 'd');
    return result;
  }

  /// Checks if [source] matches the [query], ignoring case and Vietnamese diacritics.
  /// Also supports multi-word query matching (all words must appear in [source]).
  static bool matches(String source, String query) {
    if (query.trim().isEmpty) return true;
    final normalizedSource = toUnaccented(source);
    final normalizedQuery = toUnaccented(query).trim();

    // Fast direct substring match
    if (normalizedSource.contains(normalizedQuery)) return true;

    // Multi-term match: all words in query appear somewhere in the source
    final terms = normalizedQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    if (terms.isEmpty) return true;
    return terms.every((term) => normalizedSource.contains(term));
  }
}
