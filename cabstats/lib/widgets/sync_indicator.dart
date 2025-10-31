import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../screens/sync_screen.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = SyncService();
    final status = syncService.status;
    final lastSyncTime = syncService.lastSyncTime;

    // Don't show if never synced and idle
    if (status == SyncStatus.idle && lastSyncTime == null) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (status == SyncStatus.syncing) {
      statusColor = Colors.blue;
      statusIcon = Icons.sync;
      statusText = 'Syncing...';
    } else if (status == SyncStatus.success) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Synced';
    } else if (status == SyncStatus.error) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Sync Failed';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.sync;
      statusText = 'Tap to Sync';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SyncScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == SyncStatus.syncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
            else
              Icon(
                statusIcon,
                size: 16,
                color: statusColor,
              ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

