import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import 'navigation_controller.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final locale = prefs.localeCode;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.homeWelcome(locale),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF67E8F9),
                        letterSpacing: 2.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.homeSubtitle(locale),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.homeDescription(locale),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 420 ? 2 : 1,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.9,
          children: [
            _QuickCard(
              icon: Icons.add_circle_outline_rounded,
              title: AppStrings.quickNewProcess(locale),
              subtitle: AppStrings.processesSubtitle(locale),
              onTap: () => ref.read(navigationControllerProvider).setIndex(1),
            ),
            _QuickCard(
              icon: Icons.list_alt_rounded,
              title: AppStrings.quickMyProcesses(locale),
              subtitle: AppStrings.instancesSubtitle(locale),
              onTap: () => ref.read(navigationControllerProvider).setIndex(2),
            ),
            _QuickCard(
              icon: Icons.task_alt_rounded,
              title: AppStrings.quickPendingTasks(locale),
              subtitle: AppStrings.tasksSubtitle(locale),
              onTap: () => ref.read(navigationControllerProvider).setIndex(3),
            ),
            _QuickCard(
              icon: Icons.notifications_rounded,
              title: AppStrings.quickNotifications(locale),
              subtitle: AppStrings.notificationsSubtitle(locale),
              onTap: () => ref.read(navigationControllerProvider).setIndex(4),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF67E8F9)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
