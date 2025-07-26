// lib/models/sync_data.dart
// Efficient subcollection-based sync data models

class SyncMetadata {
  final DateTime lastUpdated;
  final int seenQuestionsCount;
  final int mistakesCount;
  final String version;
  final DateTime? lastSeenQuestionSync;
  final DateTime? lastMistakeSync;
  final DateTime? lastSettingsSync;

  SyncMetadata({
    required this.lastUpdated,
    required this.seenQuestionsCount,
    required this.mistakesCount,
    this.version = '2.0',
    this.lastSeenQuestionSync,
    this.lastMistakeSync,
    this.lastSettingsSync,
  });

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated.toIso8601String(),
      'seenQuestionsCount': seenQuestionsCount,
      'mistakesCount': mistakesCount,
      'version': version,
      if (lastSeenQuestionSync != null)
        'lastSeenQuestionSync': lastSeenQuestionSync!.toIso8601String(),
      if (lastMistakeSync != null)
        'lastMistakeSync': lastMistakeSync!.toIso8601String(),
      if (lastSettingsSync != null)
        'lastSettingsSync': lastSettingsSync!.toIso8601String(),
    };
  }

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      lastUpdated: DateTime.parse(json['lastUpdated']),
      seenQuestionsCount: json['seenQuestionsCount'] ?? 0,
      mistakesCount: json['mistakesCount'] ?? 0,
      version: json['version'] ?? '2.0',
      lastSeenQuestionSync: json['lastSeenQuestionSync'] != null
          ? DateTime.parse(json['lastSeenQuestionSync'])
          : null,
      lastMistakeSync: json['lastMistakeSync'] != null
          ? DateTime.parse(json['lastMistakeSync'])
          : null,
      lastSettingsSync: json['lastSettingsSync'] != null
          ? DateTime.parse(json['lastSettingsSync'])
          : null,
    );
  }

  SyncMetadata copyWith({
    DateTime? lastUpdated,
    int? seenQuestionsCount,
    int? mistakesCount,
    String? version,
    DateTime? lastSeenQuestionSync,
    DateTime? lastMistakeSync,
    DateTime? lastSettingsSync,
  }) {
    return SyncMetadata(
      lastUpdated: lastUpdated ?? this.lastUpdated,
      seenQuestionsCount: seenQuestionsCount ?? this.seenQuestionsCount,
      mistakesCount: mistakesCount ?? this.mistakesCount,
      version: version ?? this.version,
      lastSeenQuestionSync: lastSeenQuestionSync ?? this.lastSeenQuestionSync,
      lastMistakeSync: lastMistakeSync ?? this.lastMistakeSync,
      lastSettingsSync: lastSettingsSync ?? this.lastSettingsSync,
    );
  }
}

class SeenQuestionEntry {
  final String questionId;
  final String? deviceId;

  SeenQuestionEntry({
    required this.questionId,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  factory SeenQuestionEntry.fromJson(Map<String, dynamic> json) {
    return SeenQuestionEntry(
      questionId: json['questionId'],
      deviceId: json['deviceId'],
    );
  }

  String get documentId => questionId;
}

class MistakeEntry {
  final String questionId;
  final String questionIdType;
  final String questionType;
  final String? userChoice;
  final String? userInput;
  final DateTime timestamp;
  final String? deviceId;

  MistakeEntry({
    required this.questionId,
    required this.questionIdType,
    required this.questionType,
    required this.timestamp,
    this.userChoice,
    this.userInput,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionIdType': questionIdType,
      'questionType': questionType,
      'timestamp': timestamp.toIso8601String(),
      if (userChoice != null) 'userChoice': userChoice,
      if (userInput != null) 'userInput': userInput,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  factory MistakeEntry.fromJson(Map<String, dynamic> json) {
    return MistakeEntry(
      questionId: json['questionId'],
      questionIdType: json['questionIdType'] ?? 'external',
      questionType: json['questionType'],
      timestamp: DateTime.parse(json['timestamp']),
      userChoice: json['userChoice'],
      userInput: json['userInput'],
      deviceId: json['deviceId'],
    );
  }
  String get documentId => questionId;
}

class UserSettings {
  final bool oledMode;
  final bool excludeActiveQuestions;
  final bool cachingEnabled;
  final DateTime lastUpdated;
  final String? deviceId;

  UserSettings({
    required this.oledMode,
    required this.excludeActiveQuestions,
    required this.cachingEnabled,
    required this.lastUpdated,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'oledMode': oledMode,
      'excludeActiveQuestions': excludeActiveQuestions,
      'cachingEnabled': cachingEnabled,
      'lastUpdated': lastUpdated.toIso8601String(),
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      oledMode: json['oledMode'] ?? false,
      excludeActiveQuestions: json['excludeActiveQuestions'] ?? false,
      cachingEnabled: json['cachingEnabled'] ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      deviceId: json['deviceId'],
    );
  }
}

class UserFilters {
  final List<String> activeFilters;
  final List<String> activeDifficultyFilters;
  final DateTime lastUpdated;
  final String? deviceId;

  UserFilters({
    required this.activeFilters,
    required this.activeDifficultyFilters,
    required this.lastUpdated,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'activeFilters': activeFilters,
      'activeDifficultyFilters': activeDifficultyFilters,
      'lastUpdated': lastUpdated.toIso8601String(),
      if (deviceId != null) 'deviceId': deviceId,
    };
  }

  factory UserFilters.fromJson(Map<String, dynamic> json) {
    return UserFilters(
      activeFilters: List<String>.from(json['activeFilters'] ?? []),
      activeDifficultyFilters:
          List<String>.from(json['activeDifficultyFilters'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      deviceId: json['deviceId'],
    );
  }
}
