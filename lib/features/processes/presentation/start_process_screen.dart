import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/form_models.dart';
import '../../../core/models/process_models.dart';
import '../../../core/network/file_upload_repository.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/dynamic_form_field_tile.dart';
import '../../home/presentation/navigation_controller.dart';
import '../data/client_process_repository.dart';

class StartProcessScreen extends ConsumerStatefulWidget {
  const StartProcessScreen({super.key, required this.process});

  final ClientProcessListItem process;

  @override
  ConsumerState<StartProcessScreen> createState() => _StartProcessScreenState();
}

class _StartProcessScreenState extends ConsumerState<StartProcessScreen> {
  ClientProcessStartPreview? _preview;
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  String? _submitError;
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final preview = await ref.read(clientProcessRepositoryProvider).startPreview(widget.process.processId);
      setState(() {
        _preview = preview;
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
    final fields = _preview?.formDefinition?.sortedFields ?? const <FormFieldDefinition>[];
    return fields;
  }

  bool _isFormValid() {
    for (final field in _fields) {
      if (_isFieldMissing(field)) {
        return false;
      }
    }
    return true;
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

  void _setFieldValue(String fieldName, dynamic value) {
    setState(() {
      _values[fieldName] = value;
      _submitError = null;
    });
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
      final payload = await _buildVariablesPayload();
      final result = await ref.read(clientProcessRepositoryProvider).startProcess(
            widget.process.processId,
            variables: payload,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message.isNotEmpty ? result.message : 'Tramite iniciado exitosamente.')),
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

  Future<Map<String, dynamic>> _buildVariablesPayload() async {
    final payload = <String, dynamic>{};
    final fileRepo = ref.read(fileUploadRepositoryProvider);

    for (final field in _fields) {
      final value = _values[field.name];
      if (value == null || value == '') {
        continue;
      }

      switch (field.type) {
        case 'file':
          if (value is PendingFileSelection) {
            final uploaded = await fileRepo.uploadFile(
              bytes: value.bytes,
              fileName: value.fileName,
              mimeType: value.mimeType,
            );
            payload[field.name] = uploaded.toJson();
          }
          break;
        case 'number':
          final parsed = num.tryParse(value.toString());
          payload[field.name] = parsed ?? value;
          break;
        case 'date':
          payload[field.name] = value.toString();
          break;
        case 'checklist':
          payload[field.name] = jsonEncode((value as List).map((item) => item.toString()).toList());
          break;
        case 'checkbox':
          payload[field.name] = value == true;
          break;
        default:
          payload[field.name] = value;
      }
    }

    return payload;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.process.nombre),
      ),
      body: _loading
          ? const LoadingView(label: 'Cargando formulario inicial...')
          : _errorView(context),
    );
  }

  Widget _errorView(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: EmptyStateView(
              icon: Icons.error_outline_rounded,
              title: 'No pudimos abrir el tramite',
              subtitle: _errorMessage!,
              action: FilledButton(
                onPressed: _loadPreview,
                child: const Text('Reintentar'),
              ),
            ),
          ),
        ),
      );
    }

    final preview = _preview;
    if (preview == null) {
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
                    'Nuevo tramite',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF67E8F9),
                          letterSpacing: 2.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preview.firstTaskName?.trim().isNotEmpty == true
                        ? preview.firstTaskName!.trim()
                        : preview.processName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Completa este primer formulario para iniciar y procesar tu tramite.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_fields.isNotEmpty) ...[
              for (final field in _fields) ...[
                DynamicFormFieldTile(
                  field: field,
                  value: _values[field.name],
                  onChanged: (next) => _setFieldValue(field.name, next),
                  onPickFile: field.type == 'file' ? () => _pickFile(field) : null,
                  onPickDate: field.type == 'date' ? () => _pickDate(field) : null,
                ),
                const SizedBox(height: 12),
              ],
            ] else
              const AppCard(
                child: EmptyStateView(
                  title: 'Sin formulario adicional',
                  subtitle: 'El tramite se puede iniciar directamente.',
                  icon: Icons.playlist_add_check_rounded,
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
            label: _submitting ? 'Iniciando...' : 'Iniciar tramite',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
