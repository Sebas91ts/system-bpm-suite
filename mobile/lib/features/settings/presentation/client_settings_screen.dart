import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';

class ClientSettingsScreen extends ConsumerWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.navSettings(prefs.localeCode),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF67E8F9),
                      letterSpacing: 2.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.settingsHint(prefs.localeCode),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.language(prefs.localeCode), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'es',
                    label: Text(AppStrings.spanish(prefs.localeCode)),
                    icon: const Icon(Icons.translate_rounded),
                  ),
                  ButtonSegment(
                    value: 'en',
                    label: Text(AppStrings.english(prefs.localeCode)),
                    icon: const Icon(Icons.translate_rounded),
                  ),
                ],
                selected: {prefs.localeCode},
                onSelectionChanged: (selection) {
                  ref.read(appPreferencesProvider).setLocaleCode(selection.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.theme(prefs.localeCode), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(AppStrings.dark(prefs.localeCode)),
                    icon: const Icon(Icons.dark_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(AppStrings.light(prefs.localeCode)),
                    icon: const Icon(Icons.light_mode_rounded),
                  ),
                ],
                selected: {prefs.themeMode},
                onSelectionChanged: (selection) {
                  ref.read(appPreferencesProvider).setThemeMode(selection.first);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
