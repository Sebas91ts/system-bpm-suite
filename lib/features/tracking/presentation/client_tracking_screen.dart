import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/form_models.dart';
import '../../../core/models/process_tracking_models.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/client_tracking_repository.dart';
import 'client_bpmn_viewer_screen.dart';

final clientTrackingProvider = FutureProvider.family.autoDispose<ClientInstanceTracking, String>((ref, processInstanceId) {
  return ref.read(clientTrackingRepositoryProvider).getTracking(processInstanceId);
});

class ClientTrackingScreen extends ConsumerWidget {
  const ClientTrackingScreen({super.key, required this.processInstanceId});

  final String processInstanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(clientTrackingProvider(processInstanceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientTrackingProvider(processInstanceId));
          await ref.read(clientTrackingProvider(processInstanceId).future);
        },
        child: trackingAsync.when(
          loading: () => ListView(
            children: [
              SizedBox(height: 260, child: LoadingView(label: 'Cargando seguimiento...')),
            ],
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: EmptyStateView(
                  icon: Icons.error_outline_rounded,
                  title: 'No pudimos cargar el seguimiento',
                  subtitle: error.toString(),
                  action: FilledButton(
                    onPressed: () => ref.invalidate(clientTrackingProvider(processInstanceId)),
                    child: const Text('Reintentar'),
                  ),
                ),
              ),
            ],
          ),
          data: (tracking) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seguimiento de tramite',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF67E8F9),
                              letterSpacing: 2.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tracking.processName?.trim().isNotEmpty == true ? tracking.processName! : 'Tramite',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Revisa el avance, los pasos completados y lo que enviaste en tus tareas.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _StatusBadge(label: tracking.estado ?? 'ACTIVA'),
                          const SizedBox(width: 12),
                          Text(
                            'Actualizacion: ${_formatDate(tracking.startedAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if ((tracking.xmlBpmn ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClientBpmnViewerScreen(
                                    xmlBpmn: tracking.xmlBpmn!,
                                    title: tracking.processName?.trim().isNotEmpty == true
                                        ? tracking.processName!
                                        : 'Diagrama BPMN',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.account_tree_outlined),
                            label: const Text('Ver diagrama'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen visual', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 14),
                      _ProgressBar(value: tracking.progressPercentage ?? 0),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _LegendPill(color: const Color(0xFF3B82F6), label: 'Activa'),
                          _LegendPill(color: const Color(0xFF10B981), label: 'Finalizada'),
                          _LegendPill(color: const Color(0xFFF59E0B), label: 'Pendiente'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Paso actual', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        tracking.currentTaskName?.trim().isNotEmpty == true ? tracking.currentTaskName! : 'Sin paso actual',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tracking.currentAreaName?.trim().isNotEmpty == true ? tracking.currentAreaName! : 'Area no definida',
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
                      Text('Tus envios', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      if (tracking.history.isEmpty)
                        const EmptyStateView(
                          icon: Icons.inbox_outlined,
                          title: 'Sin envios aun',
                          subtitle: 'Cuando completes una tarea, aqui apareceran tus datos.',
                        )
                      else
                        ...tracking.history.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HistoryEntryCard(entry: entry),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sin fecha';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF113344),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label.toUpperCase()),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final progress = (value.clamp(0, 100)) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress, minHeight: 12),
        ),
        const SizedBox(height: 8),
        Text('${value.clamp(0, 100)}% completado', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry});

  final ClientTrackingHistoryItem entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.taskName?.trim().isNotEmpty == true ? entry.taskName! : 'Tarea', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(entry.areaName?.trim().isNotEmpty == true ? entry.areaName! : 'Area no indicada', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(entry.completedAt?.trim().isNotEmpty == true ? entry.completedAt! : 'Sin fecha', style: Theme.of(context).textTheme.bodySmall),
          if (entry.formData != null && entry.formData!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.formData!.entries.map((item) => _FieldChip(entry: item)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldChip extends StatelessWidget {
  const _FieldChip({required this.entry});

  final MapEntry<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final value = _displayValue(entry.value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1628),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.key, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF67E8F9))),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _displayValue(dynamic value) {
    if (value == null) {
      return 'Sin dato';
    }

    if (value is Map<String, dynamic>) {
      if (value['fileName'] is String && (value['fileName'] as String).trim().isNotEmpty) {
        return value['fileName'] as String;
      }
      return value.entries.map((entry) => '${entry.key}: ${_displayValue(entry.value)}').join(' | ');
    }

    if (value is List) {
      return value.map((item) => _displayValue(item)).join(', ');
    }

    return value.toString();
  }
}
