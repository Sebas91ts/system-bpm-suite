import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/i18n/app_strings.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../assistant/presentation/client_assistant_screen.dart';
import 'navigation_controller.dart';
import '../../instances/presentation/client_instances_screen.dart';
import '../../notifications/presentation/client_notifications_screen.dart';
import '../../processes/presentation/client_processes_screen.dart';
import '../../tasks/presentation/client_tasks_screen.dart';
import '../../settings/presentation/client_settings_screen.dart';
import 'client_home_screen.dart';

class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key});

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  static const _tabs = <Widget>[
    ClientHomeScreen(),
    ClientProcessesScreen(),
    ClientInstancesScreen(),
    ClientTasksScreen(),
    ClientNotificationsScreen(),
    ClientSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).state;
    final navigationState = ref.watch(navigationControllerProvider);
    final prefs = ref.watch(appPreferencesProvider);
    final userName = authState.user?.fullName.isNotEmpty == true ? authState.user!.fullName : 'Cliente';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appTitle(prefs.localeCode),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 2.5,
                    color: const Color(0xFF67E8F9),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.logout(prefs.localeCode),
            onPressed: authState.loading
                ? null
                : () async {
                    await ref.read(authControllerProvider.notifier).logout();
                  },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: navigationState.index, children: _tabs),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClientAssistantScreen(
                contextHint: 'app movile de clientes, pantalla actual: ${_tabName(navigationState.index)}',
              ),
            ),
          );
        },
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(AppStrings.helpIa(prefs.localeCode)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationState.index,
        onDestinationSelected: (index) => ref.read(navigationControllerProvider).setIndex(index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: AppStrings.navHome(prefs.localeCode)),
          NavigationDestination(icon: const Icon(Icons.receipt_long_rounded), label: AppStrings.navProcesses(prefs.localeCode)),
          NavigationDestination(icon: const Icon(Icons.list_alt_rounded), label: AppStrings.navInstances(prefs.localeCode)),
          NavigationDestination(icon: const Icon(Icons.task_alt_rounded), label: AppStrings.navTasks(prefs.localeCode)),
          NavigationDestination(icon: const Icon(Icons.notifications_rounded), label: AppStrings.navNotifications(prefs.localeCode)),
          NavigationDestination(icon: const Icon(Icons.settings_rounded), label: AppStrings.navSettings(prefs.localeCode)),
        ],
      ),
    );
  }

  String _tabName(int index) {
    switch (index) {
      case 1:
        return 'tramites';
      case 2:
        return 'instancias';
      case 3:
        return 'tareas';
      case 4:
        return 'notificaciones';
      case 5:
        return 'ajustes';
      default:
        return 'inicio';
    }
  }
}
