// lib/widgets/sync_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SyncDialog extends StatelessWidget {
  final VoidCallback onKeepLocal;
  final VoidCallback onUseCloud;
  final VoidCallback onMerge;
  final VoidCallback onCancel;

  const SyncDialog({
    super.key,
    required this.onKeepLocal,
    required this.onUseCloud,
    required this.onMerge,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button dismissal
      child: AlertDialog(
        title: Text(
          'Sync Conflict',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have data both locally and in the cloud. How would you like to proceed?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              icon: Icons.phone_android,
              title: 'Keep Local Data',
              subtitle: 'Use your current device data and overwrite cloud data',
              onTap: onKeepLocal,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.cloud,
              title: 'Use Cloud Data',
              subtitle: 'Replace local data with cloud data',
              onTap: onUseCloud,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.merge,
              title: 'Merge Data',
              subtitle: 'Combine both datasets (recommended)',
              onTap: onMerge,
              isRecommended: true,
            ),
          ],
        ),
        // Remove cancel button since dialog is non-dismissible
        actions: const [],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRecommended
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isRecommended ? 2 : 1,
          ),
          color: isRecommended
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isRecommended
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isRecommended
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SyncProgressDialog extends StatelessWidget {
  final String message;

  const SyncProgressDialog({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SignInDialog extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onCancel;

  const SignInDialog({
    super.key,
    required this.onSignIn,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Sign In Required',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_sync,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in with Google to sync your progress across devices.',
            style: GoogleFonts.poppins(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onSignIn,
          icon: const Icon(Icons.login),
          label: Text(
            'Sign In',
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }
}
