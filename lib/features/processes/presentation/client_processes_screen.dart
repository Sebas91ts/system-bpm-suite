import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  'Nuevos tramites',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF67E8F9),
                        letterSpacing: 2.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Procesos disponibles para iniciar',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  'Selecciona el tramite que quieres comenzar y completa su primer formulario.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          processesAsync.when(
            loading: () => const SizedBox(height: 260, child: LoadingView(label: 'Cargando tramites disponibles...')),
            error: (error, _) => AppCard(
              child: EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: 'No pudimos cargar los tramites',
                subtitle: error.toString(),
                action: FilledButton(
                  onPressed: () => ref.invalidate(clientProcessesProvider),
                  child: const Text('Reintentar'),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const AppCard(
                  child: EmptyStateView(
                    icon: Icons.inbox_outlined,
                    title: 'No hay tramites disponibles',
                    subtitle: 'Cuando el sistema publique uno nuevo, aparecera aqui.',
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
                                  : 'Sin descripcion disponible.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Accion requerida: inicia y completa tu primer formulario.',
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
                                  child: const Text('Iniciar tramite'),
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
