import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../tracking/presentation/client_tracking_screen.dart';
import '../data/client_instances_repository.dart';

final clientInstancesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(clientInstancesRepositoryProvider).listInstances();
});

class ClientInstancesScreen extends ConsumerWidget {
  const ClientInstancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final locale = prefs.localeCode;
    final instancesAsync = ref.watch(clientInstancesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientInstancesProvider);
        await ref.read(clientInstancesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.instancesTitle(locale),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF67E8F9),
                        letterSpacing: 2.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.instancesSubtitle(locale),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          instancesAsync.when(
            loading: () => SizedBox(height: 260, child: LoadingView(label: AppStrings.loadingInstances(locale))),
            error: (error, _) => AppCard(
              child: EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: AppStrings.noInstances(locale),
                subtitle: error.toString(),
                action: FilledButton(
                  onPressed: () => ref.invalidate(clientInstancesProvider),
                  child: Text(AppStrings.retry(locale)),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return AppCard(
                  child: EmptyStateView(
                    icon: Icons.inbox_outlined,
                    title: AppStrings.noInstancesAvailable(locale),
                    subtitle: AppStrings.instancesSubtitle(locale),
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
                                        item.processKey.toUpperCase(),
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: const Color(0xFF67E8F9),
                                              letterSpacing: 1.8,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.processName,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                                _StatePill(label: item.estado, localeCode: locale),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('${AppStrings.versionLabel(locale)}: v${item.processVersion}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 6),
                            Text('${AppStrings.startLabel(locale)}: ${_formatDate(item.startedAt, locale)}', style: Theme.of(context).textTheme.bodyMedium),
                            if ((item.finishedAt ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('${AppStrings.endLabel(locale)}: ${_formatDate(item.finishedAt, locale)}', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ClientTrackingScreen(processInstanceId: item.processInstanceId),
                                    ),
                                  );
                                },
                                child: Text(AppStrings.viewTracking(locale)),
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

class _StatePill extends StatelessWidget {
  const _StatePill({required this.label, required this.localeCode});

  final String label;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF113344),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label.trim().isNotEmpty ? label : AppStrings.activeLabel(localeCode)),
    );
  }
}
