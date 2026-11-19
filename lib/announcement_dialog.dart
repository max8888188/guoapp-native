import 'package:flutter/material.dart';

import 'announcement.dart';
import 'app_layout.dart';

Future<void> showAnnouncementDialog(
  BuildContext context,
  Announcement announcement,
  VoidCallback onDismiss,
) async {
  if (!announcement.ready) return;
  final television = AppLayout.isTelevision(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: !announcement.mandatory,
    builder: (_) => PopScope(
      canPop: !announcement.mandatory,
      child: _AnnouncementDialog(
        announcement: announcement,
        television: television,
        onDismiss: onDismiss,
      ),
    ),
  );
}

class _AnnouncementDialog extends StatelessWidget {
  const _AnnouncementDialog({
    required this.announcement,
    required this.television,
    required this.onDismiss,
  });

  final Announcement announcement;
  final bool television;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          if (announcement.mandatory) ...[
            Icon(
              Icons.campaign_rounded,
              color: colors.primary,
              size: television ? 32 : 24,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              announcement.title,
              style: television
                  ? const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)
                  : null,
            ),
          ),
          if (!announcement.mandatory)
            ExcludeFocus(
              child: IconButton(
                tooltip: '关闭',
                onPressed: () => _close(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: television ? 640 : 460,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (announcement.body.isNotEmpty)
                  Text(
                    announcement.body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: television ? 22 : 16,
                      height: 1.7,
                    ),
                  ),
                if (announcement.actionUrl.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    announcement.actionText.isEmpty
                        ? '公告链接'
                        : announcement.actionText,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: television ? 20 : 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: ExcludeFocus(
                      child: SelectableText(
                        announcement.actionUrl,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                          fontSize: television ? 20 : 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        FilledButton(
          autofocus: television,
          onPressed: () => _close(context),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: television ? 26 : 18,
              vertical: television ? 8 : 4,
            ),
            child: Text(
              '我知道了',
              style: TextStyle(fontSize: television ? 20 : 15),
            ),
          ),
        ),
      ],
    );
  }

  void _close(BuildContext context) {
    Navigator.of(context).pop();
    onDismiss();
  }
}
