import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../home/presentation/navigation_controller.dart';
import '../data/client_process_repository.dart';
import 'start_process_screen.dart';

final clientProcessesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(clientProcessRepositoryProvider).listProcesses();
});

class ClientProcessesScreen extends ConsumerWidget {
  const ClientProcessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final locale = prefs.localeCode;
    final processesAsync = ref.watch(clientProcessesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientProcessesProvider);
        await ref.read(clientProcessesProvider.future);
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
                  AppStrings.processesTitle(locale),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF67E8F9),
                        letterSpacing: 2.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.processesSubtitle(locale),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.processesDescription(locale),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          processesAsync.when(
            loading: () => SizedBox(height: 260, child: LoadingView(label: AppStrings.loadingProcesses(locale))),
            error: (error, _) => AppCard(
              child: EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: AppStrings.noProcesses(locale),
                subtitle: error.toString(),
                action: FilledButton(
                  onPressed: () => ref.invalidate(clientProcessesProvider),
                  child: Text(AppStrings.retry(locale)),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return AppCard(
                  child: EmptyStateView(
                    icon: Icons.inbox_outlined,
                    title: AppStrings.noProcessesAvailable(locale),
                    subtitle: AppStrings.processesDescription(locale),
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
                                        item.nombre,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                                _VersionPill(version: item.version),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.descripcion?.trim().isNotEmpty == true
                                  ? item.descripcion!.trim()
                                  : AppStrings.noDescription(locale),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    AppStrings.actionRequired(locale),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => StartProcessScreen(process: item),
                                      ),
                                    );
                                  },
                                  child: Text(AppStrings.startProcess(locale)),
                                ),
                              ],
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
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.version});

  final int version;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF113344),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF22D3EE).withOpacity(0.12)),
      ),
      child: Text(
        'v$version',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
