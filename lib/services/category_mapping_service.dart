/// Service for mapping between API category codes and user-friendly category names
/// Provides filtering categories for English and Math subjects
class CategoryMappingService {
  // Mapping from user-friendly category names to API primary class codes
  static const Map<String, String> _categoryToApiCode = {
    'Information and Ideas': 'INI',
    'Craft and Structure': 'CAS',
    'Expression of Ideas': 'EOI',
    'Standard English Conventions': 'SEC',
    'Algebra': 'H',
    'Advanced Math': 'P',
    'Problem-Solving and Data Analysis': 'Q',
    'Geometry and Trigonometry': 'S',
  };

  // Reverse mapping from API codes to user-friendly category names
  static const Map<String, String> _apiCodeToCategory = {
    'INI': 'Information and Ideas',
    'CAS': 'Craft and Structure',
    'EOI': 'Expression of Ideas',
    'SEC': 'Standard English Conventions',
    'H': 'Algebra',
    'P': 'Advanced Math',
    'Q': 'Problem-Solving and Data Analysis',
    'S': 'Geometry and Trigonometry',
  };

  // Filter categories organized by subject type
  static const Map<String, List<String>> _filterCategories = {
    'English': [
      'Information and Ideas',
      'Craft and Structure',
      'Expression of Ideas',
      'Standard English Conventions',
    ],
    'Math': [
      'Algebra',
      'Advanced Math',
      'Problem-Solving and Data Analysis',
      'Geometry and Trigonometry',
    ],
  };

  /// Converts an API primary class code to a user-friendly category name
  /// Returns the original code if no mapping is found
  static String getUserFriendlyCategory(String apiCode) {
    return _apiCodeToCategory[apiCode] ?? apiCode;
  }

  /// Converts a user-friendly category name to an API primary class code
  /// Returns the original category if no mapping is found
  static String getApiCode(String category) {
    return _categoryToApiCode[category] ?? category;
  }

  /// Returns a list of filterable categories for the specified subject type
  /// Returns empty list if subject type is not found
  static List<String> getFilterableCategories([String? subjectType]) {
    if (subjectType == null) {
      // Return all categories if no subject type specified
      return [
        ..._filterCategories['English']!,
        ..._filterCategories['Math']!,
      ];
    }
    return _filterCategories[subjectType] ?? [];
  }

  /// Returns all available subject types
  static List<String> getSubjectTypes() {
    return _filterCategories.keys.toList();
  }

  /// Checks if a category is valid (exists in our mappings)
  static bool isValidCategory(String category) {
    return _categoryToApiCode.containsKey(category);
  }

  /// Checks if an API code is valid (exists in our mappings)
  static bool isValidApiCode(String apiCode) {
    return _apiCodeToCategory.containsKey(apiCode);
  }

  /// Returns the subject type for a given category
  /// Returns null if category is not found
  static String? getSubjectTypeForCategory(String category) {
    for (final entry in _filterCategories.entries) {
      if (entry.value.contains(category)) {
        return entry.key;
      }
    }
    return null;
  }
}
