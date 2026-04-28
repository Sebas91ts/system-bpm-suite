import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import 'navigation_controller.dart';
import '../../instances/presentation/client_instances_screen.dart';
import '../../notifications/presentation/client_notifications_screen.dart';
import '../../processes/presentation/client_processes_screen.dart';
import '../../tasks/presentation/client_tasks_screen.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).state;
    final navigationState = ref.watch(navigationControllerProvider);
    final userName = authState.user?.fullName.isNotEmpty == true ? authState.user!.fullName : 'Cliente';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portal Cliente',
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
            tooltip: 'Cerrar sesion',
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationState.index,
        onDestinationSelected: (index) => ref.read(navigationControllerProvider).setIndex(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Tramites'),
          NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: 'Instancias'),
          NavigationDestination(icon: Icon(Icons.task_alt_rounded), label: 'Tareas'),
          NavigationDestination(icon: Icon(Icons.notifications_rounded), label: 'Avisos'),
        ],
      ),
    );
  }
}
