import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/client_task_models.dart';
import '../../../core/models/form_models.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/dynamic_form_field_tile.dart';
import '../../home/presentation/navigation_controller.dart';
import '../data/client_tasks_repository.dart';

final clientTasksProvider = FutureProvider.autoDispose((ref) {
  return ref.read(clientTasksRepositoryProvider).listTasks();
});

class ClientTasksScreen extends ConsumerWidget {
  const ClientTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(clientTasksProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientTasksProvider);
        await ref.read(clientTasksProvider.future);
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
                  'Tareas pendientes',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF67E8F9),
                        letterSpacing: 2.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accion requerida. Aqui veras lo que esta pendiente de tu parte para avanzar tus tramites.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          tasksAsync.when(
            loading: () => const SizedBox(height: 260, child: LoadingView(label: 'Cargando tareas pendientes...')),
            error: (error, _) => AppCard(
              child: EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: 'No pudimos cargar tus tareas',
                subtitle: error.toString(),
                action: FilledButton(
                  onPressed: () => ref.invalidate(clientTasksProvider),
                  child: const Text('Reintentar'),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const AppCard(
                  child: EmptyStateView(
                    icon: Icons.inbox_outlined,
                    title: 'No tienes tareas pendientes',
                    subtitle: 'Cuando exista una accion requerida para ti, aparecera aqui automaticamente.',
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
                            Text(
                              item.processName,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF67E8F9),
                                    letterSpacing: 1.8,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.taskName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(item.areaName?.trim().isNotEmpty == true ? item.areaName! : 'Pendiente de tu parte'),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ClientTaskFormScreen(taskId: item.taskId),
                                    ),
                                  );
                                },
                                child: const Text('Completar'),
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
}

class ClientTaskFormScreen extends ConsumerStatefulWidget {
  const ClientTaskFormScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<ClientTaskFormScreen> createState() => _ClientTaskFormScreenState();
}

class _ClientTaskFormScreenState extends ConsumerState<ClientTaskFormScreen> {
  ClientTaskFormResponse? _form;
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  String? _submitError;
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final form = await ref.read(clientTasksRepositoryProvider).getForm(widget.taskId);
      _values.addAll(form.currentValues);
      setState(() {
        _form = form;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<FormFieldDefinition> get _fields {
    return _form?.formDefinition?.sortedFields ?? const <FormFieldDefinition>[];
  }

  void _setFieldValue(String fieldName, dynamic value) {
    setState(() {
      _values[fieldName] = value;
      _submitError = null;
    });
  }

  bool _isFieldMissing(FormFieldDefinition field) {
    final value = _values[field.name];

    if (!field.required) {
      return false;
    }

    switch (field.type) {
      case 'checkbox':
        return value != true;
      case 'checklist':
        return value is! List || (value as List).isEmpty;
      case 'file':
        return value == null;
      default:
        if (value == null) {
          return true;
        }
        return value is String ? value.trim().isEmpty : false;
    }
  }

  bool _isFormValid() {
    for (final field in _fields) {
      if (_isFieldMissing(field)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _pickFile(FormFieldDefinition field) async {
    final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false);
    final file = result?.files.isNotEmpty == true ? result!.files.first : null;
    if (file == null || file.bytes == null) {
      return;
    }

    _setFieldValue(
      field.name,
      PendingFileSelection(
        fileName: file.name,
        bytes: file.bytes!,
        mimeType: file.extension,
      ),
    );
  }

  Future<void> _pickDate(FormFieldDefinition field) async {
    final current = _values[field.name];
    final initialDate = current is String && current.trim().isNotEmpty
        ? DateTime.tryParse(current) ?? DateTime.now()
        : DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }

    _setFieldValue(field.name, selected.toIso8601String().split('T').first);
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    if (!_isFormValid()) {
      setState(() => _submitError = 'Completa los campos obligatorios antes de continuar.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final payload = await _buildPayload();
      final response = await ref.read(clientTasksRepositoryProvider).completeTask(widget.taskId, payload);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message.isNotEmpty ? response.message : 'Tarea completada exitosamente.')),
      );
      ref.read(navigationControllerProvider).setIndex(2);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _submitError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<FormData> _buildPayload() async {
    final payload = FormData();
    final jsonPayload = <String, dynamic>{};

    for (final field in _fields) {
      final value = _values[field.name];
      if (value == null || value == '') {
        continue;
      }

      switch (field.type) {
        case 'file':
          if (value is PendingFileSelection) {
            payload.files.add(
              MapEntry(
                field.name,
                MultipartFile.fromBytes(value.bytes, filename: value.fileName),
              ),
            );
          } else if (value is UploadedFileMetadata) {
            jsonPayload[field.name] = value.toJson();
          }
          break;
        case 'number':
          final parsed = num.tryParse(value.toString());
          jsonPayload[field.name] = parsed ?? value;
          break;
        case 'date':
          jsonPayload[field.name] = value.toString();
          break;
        case 'checklist':
          jsonPayload[field.name] = value is List ? value : <String>[];
          break;
        case 'checkbox':
          jsonPayload[field.name] = value == true;
          break;
        default:
          jsonPayload[field.name] = value;
      }
    }

    payload.fields.add(MapEntry('formData', jsonEncode(jsonPayload)));
    return payload;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_form?.taskName ?? 'Completar tarea')),
      body: _loading ? const LoadingView(label: 'Cargando formulario...') : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: EmptyStateView(
              icon: Icons.error_outline_rounded,
              title: 'No pudimos abrir la tarea',
              subtitle: _errorMessage!,
              action: FilledButton(
                onPressed: _loadForm,
                child: const Text('Reintentar'),
              ),
            ),
          ),
        ),
      );
    }

    final form = _form;
    if (form == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    form.processName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF67E8F9),
                          letterSpacing: 2.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    form.taskName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    form.areaName?.trim().isNotEmpty == true ? form.areaName! : 'Accion requerida',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_fields.isNotEmpty)
              for (final field in _fields) ...[
                DynamicFormFieldTile(
                  field: field,
                  value: _values[field.name],
                  onChanged: (next) => _setFieldValue(field.name, next),
                  onPickFile: field.type == 'file' ? () => _pickFile(field) : null,
                  onPickDate: field.type == 'date' ? () => _pickDate(field) : null,
                ),
                const SizedBox(height: 12),
              ]
            else
              const AppCard(
                child: EmptyStateView(
                  icon: Icons.playlist_add_check_rounded,
                  title: 'Sin formulario definido',
                  subtitle: 'Puedes completar la tarea sin campos adicionales.',
                ),
              ),
            if (_submitError != null) ...[
              const SizedBox(height: 8),
              AppCard(
                child: Text(
                  _submitError!,
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                ),
              ),
            ],
            const SizedBox(height: 90),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: AppPrimaryButton(
            label: _submitting ? 'Enviando...' : 'Completar tarea',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
