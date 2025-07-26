// lib/services/firebase_sync_service.dart
// Efficient subcollection-based sync service

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sync_data.dart';
import '../models/mistake.dart';
import '../models/question.dart';
import '../models/question_identifier.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/mistake_service.dart';
import '../providers/settings_provider.dart';
import '../providers/filter_provider.dart';
import '../utils/logger.dart';

enum SyncConflictResolution { keepLocal, useCloud, merge }

enum SyncResult { success, conflictDetected, failed }

class SyncConflictException implements Exception {
  final String message;
  SyncConflictException(this.message);
}

class FirebaseSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn;
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  final MistakeService _mistakeService = MistakeService();

  FirebaseSyncService() {
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  }

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Collection references for subcollections
  CollectionReference _getUserCollection() {
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('sync_data');
  }

  CollectionReference _getSeenQuestionsCollection() {
    return _getUserCollection().doc('collections').collection('seen_questions');
  }

  CollectionReference _getMistakesCollection() {
    return _getUserCollection().doc('collections').collection('mistakes');
  }

  CollectionReference _getSettingsCollection() {
    return _getUserCollection().doc('collections').collection('settings');
  }

  DocumentReference _getMetadataDocument() {
    return _getUserCollection().doc('metadata');
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      AppLogger.info('Starting Google Sign In', tag: 'FirebaseSyncService');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.info('Google Sign In cancelled by user',
            tag: 'FirebaseSyncService');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      AppLogger.info('Google Sign In successful: ${userCredential.user?.email}',
          tag: 'FirebaseSyncService');

      return userCredential.user;
    } catch (e, stackTrace) {
      AppLogger.error('Google Sign In failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      AppLogger.info('User signed out successfully',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Sign out failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Check if cloud data exists
  Future<bool> hasCloudData() async {
    if (!isSignedIn) return false;

    try {
      final metadataDoc = await _getMetadataDocument().get();
      if (!metadataDoc.exists) return false;

      final metadata =
          SyncMetadata.fromJson(metadataDoc.data() as Map<String, dynamic>);
      return metadata.seenQuestionsCount > 0 || metadata.mistakesCount > 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check cloud data',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Get sync metadata
  Future<SyncMetadata?> getSyncMetadata() async {
    if (!isSignedIn) return null;

    try {
      final doc = await _getMetadataDocument().get();
      if (!doc.exists) return null;

      return SyncMetadata.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Failed to get sync metadata',
          tag: 'FirebaseSyncService', error: e);
      return null;
    }
  }

  // Update sync metadata
  Future<void> _updateSyncMetadata(SyncMetadata metadata) async {
    try {
      await _getMetadataDocument()
          .set(metadata.toJson(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Failed to update sync metadata',
          tag: 'FirebaseSyncService', error: e);
      rethrow;
    }
  }

  // INCREMENTAL SYNC OPERATIONS

  // Sync a new seen question (true incremental)
  Future<SyncResult> syncSeenQuestion(String questionId) async {
    if (!isSignedIn) return SyncResult.success;

    try {
      AppLogger.debug('Starting incremental seen question sync: $questionId',
          tag: 'FirebaseSyncService');

      final now = DateTime.now();
      final entry = SeenQuestionEntry(
        questionId: questionId,
      );

      // Add to subcollection (will overwrite if exists, which is fine)
      await _getSeenQuestionsCollection()
          .doc(entry.documentId)
          .set(entry.toJson());

      // Update metadata count
      final metadata = await getSyncMetadata();
      final currentCount = metadata?.seenQuestionsCount ?? 0;

      // Only increment if this is a new question
      final existingDoc =
          await _getSeenQuestionsCollection().doc(questionId).get();
      final isNewQuestion = !existingDoc.exists;

      final updatedMetadata = (metadata ??
              SyncMetadata(
                lastUpdated: now,
                seenQuestionsCount: 0,
                mistakesCount: 0,
              ))
          .copyWith(
        lastUpdated: now,
        seenQuestionsCount: isNewQuestion ? currentCount + 1 : currentCount,
        lastSeenQuestionSync: now,
      );

      await _updateSyncMetadata(updatedMetadata);

      AppLogger.debug('Incremental seen question sync completed',
          tag: 'FirebaseSyncService');
      return SyncResult.success;
    } catch (e) {
      AppLogger.warning('Incremental seen question sync failed',
          tag: 'FirebaseSyncService', error: e);
      return SyncResult.failed;
    }
  }

  // Sync a new mistake (true incremental)
  Future<SyncResult> syncMistake(Mistake mistake) async {
    if (!isSignedIn) return SyncResult.success;

    try {
      AppLogger.debug('Starting incremental mistake sync',
          tag: 'FirebaseSyncService');

      final now = DateTime.now();
      final entry = MistakeEntry(
        questionId: _extractQuestionId(mistake),
        questionIdType: _extractQuestionIdType(mistake),
        questionType: _inferQuestionType(mistake),
        timestamp: mistake.timestamp, // Use original timestamp
        userChoice:
            mistake.answerOptions.isNotEmpty ? mistake.userAnswerLabel : null,
        userInput: mistake.answerOptions.isEmpty ? mistake.userAnswer : null,
      );

      // Add to subcollection
      await _getMistakesCollection().doc(entry.documentId).set(entry.toJson());

      // Update metadata count
      final metadata = await getSyncMetadata();
      final currentCount = metadata?.mistakesCount ?? 0;

      final updatedMetadata = (metadata ??
              SyncMetadata(
                lastUpdated: now,
                seenQuestionsCount: 0,
                mistakesCount: 0,
              ))
          .copyWith(
        lastUpdated: now,
        mistakesCount: currentCount + 1,
        lastMistakeSync: now,
      );

      await _updateSyncMetadata(updatedMetadata);

      AppLogger.debug('Incremental mistake sync completed',
          tag: 'FirebaseSyncService');
      return SyncResult.success;
    } catch (e) {
      AppLogger.warning('Incremental mistake sync failed',
          tag: 'FirebaseSyncService', error: e);
      return SyncResult.failed;
    }
  }

  // Sync settings changes (true incremental)
  Future<SyncResult> syncSettings(SettingsProvider settingsProvider) async {
    if (!isSignedIn) return SyncResult.success;

    try {
      AppLogger.debug('Starting incremental settings sync',
          tag: 'FirebaseSyncService');

      final now = DateTime.now();
      final settings = UserSettings(
        oledMode: settingsProvider.isOledMode,
        excludeActiveQuestions: settingsProvider.excludeActiveQuestions,
        cachingEnabled: settingsProvider.isCachingEnabled,
        lastUpdated: now,
      );

      // Update settings document
      await _getSettingsCollection()
          .doc('user_preferences')
          .set(settings.toJson());

      // Update metadata
      final metadata = await getSyncMetadata();
      final updatedMetadata = (metadata ??
              SyncMetadata(
                lastUpdated: now,
                seenQuestionsCount: 0,
                mistakesCount: 0,
              ))
          .copyWith(
        lastUpdated: now,
        lastSettingsSync: now,
      );

      await _updateSyncMetadata(updatedMetadata);

      AppLogger.debug('Incremental settings sync completed',
          tag: 'FirebaseSyncService');
      return SyncResult.success;
    } catch (e) {
      AppLogger.warning('Incremental settings sync failed',
          tag: 'FirebaseSyncService', error: e);
      return SyncResult.failed;
    }
  }

  // Sync filters changes (true incremental)
  Future<SyncResult> syncFilters(FilterProvider filterProvider) async {
    if (!isSignedIn) return SyncResult.success;

    try {
      AppLogger.debug('Starting incremental filters sync',
          tag: 'FirebaseSyncService');

      final now = DateTime.now();
      final filters = UserFilters(
        activeFilters: filterProvider.activeFilters.toList(),
        activeDifficultyFilters:
            filterProvider.activeDifficultyFilters.toList(),
        lastUpdated: now,
      );

      // Update filters document
      await _getSettingsCollection().doc('filters').set(filters.toJson());

      // Update metadata
      final metadata = await getSyncMetadata();
      final updatedMetadata = (metadata ??
              SyncMetadata(
                lastUpdated: now,
                seenQuestionsCount: 0,
                mistakesCount: 0,
              ))
          .copyWith(
        lastUpdated: now,
        lastSettingsSync: now,
      );

      await _updateSyncMetadata(updatedMetadata);

      AppLogger.debug('Incremental filters sync completed',
          tag: 'FirebaseSyncService');
      return SyncResult.success;
    } catch (e) {
      AppLogger.warning('Incremental filters sync failed',
          tag: 'FirebaseSyncService', error: e);
      return SyncResult.failed;
    }
  }

  // EFFICIENT SYNC OPERATIONS

  // Sync changes since last sync (pull from cloud)
  Future<void> syncFromCloud(
      SettingsProvider settingsProvider, FilterProvider filterProvider) async {
    if (!isSignedIn) return;

    try {
      AppLogger.info('Starting efficient sync from cloud',
          tag: 'FirebaseSyncService');

      final lastSync = await _getLastSyncTimestamp();
      final now = DateTime.now();

      // Sync seen questions added since last sync
      await _syncSeenQuestionsFromCloud(lastSync);

      // Sync mistakes added since last sync
      await _syncMistakesFromCloud(filterProvider, lastSync);

      // Sync settings if they've changed
      await _syncSettingsFromCloud(settingsProvider, lastSync);

      // Sync filters if they've changed
      await _syncFiltersFromCloud(filterProvider, lastSync);

      // Update local sync timestamp
      await _storeLastSyncTimestamp(now);

      AppLogger.info('Efficient sync from cloud completed',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Sync from cloud failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Sync seen questions from cloud (only new ones)
  Future<void> _syncSeenQuestionsFromCloud(DateTime? lastSync) async {
    try {
      Query query = _getSeenQuestionsCollection();

      if (lastSync != null) {
        query =
            query.where('timestamp', isGreaterThan: lastSync.toIso8601String());
      }

      final snapshot = await query.get();
      AppLogger.debug(
          'Found ${snapshot.docs.length} new seen questions from cloud',
          tag: 'FirebaseSyncService');

      for (final doc in snapshot.docs) {
        final entry =
            SeenQuestionEntry.fromJson(doc.data() as Map<String, dynamic>);

        // Add to local cache if not already present
        final localSeenIds = await _cacheService.getSeenQuestionIds();
        if (!localSeenIds.contains(entry.questionId)) {
          await _cacheService.addSeenQuestionId(entry.questionId);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to sync seen questions from cloud',
          tag: 'FirebaseSyncService', error: e);
      rethrow;
    }
  }

  // Sync mistakes from cloud (only new ones)
  Future<void> _syncMistakesFromCloud(
      FilterProvider filterProvider, DateTime? lastSync) async {
    try {
      Query query = _getMistakesCollection();

      if (lastSync != null) {
        query =
            query.where('timestamp', isGreaterThan: lastSync.toIso8601String());
      }

      final snapshot = await query.get();
      AppLogger.debug('Found ${snapshot.docs.length} new mistakes from cloud',
          tag: 'FirebaseSyncService');

      final newMistakes = <MistakeEntry>[];
      for (final doc in snapshot.docs) {
        final entry = MistakeEntry.fromJson(doc.data() as Map<String, dynamic>);
        newMistakes.add(entry);
      }

      // Convert to full mistakes and add to local storage
      if (newMistakes.isNotEmpty) {
        final mistakes =
            await _convertMistakeEntriesToMistakes(newMistakes, filterProvider);
        for (final mistake in mistakes) {
          await _mistakeService.addMistake(mistake);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to sync mistakes from cloud',
          tag: 'FirebaseSyncService', error: e);
      rethrow;
    }
  }

  // Sync settings from cloud (only if changed)
  Future<void> _syncSettingsFromCloud(
      SettingsProvider settingsProvider, DateTime? lastSync) async {
    try {
      final doc = await _getSettingsCollection().doc('user_preferences').get();
      if (!doc.exists) return;

      final settings =
          UserSettings.fromJson(doc.data() as Map<String, dynamic>);

      // Only apply if settings are newer than our last sync
      if (lastSync == null || settings.lastUpdated.isAfter(lastSync)) {
        AppLogger.debug('Applying newer settings from cloud',
            tag: 'FirebaseSyncService');

        await settingsProvider.toggleOledMode(settings.oledMode);
        await settingsProvider
            .toggleExcludeActiveQuestions(settings.excludeActiveQuestions);
        await settingsProvider.toggleCaching(settings.cachingEnabled);
      }
    } catch (e) {
      AppLogger.error('Failed to sync settings from cloud',
          tag: 'FirebaseSyncService', error: e);
      // Don't rethrow - settings sync failure shouldn't break overall sync
    }
  }

  // Sync filters from cloud (only if changed)
  Future<void> _syncFiltersFromCloud(
      FilterProvider filterProvider, DateTime? lastSync) async {
    try {
      final doc = await _getSettingsCollection().doc('filters').get();
      if (!doc.exists) return;

      final filters = UserFilters.fromJson(doc.data() as Map<String, dynamic>);

      // Only apply if filters are newer than our last sync
      if (lastSync == null || filters.lastUpdated.isAfter(lastSync)) {
        AppLogger.debug('Applying newer filters from cloud',
            tag: 'FirebaseSyncService');

        await filterProvider.clearFilters();
        for (final filter in filters.activeFilters) {
          await filterProvider.addFilter(filter);
        }
        for (final difficultyFilter in filters.activeDifficultyFilters) {
          await filterProvider.addDifficultyFilter(difficultyFilter);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to sync filters from cloud',
          tag: 'FirebaseSyncService', error: e);
      // Don't rethrow - filters sync failure shouldn't break overall sync
    }
  }
  // FULL BACKUP/RESTORE OPERATIONS

  // Full backup to cloud (used for initial sync or conflict resolution)
  Future<void> backupToCloud(
      SettingsProvider settingsProvider, FilterProvider filterProvider) async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      AppLogger.info('Starting full backup to cloud',
          tag: 'FirebaseSyncService');

      final now = DateTime.now();
      final batch = _firestore.batch();

      // Get rid of previous data
      await syncClearAllData();

      // Backup seen questions
      final seenQuestionIds = await _cacheService.getSeenQuestionIds();
      for (final questionId in seenQuestionIds) {
        final entry = SeenQuestionEntry(
          questionId: questionId,
        );
        batch.set(_getSeenQuestionsCollection().doc(entry.documentId),
            entry.toJson());
      }

      // Backup mistakes
      final mistakes = _mistakeService.getMistakes();
      for (final mistake in mistakes) {
        final entry = MistakeEntry(
          questionId: _extractQuestionId(mistake),
          questionIdType: _extractQuestionIdType(mistake),
          questionType: _inferQuestionType(mistake),
          timestamp: mistake.timestamp,
          userChoice:
              mistake.answerOptions.isNotEmpty ? mistake.userAnswerLabel : null,
          userInput: mistake.answerOptions.isEmpty ? mistake.userAnswer : null,
        );
        batch.set(
            _getMistakesCollection().doc(entry.documentId), entry.toJson());
      }

      // Backup settings
      final settings = UserSettings(
        oledMode: settingsProvider.isOledMode,
        excludeActiveQuestions: settingsProvider.excludeActiveQuestions,
        cachingEnabled: settingsProvider.isCachingEnabled,
        lastUpdated: now,
      );
      batch.set(
          _getSettingsCollection().doc('user_preferences'), settings.toJson());

      // Backup filters
      final filters = UserFilters(
        activeFilters: filterProvider.activeFilters.toList(),
        activeDifficultyFilters:
            filterProvider.activeDifficultyFilters.toList(),
        lastUpdated: now,
      );
      batch.set(_getSettingsCollection().doc('filters'), filters.toJson());

      // Update metadata
      final metadata = SyncMetadata(
        lastUpdated: now,
        seenQuestionsCount: seenQuestionIds.length,
        mistakesCount: mistakes.length,
        lastSeenQuestionSync: now,
        lastMistakeSync: now,
        lastSettingsSync: now,
      );
      batch.set(_getMetadataDocument(), metadata.toJson());

      // Commit all changes atomically
      await batch.commit();

      // Update local sync timestamp
      await _storeLastSyncTimestamp(now);

      AppLogger.info('Full backup to cloud completed successfully',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Full backup to cloud failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Full restore from cloud (used for initial sync or conflict resolution)
  Future<void> restoreFromCloud(
      SettingsProvider settingsProvider, FilterProvider filterProvider) async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      AppLogger.info('Starting full restore from cloud',
          tag: 'FirebaseSyncService');

      // Clear local data first
      await _cacheService.clearSeenQuestions();
      await _mistakeService.clearMistakes();

      // Restore seen questions
      final seenQuestionsSnapshot = await _getSeenQuestionsCollection().get();
      for (final doc in seenQuestionsSnapshot.docs) {
        final entry =
            SeenQuestionEntry.fromJson(doc.data() as Map<String, dynamic>);
        await _cacheService.addSeenQuestionId(entry.questionId);
      }

      // Restore mistakes
      final mistakesSnapshot = await _getMistakesCollection().get();
      final mistakeEntries = <MistakeEntry>[];
      for (final doc in mistakesSnapshot.docs) {
        final entry = MistakeEntry.fromJson(doc.data() as Map<String, dynamic>);
        mistakeEntries.add(entry);
      }

      if (mistakeEntries.isNotEmpty) {
        final mistakes = await _convertMistakeEntriesToMistakes(
            mistakeEntries, filterProvider);
        for (final mistake in mistakes) {
          await _mistakeService.addMistake(mistake);
        }
      }

      // Restore settings
      final settingsDoc =
          await _getSettingsCollection().doc('user_preferences').get();
      if (settingsDoc.exists) {
        final settings =
            UserSettings.fromJson(settingsDoc.data() as Map<String, dynamic>);
        await settingsProvider.toggleOledMode(settings.oledMode);
        await settingsProvider
            .toggleExcludeActiveQuestions(settings.excludeActiveQuestions);
        await settingsProvider.toggleCaching(settings.cachingEnabled);
      }

      // Restore filters
      final filtersDoc = await _getSettingsCollection().doc('filters').get();
      if (filtersDoc.exists) {
        final filters =
            UserFilters.fromJson(filtersDoc.data() as Map<String, dynamic>);
        await filterProvider.clearFilters();
        for (final filter in filters.activeFilters) {
          await filterProvider.addFilter(filter);
        }
        for (final difficultyFilter in filters.activeDifficultyFilters) {
          await filterProvider.addDifficultyFilter(difficultyFilter);
        }
      }

      // Update local sync timestamp
      await _storeLastSyncTimestamp(DateTime.now());

      AppLogger.info('Full restore from cloud completed successfully',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Full restore from cloud failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // RESTORE FROM CLOUD WITHOUT MISTAKES (for onboarding)
  Future<void> syncFromCloudWithoutMistakes(
      SettingsProvider settingsProvider, FilterProvider filterProvider) async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      AppLogger.info('Starting sync from cloud without mistakes',
          tag: 'FirebaseSyncService');

      // Restore seen questions
      final seenQuestionsSnapshot = await _getSeenQuestionsCollection().get();
      for (final doc in seenQuestionsSnapshot.docs) {
        final entry =
            SeenQuestionEntry.fromJson(doc.data() as Map<String, dynamic>);
        await _cacheService.addSeenQuestionId(entry.questionId);
      }

      // Restore settings
      final settingsDoc =
          await _getSettingsCollection().doc('user_preferences').get();
      if (settingsDoc.exists) {
        final settings =
            UserSettings.fromJson(settingsDoc.data() as Map<String, dynamic>);
        await settingsProvider.toggleOledMode(settings.oledMode);
        await settingsProvider
            .toggleExcludeActiveQuestions(settings.excludeActiveQuestions);
        await settingsProvider.toggleCaching(settings.cachingEnabled);
      }

      // Restore filters
      final filtersDoc = await _getSettingsCollection().doc('filters').get();
      if (filtersDoc.exists) {
        final filters =
            UserFilters.fromJson(filtersDoc.data() as Map<String, dynamic>);
        await filterProvider.clearFilters();
        for (final filter in filters.activeFilters) {
          await filterProvider.addFilter(filter);
        }
        for (final difficultyFilter in filters.activeDifficultyFilters) {
          await filterProvider.addDifficultyFilter(difficultyFilter);
        }
      }

      // Update local sync timestamp
      await _storeLastSyncTimestamp(DateTime.now());

      AppLogger.info('Sync from cloud without mistakes completed successfully',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Sync from cloud without mistakes failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // RESTORE MISTAKES ONLY (after quiz initialization)
  Future<void> restoreMistakesOnly(
      SettingsProvider settingsProvider, FilterProvider filterProvider) async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      AppLogger.info('Starting mistakes-only restoration',
          tag: 'FirebaseSyncService');

      // Clear existing mistakes first
      await _mistakeService.clearMistakes();

      // Restore mistakes
      final mistakesSnapshot = await _getMistakesCollection().get();
      final mistakeEntries = <MistakeEntry>[];
      for (final doc in mistakesSnapshot.docs) {
        final entry = MistakeEntry.fromJson(doc.data() as Map<String, dynamic>);
        mistakeEntries.add(entry);
      }

      if (mistakeEntries.isNotEmpty) {
        final mistakes = await _convertMistakeEntriesToMistakes(
            mistakeEntries, filterProvider);
        for (final mistake in mistakes) {
          await _mistakeService.addMistake(mistake);
        }
        AppLogger.info(
            'Restored ${mistakes.length} mistakes with full metadata',
            tag: 'FirebaseSyncService');
      } else {
        AppLogger.info('No mistakes to restore', tag: 'FirebaseSyncService');
      }

      AppLogger.info('Mistakes-only restoration completed successfully',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Mistakes-only restoration failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // CLEAR OPERATIONS

  // Clear seen questions from cloud (efficient batch deletion)
  Future<void> syncClearSeenQuestions() async {
    if (!isSignedIn) return;

    try {
      AppLogger.info('Clearing seen questions from cloud efficiently',
          tag: 'FirebaseSyncService');

      // Use efficient batch deletion to clear the entire collection
      await _deleteCollection(_getSeenQuestionsCollection());

      // Update metadata to reflect the clear operation
      final metadata = await getSyncMetadata();
      final updatedMetadata = (metadata ??
              SyncMetadata(
                lastUpdated: DateTime.now(),
                seenQuestionsCount: 0,
                mistakesCount: 0,
              ))
          .copyWith(
        lastUpdated: DateTime.now(),
        seenQuestionsCount: 0,
        lastSeenQuestionSync: DateTime.now(),
      );
      await _updateSyncMetadata(updatedMetadata);

      AppLogger.info('Seen questions cleared from cloud efficiently',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear seen questions from cloud',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Clear mistakes from cloud (efficient batch deletion)
  Future<void> syncClearMistakes() async {
    if (!isSignedIn) return;

    try {
      AppLogger.info('Clearing mistakes from cloud efficiently',
          tag: 'FirebaseSyncService');

      // Use efficient batch deletion to clear the entire collection
      await _deleteCollection(_getMistakesCollection());

      // Update metadata to reflect the clear operation
      final metadata = await getSyncMetadata();
      final updatedMetadata = (metadata ??
              SyncMetadata(
                lastUpdated: DateTime.now(),
                seenQuestionsCount: 0,
                mistakesCount: 0,
              ))
          .copyWith(
        lastUpdated: DateTime.now(),
        mistakesCount: 0,
        lastMistakeSync: DateTime.now(),
      );
      await _updateSyncMetadata(updatedMetadata);

      AppLogger.info('Mistakes cleared from cloud efficiently',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear mistakes from cloud',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Clear all data from cloud (most efficient - clears everything at once)
  Future<void> syncClearAllData() async {
    if (!isSignedIn) return;

    try {
      AppLogger.info('Clearing all data from cloud efficiently',
          tag: 'FirebaseSyncService');

      // Clear all collections in parallel for maximum efficiency
      await Future.wait([
        _deleteCollection(_getSeenQuestionsCollection()),
        _deleteCollection(_getMistakesCollection()),
        _deleteCollection(_getSettingsCollection()),
      ]);

      // Reset metadata to reflect complete clear
      final updatedMetadata = SyncMetadata(
        lastUpdated: DateTime.now(),
        seenQuestionsCount: 0,
        mistakesCount: 0,
        lastSeenQuestionSync: DateTime.now(),
        lastMistakeSync: DateTime.now(),
        lastSettingsSync: DateTime.now(),
      );
      await _updateSyncMetadata(updatedMetadata);

      AppLogger.info('All data cleared from cloud efficiently',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear all data from cloud',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // CONFLICT RESOLUTION

  // Handle sync conflicts with user choice
  Future<void> handleSyncConflict(
    SyncConflictResolution resolution,
    SettingsProvider settingsProvider,
    FilterProvider filterProvider,
  ) async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      AppLogger.info(
          'Handling sync conflict with resolution: ${resolution.name}',
          tag: 'FirebaseSyncService');

      switch (resolution) {
        case SyncConflictResolution.keepLocal:
          await backupToCloud(settingsProvider, filterProvider);
          break;

        case SyncConflictResolution.useCloud:
          await restoreFromCloud(settingsProvider, filterProvider);
          break;

        case SyncConflictResolution.merge:
          await _mergeData(settingsProvider, filterProvider);
          break;
      }

      AppLogger.info('Sync conflict resolved successfully',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle sync conflict',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Merge local and cloud data intelligently
  Future<void> _mergeData(
      SettingsProvider settingsProvider, FilterProvider filterProvider) async {
    try {
      AppLogger.info('Starting intelligent data merge',
          tag: 'FirebaseSyncService');

      // Get local data
      final localSeenIds = await _cacheService.getSeenQuestionIds();
      final localMistakes = _mistakeService.getMistakes();

      // Get cloud data
      final cloudSeenSnapshot = await _getSeenQuestionsCollection().get();
      final cloudMistakesSnapshot = await _getMistakesCollection().get();

      final cloudSeenIds = cloudSeenSnapshot.docs.map((doc) => doc.id).toSet();
      final cloudMistakeEntries = cloudMistakesSnapshot.docs
          .map((doc) =>
              MistakeEntry.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Find unique local data
      final uniqueLocalSeenIds =
          localSeenIds.where((id) => !cloudSeenIds.contains(id)).toList();
      final uniqueLocalMistakes =
          _findUniqueMistakes(localMistakes, cloudMistakeEntries);

      // Find unique cloud data
      final uniqueCloudSeenIds =
          cloudSeenIds.where((id) => !localSeenIds.contains(id)).toList();
      final uniqueCloudMistakes = cloudMistakeEntries
          .where((entry) => !localMistakes.any(
              (mistake) => _extractQuestionId(mistake) == entry.questionId))
          .toList();

      AppLogger.info(
        'Merge stats: ${uniqueLocalSeenIds.length} unique local seen IDs, ${uniqueLocalMistakes.length} unique local mistakes, '
        '${uniqueCloudSeenIds.length} unique cloud seen IDs, ${uniqueCloudMistakes.length} unique cloud mistakes',
        tag: 'FirebaseSyncService',
      );

      // Add unique cloud data to local
      for (final id in uniqueCloudSeenIds) {
        await _cacheService.addSeenQuestionId(id);
      }

      if (uniqueCloudMistakes.isNotEmpty) {
        final mistakes = await _convertMistakeEntriesToMistakes(
            uniqueCloudMistakes, filterProvider);
        for (final mistake in mistakes) {
          await _mistakeService.addMistake(mistake);
        }
      }

      // Add unique local data to cloud
      if (uniqueLocalSeenIds.isNotEmpty || uniqueLocalMistakes.isNotEmpty) {
        await _addUniqueLocalDataToCloud(
            uniqueLocalSeenIds, uniqueLocalMistakes);
      }

      // Sync settings and filters (cloud takes precedence)
      await _syncSettingsFromCloud(settingsProvider, null);
      await _syncFiltersFromCloud(filterProvider, null);

      // Update local sync timestamp
      await _storeLastSyncTimestamp(DateTime.now());

      AppLogger.info('Intelligent data merge completed successfully',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Data merge failed',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Add unique local data to cloud efficiently
  Future<void> _addUniqueLocalDataToCloud(
      List<String> uniqueSeenIds, List<Mistake> uniqueMistakes) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Add unique seen questions
      for (final questionId in uniqueSeenIds) {
        final entry = SeenQuestionEntry(
          questionId: questionId,
        );
        batch.set(_getSeenQuestionsCollection().doc(entry.documentId),
            entry.toJson());
      }

      // Add unique mistakes
      for (final mistake in uniqueMistakes) {
        final entry = MistakeEntry(
          questionId: _extractQuestionId(mistake),
          questionIdType: _extractQuestionIdType(mistake),
          questionType: _inferQuestionType(mistake),
          timestamp: mistake.timestamp,
          userChoice:
              mistake.answerOptions.isNotEmpty ? mistake.userAnswerLabel : null,
          userInput: mistake.answerOptions.isEmpty ? mistake.userAnswer : null,
        );
        batch.set(
            _getMistakesCollection().doc(entry.documentId), entry.toJson());
      }

      // Update metadata
      final metadata = await getSyncMetadata();
      final updatedMetadata = (metadata ??
              SyncMetadata(
                lastUpdated: now,
                seenQuestionsCount: 0,
                mistakesCount: 0,
              ))
          .copyWith(
        lastUpdated: now,
        seenQuestionsCount:
            (metadata?.seenQuestionsCount ?? 0) + uniqueSeenIds.length,
        mistakesCount: (metadata?.mistakesCount ?? 0) + uniqueMistakes.length,
        lastSeenQuestionSync:
            uniqueSeenIds.isNotEmpty ? now : metadata?.lastSeenQuestionSync,
        lastMistakeSync:
            uniqueMistakes.isNotEmpty ? now : metadata?.lastMistakeSync,
      );
      batch.set(_getMetadataDocument(), updatedMetadata.toJson());

      await batch.commit();

      AppLogger.info('Successfully added unique local data to cloud',
          tag: 'FirebaseSyncService');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add unique local data to cloud',
          tag: 'FirebaseSyncService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  // HELPER METHODS

  // Efficiently delete an entire collection using batched operations
  Future<void> _deleteCollection(CollectionReference collection) async {
    const int batchSize = 500; // Firestore batch limit

    try {
      QuerySnapshot snapshot;
      do {
        // Get a batch of documents
        snapshot = await collection.limit(batchSize).get();

        if (snapshot.docs.isEmpty) break;

        // Create a batch to delete documents
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Commit the batch
        await batch.commit();

        AppLogger.debug(
            'Deleted ${snapshot.docs.length} documents from collection',
            tag: 'FirebaseSyncService');
      } while (snapshot.docs.length == batchSize);

      AppLogger.info('Collection deletion completed successfully',
          tag: 'FirebaseSyncService');
    } catch (e) {
      AppLogger.error('Failed to delete collection',
          tag: 'FirebaseSyncService', error: e);
      rethrow;
    }
  }

  // Convert MistakeEntry objects to full Mistake objects
  Future<List<Mistake>> _convertMistakeEntriesToMistakes(
      List<MistakeEntry> entries, FilterProvider filterProvider) async {
    final mistakes = <Mistake>[];
    final allIdentifiers = filterProvider.originalQuestions;
    final identifierMap = {
      for (var identifier in allIdentifiers) identifier.id: identifier
    };

    AppLogger.info(
        'Converting ${entries.length} mistake entries to full mistakes',
        tag: 'FirebaseSyncService');

    // Check if we have question metadata available
    final hasMetadata = allIdentifiers.isNotEmpty;
    if (!hasMetadata) {
      AppLogger.warning(
          'No question metadata available in FilterProvider. Mistakes will be restored with limited metadata.',
          tag: 'FirebaseSyncService');
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      try {
        AppLogger.debug(
            'Processing mistake ${i + 1}/${entries.length}: questionId=${entry.questionId}',
            tag: 'FirebaseSyncService');

        QuestionIdentifier identifierToUse;

        if (hasMetadata) {
          // Try to find the full identifier from the map
          final fullIdentifier = identifierMap[entry.questionId];

          if (fullIdentifier != null) {
            identifierToUse = fullIdentifier;
          } else {
            AppLogger.warning(
                'Could not find metadata for question ${entry.questionId}. Using fallback identifier.',
                tag: 'FirebaseSyncService');
            identifierToUse = _createQuestionIdentifier(
                entry.questionId, entry.questionIdType, entry.questionType);
          }
        } else {
          // No metadata available, use fallback identifier
          identifierToUse = _createQuestionIdentifier(
              entry.questionId, entry.questionIdType, entry.questionType);
        }

        // Fetch question details using API service
        final question = await _apiService.getQuestionDetails(identifierToUse);

        // Create full mistake object
        final mistake = _createMistakeFromEntryAndQuestion(entry, question);
        mistakes.add(mistake);

        AppLogger.debug(
            'Successfully converted mistake ${i + 1}/${entries.length}',
            tag: 'FirebaseSyncService');
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to restore mistake ${i + 1}/${entries.length} for question ${entry.questionId}',
          tag: 'FirebaseSyncService',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue with other mistakes even if one fails
      }
    }

    AppLogger.info(
        'Successfully converted ${mistakes.length}/${entries.length} mistakes',
        tag: 'FirebaseSyncService');
    return mistakes;
  }

  // Extract question ID from mistake
  String _extractQuestionId(Mistake mistake) {
    if (mistake.questionId != null && mistake.questionId!.isNotEmpty) {
      return mistake.questionId!;
    }

    AppLogger.warning('Mistake missing questionId, using hash fallback',
        tag: 'FirebaseSyncService');
    return mistake.question.hashCode.abs().toString();
  }

  // Extract question ID type from mistake
  String _extractQuestionIdType(Mistake mistake) {
    if (mistake.questionIdType != null && mistake.questionIdType!.isNotEmpty) {
      return mistake.questionIdType!;
    }
    return 'external'; // Default fallback
  }

  // Infer question type from mistake
  String _inferQuestionType(Mistake mistake) {
    if (mistake.questionType != null && mistake.questionType!.isNotEmpty) {
      return mistake.questionType!;
    }
    return mistake.answerOptions.isNotEmpty ? 'mcq' : 'spr';
  }

  // Create question identifier from entry data
  QuestionIdentifier _createQuestionIdentifier(
      String questionId, String questionIdType, String questionType) {
    try {
      // Skip if questionId looks like a hash (very large numbers are likely hashes)
      final parsedId = int.tryParse(questionId);
      if (parsedId != null && parsedId > 1000000) {
        AppLogger.warning(
            'Skipping mistake with hash-based question ID: $questionId',
            tag: 'FirebaseSyncService');
        throw Exception(
            'Cannot restore mistake with hash-based question ID: $questionId');
      }

      // Determine subject type from question type
      QuestionType subjectType;
      final lowerQuestionType = questionType.toLowerCase();
      if (lowerQuestionType.contains('math') ||
          lowerQuestionType.contains('mathematics')) {
        subjectType = QuestionType.math;
      } else if (lowerQuestionType.contains('english') ||
          lowerQuestionType.contains('reading') ||
          lowerQuestionType.contains('writing')) {
        subjectType = QuestionType.english;
      } else {
        // Default fallback - try to infer from question ID patterns if possible
        AppLogger.warning(
            'Could not determine subject type from questionType: $questionType. Defaulting to English.',
            tag: 'FirebaseSyncService');
        subjectType = QuestionType.english;
      }

      // Determine ID type
      IdType idType =
          questionIdType.toLowerCase() == 'ibn' ? IdType.ibn : IdType.external;

      AppLogger.debug(
          'Created fallback identifier: id=$questionId, type=$idType, subject=$subjectType',
          tag: 'FirebaseSyncService');

      return QuestionIdentifier(
        id: questionId,
        type: idType,
        metadata: null,
        subjectType: subjectType,
      );
    } catch (e) {
      AppLogger.error('Failed to create question identifier for: $questionId',
          tag: 'FirebaseSyncService', error: e);
      rethrow;
    }
  }

  // Create full mistake from entry and fetched question
  Mistake _createMistakeFromEntryAndQuestion(
      MistakeEntry entry, Question question) {
    final meta = question.metadata;
    final difficulty = meta?.difficulty ?? 'Unknown';
    final category = meta?.primaryClassDescription ?? 'Unknown';
    final subject = meta?.skillDescription ?? 'Unknown';

    if (entry.questionType == 'spr') {
      // SPR mistake
      return Mistake(
        question: question.stimulus + question.stem,
        userAnswer: entry.userInput ?? '',
        correctAnswer: question.correctKey.trim().isNotEmpty
            ? question.correctKey
            : 'See explanation',
        timestamp: entry.timestamp,
        rationale: question.rationale,
        userAnswerLabel: '',
        correctAnswerLabel: '',
        difficulty: difficulty,
        category: category,
        subject: subject,
        answerOptions: [],
        questionId: entry.questionId,
        questionType: entry.questionType,
        questionIdType: entry.questionIdType,
      );
    } else {
      // MCQ mistake
      final options = question.answerOptions;
      final correctIndex =
          options.indexWhere((option) => option.id == question.correctKey);
      final correctOption = correctIndex != -1
          ? options[correctIndex]
          : AnswerOption(id: question.correctKey, content: '');

      String getLabel(int idx) =>
          idx >= 0 && idx < 26 ? String.fromCharCode(65 + idx) : '?';

      final correctLabel = getLabel(correctIndex);
      final answerOptions = <MistakeAnswerOption>[];

      for (int i = 0; i < options.length; i++) {
        answerOptions.add(MistakeAnswerOption(
          label: getLabel(i),
          content: options[i].content,
        ));
      }

      // Find user's choice
      final userChoiceIndex = entry.userChoice != null
          ? (entry.userChoice!.codeUnitAt(0) - 65)
          : -1;
      final userOption =
          userChoiceIndex >= 0 && userChoiceIndex < options.length
              ? options[userChoiceIndex]
              : AnswerOption(id: '', content: 'Unknown');

      return Mistake(
        question: question.stimulus + question.stem,
        userAnswer: userOption.content.isNotEmpty ? userOption.content : 'N/A',
        correctAnswer:
            correctOption.content.isNotEmpty ? correctOption.content : 'N/A',
        timestamp: entry.timestamp,
        rationale: question.rationale,
        userAnswerLabel: entry.userChoice ?? '?',
        correctAnswerLabel: correctLabel,
        difficulty: difficulty,
        category: category,
        subject: subject,
        answerOptions: answerOptions,
        questionId: entry.questionId,
        questionType: entry.questionType,
        questionIdType: entry.questionIdType,
      );
    }
  }

  // Find unique local mistakes not in cloud
  List<Mistake> _findUniqueMistakes(
      List<Mistake> localMistakes, List<MistakeEntry> cloudEntries) {
    final cloudQuestionIds = cloudEntries.map((e) => e.questionId).toSet();
    return localMistakes.where((mistake) {
      final questionId = _extractQuestionId(mistake);
      return !cloudQuestionIds.contains(questionId);
    }).toList();
  }

  // Store last sync timestamp locally
  Future<void> _storeLastSyncTimestamp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_timestamp', timestamp.toIso8601String());
    } catch (e) {
      AppLogger.warning('Failed to store last sync timestamp',
          tag: 'FirebaseSyncService', error: e);
    }
  }

  // Get last sync timestamp from local storage
  Future<DateTime?> _getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString('last_sync_timestamp');
      if (timestampStr != null) {
        return DateTime.parse(timestampStr);
      }
    } catch (e) {
      AppLogger.warning('Failed to get last sync timestamp',
          tag: 'FirebaseSyncService', error: e);
    }
    return null;
  }
}
