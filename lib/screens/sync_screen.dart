import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_sync_service.dart';
import '../services/cache_service.dart';
import '../services/mistake_service.dart';
import '../providers/settings_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/sync_dialog.dart';
import '../utils/logger.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final FirebaseSyncService _syncService = FirebaseSyncService();
  final CacheService _cacheService = CacheService();
  final MistakeService _mistakeService = MistakeService();
  bool _isLoading = false;
  String? _lastSyncTime;
  bool _hasCloudData = false;
  int _localQuestionCount = 0;
  int _localMistakeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      if (_syncService.isSignedIn) {
        _hasCloudData = await _syncService.hasCloudData();
        final seenQuestions = await _cacheService.getSeenQuestionIds();
        _localQuestionCount = seenQuestions.length;
        final mistakes = _mistakeService.getMistakes();
        _localMistakeCount = mistakes.length;
      }
    } catch (e) {
      AppLogger.error('Failed to load sync status', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signIn() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = await _syncService.signInWithGoogle();
      if (user != null && mounted) {
        await _loadSyncStatus();
        _showSuccessMessage('Signed in successfully!');

        // Check for sync conflicts after sign in
        final seenQuestions = await _cacheService.getSeenQuestionIds();
        final hasLocalData = seenQuestions.isNotEmpty;
        final hasCloudData = await _syncService.hasCloudData();

        if (hasLocalData && hasCloudData) {
          _showSyncConflictDialog();
        } else if (hasCloudData) {
          // Only cloud data exists, restore it
          await _restoreFromCloud();
        } else if (hasLocalData) {
          // Only local data exists, backup to cloud
          await _backupToCloud();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Sign in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (!mounted) return;

    try {
      await _syncService.signOut();
      if (mounted) {
        await _loadSyncStatus();
        _showSuccessMessage('Signed out successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Sign out failed: ${e.toString()}');
      }
    }
  }

  Future<void> _backupToCloud() async {
    if (!mounted) return;

    try {
      _showSyncProgress('Backing up your data...');
      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();
      await _syncService.backupToCloud(settingsProvider, filterProvider);

      if (mounted) {
        _hideSyncProgress();
        await _loadSyncStatus();
        _showSuccessMessage('Backup completed successfully!');
      }
    } catch (e) {
      if (mounted) {
        _hideSyncProgress();
        _showErrorMessage('Backup failed: ${e.toString()}');
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    if (!mounted) return;

    try {
      _showSyncProgress('Restoring your progress...');
      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();
      await _syncService.restoreFromCloud(settingsProvider, filterProvider);

      if (mounted) {
        _hideSyncProgress();
        await _loadSyncStatus();
        _showSuccessMessage('Restore completed successfully!');
      }
    } catch (e) {
      if (mounted) {
        _hideSyncProgress();
        _showErrorMessage('Restore failed: ${e.toString()}');
      }
    }
  }

  void _showSyncConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Make it non-dismissible
      builder: (context) => PopScope(
        canPop: false, // Prevent back button dismissal
        child: SyncDialog(
          onKeepLocal: () async {
            Navigator.pop(context);
            await _handleSyncConflict(SyncConflictResolution.keepLocal);
          },
          onUseCloud: () async {
            Navigator.pop(context);
            await _handleSyncConflict(SyncConflictResolution.useCloud);
          },
          onMerge: () async {
            Navigator.pop(context);
            await _handleSyncConflict(SyncConflictResolution.merge);
          },
          onCancel: () {}, // Empty callback since dialog is non-dismissible
        ),
      ),
    );
  }

  Future<void> _handleSyncConflict(SyncConflictResolution resolution) async {
    if (!mounted) return;

    try {
      // Show appropriate message based on resolution type
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

      _showSyncProgress(progressMessage);
      final settingsProvider = context.read<SettingsProvider>();
      final filterProvider = context.read<FilterProvider>();

      await _syncService.handleSyncConflict(
        resolution,
        settingsProvider,
        filterProvider,
      );

      if (mounted) {
        _hideSyncProgress();
        await _loadSyncStatus();
        _showSuccessMessage(successMessage);
      }
    } catch (e) {
      if (mounted) {
        _hideSyncProgress();
        _showErrorMessage('Sync failed: ${e.toString()}');
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSyncProgress(String message) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SyncProgressDialog(message: message),
      );
    }
  }

  void _hideSyncProgress() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sync',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading sync status...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAccountSection(),
                const SizedBox(height: 24),
                _buildSyncStatusSection(),
                const SizedBox(height: 24),
                _buildDataOverviewSection(),
              ],
            ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_syncService.isSignedIn) ...[
              ListTile(
                leading: _buildProfileAvatar(),
                title: Text(
                  _syncService.currentUser?.displayName ?? 'User',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_syncService.currentUser?.email ?? ''),
                trailing: TextButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Not signed in',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to sync your progress across devices',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _signIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In with Google'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusSection() {
    if (!_syncService.isSignedIn) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.sync,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-sync enabled',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your progress is automatically synced after each question.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            if (_lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last sync: $_lastSyncTime',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataOverviewSection() {
    if (!_syncService.isSignedIn) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Overview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildDataRow(
              icon: Icons.quiz,
              label: 'Questions answered',
              value: '$_localQuestionCount',
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              icon: Icons.error_outline,
              label: 'Mistakes recorded',
              value: '$_localMistakeCount',
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              icon: Icons.cloud,
              label: 'Cloud backup',
              value: _hasCloudData ? 'Available' : 'None',
              valueColor: _hasCloudData ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    final user = _syncService.currentUser;
    final photoUrl = user?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            errorWidget: (context, url, error) {
              // Fallback to initials if image fails to load
              return Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      );
    }

    // Fallback to initials
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
