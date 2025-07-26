// lib/utils/sync_helper.dart
// Efficient sync helper using subcollection-based sync service

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_sync_service.dart';
import '../services/mistake_restoration_service.dart';
import '../providers/settings_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/sync_dialog.dart';
import '../models/mistake.dart';
import '../utils/logger.dart';

class SyncHelper {
  static final FirebaseSyncService _syncService = FirebaseSyncService();
  static final MistakeRestorationService _restorationService =
      MistakeRestorationService();

  /// Get the mistake restoration service instance
  static MistakeRestorationService get restorationService =>
      _restorationService;

  /// Initialize sync system
  static Future<void> initializeSync(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.info('Initializing sync system', tag: 'SyncHelper');
      await checkInitialSync(context);
      AppLogger.info('Sync system initialized successfully', tag: 'SyncHelper');
    } catch (e) {
      AppLogger.error('Failed to initialize sync system',
          tag: 'SyncHelper', error: e);
      if (context.mounted) {
        _showErrorMessage(
            context, 'Sync initialization failed: ${e.toString()}');
      }
    }
  }

  /// Check if sync is needed on app startup
  static Future<void> checkInitialSync(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.info('Checking initial sync requirements', tag: 'SyncHelper');

      final hasCloudData = await _syncService.hasCloudData();
      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();

      if (!context.mounted) return;

      if (!hasCloudData) {
        // No cloud data, backup local data if any exists
        AppLogger.info('No cloud data found, backing up local data',
            tag: 'SyncHelper');
        await _syncService.backupToCloud(settingsProvider, filterProvider);
      } else {
        // Cloud data exists, sync from cloud
        AppLogger.info('Cloud data found, syncing from cloud',
            tag: 'SyncHelper');

        // Check if filter provider has questions loaded (quiz initialized)
        final hasQuestionsLoaded = filterProvider.originalQuestions.isNotEmpty;

        if (hasQuestionsLoaded) {
          // Quiz is initialized, can restore mistakes with full metadata
          await _syncService.syncFromCloud(settingsProvider, filterProvider);
        } else {
          // Quiz not initialized yet, restore settings/seen questions first, defer mistakes
          AppLogger.info('Quiz not initialized, deferring mistake restoration',
              tag: 'SyncHelper');
          await _syncService.syncFromCloudWithoutMistakes(
              settingsProvider, filterProvider);

          // Schedule mistake restoration for after quiz initialization
          _restorationService.startRestoration('Restoring your mistakes...');
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (context.mounted) {
              await _restoreDeferredMistakes(context);
            }
          });
        }
      }

      AppLogger.info('Initial sync completed successfully', tag: 'SyncHelper');
    } catch (e) {
      AppLogger.warning('Initial sync failed', tag: 'SyncHelper', error: e);
      // Don't show error to user for initial sync failures
    }
  }

  /// Restore mistakes after quiz initialization
  static Future<void> _restoreDeferredMistakes(BuildContext context) async {
    if (!_syncService.isSignedIn) {
      _restorationService.completeRestoration();
      return;
    }

    try {
      AppLogger.info('Restoring deferred mistakes', tag: 'SyncHelper');

      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();

      // Wait a bit more to ensure quiz is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      if (filterProvider.originalQuestions.isNotEmpty) {
        await _syncService.restoreMistakesOnly(
            settingsProvider, filterProvider);
        AppLogger.info('Deferred mistakes restored successfully',
            tag: 'SyncHelper');
      } else {
        AppLogger.warning(
            'Quiz still not initialized, skipping mistake restoration',
            tag: 'SyncHelper');
      }
    } catch (e) {
      AppLogger.warning('Failed to restore deferred mistakes',
          tag: 'SyncHelper', error: e);
      // Silently fail - this shouldn't interrupt user flow
    } finally {
      _restorationService.completeRestoration();
    }
  }

  /// Sync a new seen question (called after answering a question)
  static Future<void> syncSeenQuestion(String questionId) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.debug('Syncing seen question: $questionId', tag: 'SyncHelper');
      await _syncService.syncSeenQuestion(questionId);
    } catch (e) {
      AppLogger.warning('Failed to sync seen question',
          tag: 'SyncHelper', error: e);
      // Silently fail - this shouldn't interrupt user flow
    }
  }

  /// Sync a new mistake (called after making a mistake)
  static Future<void> syncMistake(Mistake mistake) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.debug('Syncing new mistake', tag: 'SyncHelper');
      await _syncService.syncMistake(mistake);
    } catch (e) {
      AppLogger.warning('Failed to sync mistake', tag: 'SyncHelper', error: e);
      // Silently fail - this shouldn't interrupt user flow
    }
  }

  /// Sync settings changes (called after settings change)
  static Future<void> syncSettings(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.debug('Syncing settings changes', tag: 'SyncHelper');
      final settingsProvider = context.read<SettingsProvider>();
      await _syncService.syncSettings(settingsProvider);
    } catch (e) {
      AppLogger.warning('Failed to sync settings', tag: 'SyncHelper', error: e);
      // Silently fail - this shouldn't interrupt user flow
    }
  }

  /// Sync filters changes (called after filter change)
  static Future<void> syncFilters(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.debug('Syncing filters changes', tag: 'SyncHelper');
      final filterProvider = context.read<FilterProvider>();
      await _syncService.syncFilters(filterProvider);
    } catch (e) {
      AppLogger.warning('Failed to sync filters', tag: 'SyncHelper', error: e);
      // Silently fail - this shouldn't interrupt user flow
    }
  }

  /// Sync clear seen questions operation
  static Future<void> syncClearSeenQuestions(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.info('Syncing clear seen questions operation',
          tag: 'SyncHelper');
      await _syncService.syncClearSeenQuestions();
    } catch (e) {
      AppLogger.warning('Failed to sync clear seen questions',
          tag: 'SyncHelper', error: e);
      if (context.mounted) {
        _showErrorMessage(
            context, 'Failed to sync clear operation: ${e.toString()}');
      }
    }
  }

  /// Sync clear mistakes operation
  static Future<void> syncClearMistakes(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.info('Syncing clear mistakes operation', tag: 'SyncHelper');
      await _syncService.syncClearMistakes();
    } catch (e) {
      AppLogger.warning('Failed to sync clear mistakes',
          tag: 'SyncHelper', error: e);
      if (context.mounted) {
        _showErrorMessage(
            context, 'Failed to sync clear operation: ${e.toString()}');
      }
    }
  }

  /// Sync clear all data operation (most efficient)
  static Future<void> syncClearAllData(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.info('Syncing clear all data operation', tag: 'SyncHelper');
      await _syncService.syncClearAllData();
    } catch (e) {
      AppLogger.warning('Failed to sync clear all data',
          tag: 'SyncHelper', error: e);
      if (context.mounted) {
        _showErrorMessage(
            context, 'Failed to sync clear operation: ${e.toString()}');
      }
    }
  }

  /// Perform full backup to cloud (for conflict resolution)
  static Future<void> backupToCloud(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.info('Starting full backup to cloud', tag: 'SyncHelper');
      _showSyncProgress(context, 'Backing up your data...');

      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();

      await _syncService.backupToCloud(settingsProvider, filterProvider);

      if (context.mounted) {
        _hideSyncProgress(context);
        _showSuccessMessage(context, 'Data backed up successfully!');
      }
    } catch (e) {
      AppLogger.error('Full backup failed', tag: 'SyncHelper', error: e);
      if (context.mounted) {
        _hideSyncProgress(context);
        _showErrorMessage(context, 'Backup failed: ${e.toString()}');
      }
    }
  }

  /// Perform full restore from cloud (for conflict resolution)
  static Future<void> restoreFromCloud(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.info('Starting full restore from cloud', tag: 'SyncHelper');
      _showSyncProgress(context, 'Restoring your data...');

      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();

      await _syncService.restoreFromCloud(settingsProvider, filterProvider);

      if (context.mounted) {
        _hideSyncProgress(context);
        _showSuccessMessage(context, 'Data restored successfully!');
      }
    } catch (e) {
      AppLogger.error('Full restore failed', tag: 'SyncHelper', error: e);
      if (context.mounted) {
        _hideSyncProgress(context);
        _showErrorMessage(context, 'Restore failed: ${e.toString()}');
      }
    }
  }

  /// Handle sync conflicts with user choice
  static Future<void> handleSyncConflict(
    BuildContext context,
    SyncConflictResolution resolution,
  ) async {
    if (!context.mounted) return;

    try {
      String progressMessage;
      String successMessage;

      switch (resolution) {
        case SyncConflictResolution.keepLocal:
          progressMessage = 'Backing up your data...';
          successMessage = 'Local data backed up successfully!';
          break;
        case SyncConflictResolution.useCloud:
          progressMessage = 'Restoring your progress...';
          successMessage = 'Progress restored successfully!';
          break;
        case SyncConflictResolution.merge:
          progressMessage = 'Merging your data...';
          successMessage = 'Data merged successfully!';
          break;
      }

      _showSyncProgress(context, progressMessage);

      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();

      await _syncService.handleSyncConflict(
          resolution, settingsProvider, filterProvider);

      if (context.mounted) {
        _hideSyncProgress(context);
        _showSuccessMessage(context, successMessage);
      }
    } catch (e) {
      AppLogger.error('Sync conflict resolution failed',
          tag: 'SyncHelper', error: e);
      if (context.mounted) {
        _hideSyncProgress(context);
        _showErrorMessage(context, 'Sync failed: ${e.toString()}');
      }
    }
  }

  /// Show sync conflict dialog
  static void showSyncConflictDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: SyncDialog(
          onKeepLocal: () async {
            Navigator.pop(context);
            await handleSyncConflict(context, SyncConflictResolution.keepLocal);
          },
          onUseCloud: () async {
            Navigator.pop(context);
            await handleSyncConflict(context, SyncConflictResolution.useCloud);
          },
          onMerge: () async {
            Navigator.pop(context);
            await handleSyncConflict(context, SyncConflictResolution.merge);
          },
          onCancel: () {}, // Empty callback since dialog is non-dismissible
        ),
      ),
    );
  }

  /// Periodic sync to pull changes from other devices
  static Future<void> periodicSync(BuildContext context) async {
    if (!_syncService.isSignedIn) return;

    try {
      AppLogger.debug('Starting periodic sync', tag: 'SyncHelper');

      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();

      await _syncService.syncFromCloud(settingsProvider, filterProvider);

      AppLogger.debug('Periodic sync completed', tag: 'SyncHelper');
    } catch (e) {
      AppLogger.warning('Periodic sync failed', tag: 'SyncHelper', error: e);
      // Silently fail - periodic sync shouldn't interrupt user flow
    }
  }

  // UI Helper Methods

  static void _showSyncProgress(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncProgressDialog(message: message),
    );
  }

  static void _hideSyncProgress(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  static void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// Progress dialog widget
class SyncProgressDialog extends StatelessWidget {
  final String message;

  const SyncProgressDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
