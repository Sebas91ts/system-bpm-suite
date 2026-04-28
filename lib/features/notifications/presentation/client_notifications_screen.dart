import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/models/notification_models.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/client_notifications_repository.dart';

final clientNotificationsProvider = FutureProvider.autoDispose((ref) {
  return ref.read(clientNotificationsRepositoryProvider).listNotifications();
});

class ClientNotificationsScreen extends ConsumerWidget {
  const ClientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final locale = prefs.localeCode;
    final notificationsAsync = ref.watch(clientNotificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientNotificationsProvider);
        await ref.read(clientNotificationsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.notificationsTitle(locale),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFF67E8F9),
                                  letterSpacing: 2.5,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.notificationsSubtitle(locale),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        await ref.read(clientNotificationsRepositoryProvider).markAllAsRead();
                        ref.invalidate(clientNotificationsProvider);
                      },
                      child: Text(AppStrings.markAllRead(locale)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          notificationsAsync.when(
            loading: () => SizedBox(height: 260, child: LoadingView(label: AppStrings.loadingNotifications(locale))),
            error: (error, _) => AppCard(
              child: EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: AppStrings.noNotifications(locale),
                subtitle: error.toString(),
                action: FilledButton(
                  onPressed: () => ref.invalidate(clientNotificationsProvider),
                  child: Text(AppStrings.retry(locale)),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return AppCard(
                  child: EmptyStateView(
                    icon: Icons.notifications_off_rounded,
                    title: AppStrings.noNotificationsAvailable(locale),
                    subtitle: AppStrings.notificationsSubtitle(locale),
                  ),
                );
              }

              return Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(item.message, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                                _ReadChip(read: item.read, localeCode: locale),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(item.createdAt != null ? _formatDate(item.createdAt, locale) : AppStrings.noDate(locale), style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                                child: TextButton(
                                onPressed: item.read
                                    ? null
                                    : () async {
                                        await ref.read(clientNotificationsRepositoryProvider).markAsRead(item.id);
                                        ref.invalidate(clientNotificationsProvider);
                                      },
                                child: Text(AppStrings.markRead(locale)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(String? value, String localeCode) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.noDate(localeCode);
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}

class _ReadChip extends StatelessWidget {
  const _ReadChip({required this.read, required this.localeCode});

  final bool read;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: read ? const Color(0xFF0F5132) : const Color(0xFF3A2F0F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(read ? AppStrings.read(localeCode) : AppStrings.unread(localeCode)),
    );
  }
}
