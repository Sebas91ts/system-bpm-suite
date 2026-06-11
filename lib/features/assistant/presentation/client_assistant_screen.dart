import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/models/form_models.dart';
import '../../../core/models/process_models.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../home/presentation/navigation_controller.dart';
import '../../processes/data/client_process_repository.dart';
import '../../tracking/presentation/client_tracking_screen.dart';
import '../data/client_assistant_repository.dart';

enum _AssistantStage {
  idle,
  choosingProcess,
  confirmingProcess,
  collectingForm,
  reviewingForm,
}

class ClientAssistantScreen extends ConsumerStatefulWidget {
  const ClientAssistantScreen({super.key, required this.contextHint});

  final String contextHint;

  @override
  ConsumerState<ClientAssistantScreen> createState() => _ClientAssistantScreenState();
}

class _ClientAssistantScreenState extends ConsumerState<ClientAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = SpeechToText();
  final List<_AssistantMessage> _messages = [
    const _AssistantMessage(
      role: 'assistant',
      text: 'Hola. En que puedo ayudarte? Puedo ayudarte a iniciar un tramite, buscar el proceso correcto y completar sus datos iniciales.',
    ),
  ];

  bool _loading = false;
  bool _listening = false;
  bool _speechAvailable = false;
  String? _error;
  String? _voiceError;
  String _voiceBaseText = '';

  _AssistantStage _stage = _AssistantStage.idle;
  List<ClientProcessListItem> _availableProcesses = [];
  List<ClientProcessListItem> _candidateProcesses = [];
  ClientProcessListItem? _selectedProcess;
  ClientProcessStartPreview? _preview;
  final Map<String, dynamic> _collectedValues = {};

  @override
  void initState() {
    super.initState();
    unawaited(_initializeSpeech());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _voiceError = 'No pude escuchar correctamente. Intenta de nuevo.';
          _listening = false;
        });
      },
    );
    if (mounted) {
      setState(() => _speechAvailable = available);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) {
      return;
    }

    await _speech.stop();
    setState(() {
      _messages.add(_AssistantMessage(role: 'user', text: text));
      _controller.clear();
      _loading = true;
      _error = null;
      _voiceError = null;
      _listening = false;
    });
    _scrollToBottom();

    try {
      await _handleTurn(text);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleTurn(String text) async {
    if (_isNegative(text) && _stage != _AssistantStage.collectingForm && _stage != _AssistantStage.reviewingForm) {
      _resetSession();
      _appendAssistant('Perfecto, cancelamos eso. Dime que tramite necesitas iniciar o que duda tienes.');
      return;
    }

    switch (_stage) {
      case _AssistantStage.choosingProcess:
        await _handleProcessChoice(text);
      case _AssistantStage.confirmingProcess:
        await _handleProcessConfirmation(text);
      case _AssistantStage.collectingForm:
        await _handleFormCollection(text);
      case _AssistantStage.reviewingForm:
        await _handleFormReview(text);
      case _AssistantStage.idle:
        await _handleInitialRequest(text);
    }
  }

  Future<void> _handleInitialRequest(String text) async {
    await _ensureProcessesLoaded();

    if (_availableProcesses.isEmpty) {
      _appendAssistant('Aun no hay tramites publicados para clientes. Cuando exista uno disponible, podre ayudarte a iniciarlo desde aqui.');
      return;
    }

    final recommendation = await _safeRecommendProcess(text);
    final candidates = _resolveCandidateProcesses(text, recommendation);

    if (candidates.isEmpty && _looksLikeQuestion(text)) {
      await _answerQuestion(text);
      return;
    }

    final options = candidates.isNotEmpty ? candidates : _availableProcesses.take(5).toList();
    _candidateProcesses = options;

    if (options.length == 1) {
      _selectedProcess = options.first;
      _stage = _AssistantStage.confirmingProcess;
      _appendAssistant(
        'Creo que el tramite correcto es "${options.first.nombre}". ${recommendation?.reason ?? 'Coincide con lo que me comentaste.'}\n\nQuieres iniciar este tramite? Responde "si" para continuar o "no" para buscar otro.',
      );
      return;
    }

    _stage = _AssistantStage.choosingProcess;
    _appendAssistant(
      'Tenemos estos tramites que pueden coincidir con tu solicitud:\n\n${_formatProcessOptions(options)}\n\nIndica el numero o el nombre del tramite que quieres iniciar.',
    );
  }

  Future<void> _handleProcessChoice(String text) async {
    final selected = _selectProcessFromMessage(text, _candidateProcesses);
    if (selected == null) {
      final alternatives = _resolveCandidateProcesses(text, null);
      if (alternatives.isNotEmpty) {
        _candidateProcesses = alternatives;
        _appendAssistant('Encontre estas opciones nuevas:\n\n${_formatProcessOptions(alternatives)}\n\nIndica el numero o el nombre del tramite.');
        return;
      }

      await _answerQuestion(text);
      _appendAssistant('Si quieres iniciar un tramite, dime el numero o nombre de una opcion disponible.');
      return;
    }

    _selectedProcess = selected;
    _stage = _AssistantStage.confirmingProcess;
    _appendAssistant('Seleccionaste "${selected.nombre}". Estas seguro de iniciar este tramite? Responde "si" para continuar.');
  }

  Future<void> _handleProcessConfirmation(String text) async {
    if (!_isAffirmative(text)) {
      if (_looksLikeQuestion(text)) {
        await _answerQuestion(text);
        _appendAssistant('Si quieres iniciar "${_selectedProcess?.nombre ?? 'este tramite'}", responde "si". Si prefieres buscar otro, responde "no".');
        return;
      }
      _stage = _AssistantStage.choosingProcess;
      _appendAssistant('Sin problema. Puedes elegir otro tramite o describirme nuevamente lo que necesitas.');
      return;
    }

    final process = _selectedProcess;
    if (process == null) {
      _resetSession();
      _appendAssistant('Perdi la seleccion del tramite. Dime nuevamente que necesitas iniciar.');
      return;
    }

    _preview = await ref.read(clientProcessRepositoryProvider).startPreview(process.processId);
    _collectedValues.clear();

    final fields = _sortedFields;
    if (fields.isEmpty) {
      await _startSelectedProcess();
      return;
    }

    final requiredFiles = fields.where((field) => field.required && field.type == 'file').toList();
    if (requiredFiles.isNotEmpty) {
      _resetSession();
      _appendAssistant(
        'Este tramite necesita archivos obligatorios (${requiredFiles.map((field) => field.labelOrName).join(', ')}). Por ahora el chat movil puede iniciar tramites con datos de texto; para archivos usa la pantalla de tramites.',
      );
      return;
    }

    _stage = _AssistantStage.collectingForm;
    _appendAssistant(
      'Perfecto. Para iniciar "${_preview?.processName ?? process.nombre}" necesito estos datos de la primera tarea "${_preview?.firstTaskName ?? 'Formulario inicial'}":\n\n${_formatMissingFields(_missingRequiredFields())}\n\nPuedes enviarlos en una sola frase.',
    );
  }

  Future<void> _handleFormCollection(String text) async {
    if (_looksLikeQuestion(text) && !_looksLikeFormData(text)) {
      await _answerQuestion(text);
      final missing = _missingRequiredFields();
      if (missing.isNotEmpty) {
        _appendAssistant('Para continuar, todavia necesito:\n\n${_formatMissingFields(missing)}');
      }
      return;
    }

    await _mergeFormSuggestions(text);

    final missing = _missingRequiredFields();
    if (missing.isNotEmpty) {
      _appendAssistant('Ya tome los datos que pude detectar. Aun falta:\n\n${_formatMissingFields(missing)}\n\nEnviame esos datos para poder iniciar el tramite.');
      return;
    }

    _stage = _AssistantStage.reviewingForm;
    _appendAssistant('Listo, ya tengo todos los datos necesarios. Confirmame si es correcto:\n\n${_formatCollectedValues()}\n\nSi algo esta mal, dime la correccion. Si todo esta bien, responde "si" y yo inicio el tramite.');
  }

  Future<void> _handleFormReview(String text) async {
    if (_isAffirmative(text)) {
      _appendAssistant('Perfecto, voy a iniciar tu tramite ahora.');
      await _startSelectedProcess();
      return;
    }

    if (_isNegative(text) && !_looksLikeFormData(text)) {
      _resetSession();
      _appendAssistant('Perfecto, no inicio el tramite. Si quieres, dime nuevamente que tramite necesitas.');
      return;
    }

    if (_looksLikeQuestion(text) && !_looksLikeFormData(text)) {
      await _answerQuestion(text);
      _appendAssistant('Cuando quieras continuar, confirma estos datos o enviame una correccion:\n\n${_formatCollectedValues()}');
      return;
    }

    await _mergeFormSuggestions(text);
    final missing = _missingRequiredFields();
    if (missing.isNotEmpty) {
      _stage = _AssistantStage.collectingForm;
      _appendAssistant('Actualice los datos que pude detectar, pero aun falta:\n\n${_formatMissingFields(missing)}');
      return;
    }

    _appendAssistant('Actualice la informacion. Confirmame si ahora esta correcto:\n\n${_formatCollectedValues()}\n\nResponde "si" para iniciar el tramite o dime que debo corregir.');
  }

  Future<void> _mergeFormSuggestions(String text) async {
    final preview = _preview;
    if (preview?.formDefinition == null) {
      return;
    }

    final result = await ref.read(clientAssistantRepositoryProvider).fillForm(
          transcript: text,
          processName: preview!.processName,
          taskName: preview.firstTaskName,
          areaName: preview.firstTaskAreaName,
          currentValues: Map<String, dynamic>.from(_collectedValues),
          fields: _sortedFields,
        );

    for (final suggestion in result.suggestions) {
      final field = _findFieldForSuggestion(suggestion.fieldName);
      if (field == null || suggestion.value == null || field.type == 'file') {
        continue;
      }
      _collectedValues[field.name] = _normalizeFieldValue(field, suggestion.value);
    }
  }

  Future<void> _startSelectedProcess() async {
    final process = _selectedProcess;
    if (process == null) {
      throw Exception('No hay tramite seleccionado.');
    }

    final result = await ref.read(clientProcessRepositoryProvider).startProcess(
          process.processId,
          variables: _buildVariablesPayload(),
        );

    _resetSession();
    ref.read(navigationControllerProvider).setIndex(2);
    _appendAssistant(
      'Listo, tu tramite "${result.processName.isNotEmpty ? result.processName : process.nombre}" ya esta iniciado.\n\nNumero de instancia: ${result.processInstanceId}.\nPuedes hacer seguimiento cuando quieras.',
      actionLabel: 'Ver seguimiento',
      processInstanceId: result.processInstanceId,
    );
  }

  Map<String, dynamic> _buildVariablesPayload() {
    final variables = <String, dynamic>{};
    for (final field in _sortedFields) {
      final value = _collectedValues[field.name];
      if (!_hasValue(field, value)) {
        continue;
      }
      variables[field.name] = field.type == 'checklist' && value is List ? value.join(',') : value;
    }
    return variables;
  }

  Future<void> _answerQuestion(String text) async {
    final process = _selectedProcess;
    if (process != null && _isProcessExplanationQuestion(text)) {
      final description = process.descripcion?.trim();
      _appendAssistant(
        description?.isNotEmpty == true
            ? 'El tramite "${process.nombre}" consiste en: $description'
            : 'El tramite "${process.nombre}" esta disponible para clientes. Te pedira los datos iniciales definidos por la primera tarea y luego podras hacer seguimiento desde Instancias.',
      );
      return;
    }

    try {
      final answer = await ref.read(clientAssistantRepositoryProvider).assist(
            message: text,
            processKey: process?.processKey,
            formId: _preview?.formDefinition?.id,
            currentFormValues: _collectedValues,
          );
      _appendAssistant(answer.trim().isNotEmpty ? answer.trim() : 'No pude generar una respuesta clara en este momento.');
    } catch (_) {
      _appendAssistant('Puedo ayudarte a iniciar tramites publicados para clientes. Dime que necesitas hacer y buscare el proceso mas cercano.');
    }
  }

  Future<ClientProcessRecommendation?> _safeRecommendProcess(String text) async {
    try {
      return await ref.read(clientAssistantRepositoryProvider).recommendProcess(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureProcessesLoaded() async {
    if (_availableProcesses.isNotEmpty) {
      return;
    }
    _availableProcesses = await ref.read(clientProcessRepositoryProvider).listProcesses();
  }

  List<ClientProcessListItem> _resolveCandidateProcesses(String text, ClientProcessRecommendation? recommendation) {
    final normalizedText = _normalize(text);
    final keys = <String>{};
    final recommendedKey = recommendation?.processKey;
    if (recommendedKey != null && recommendedKey.trim().isNotEmpty) {
      keys.add(_normalize(recommendedKey));
    }
    for (final alternative in recommendation?.alternatives ?? const <String>[]) {
      keys.add(_normalize(alternative));
    }

    final recommended = _availableProcesses.where((process) {
      final processKey = _normalize(process.processKey);
      final name = _normalize(process.nombre);
      return keys.contains(processKey) || keys.contains(name);
    });

    final lexical = _availableProcesses
        .map((process) => MapEntry(process, _scoreProcessMatch(normalizedText, process)))
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final merged = <String, ClientProcessListItem>{};
    for (final process in [...recommended, ...lexical.map((entry) => entry.key)]) {
      merged[process.processId] = process;
    }
    return merged.values.take(5).toList();
  }

  int _scoreProcessMatch(String normalizedText, ClientProcessListItem process) {
    final haystack = _normalize('${process.nombre} ${process.descripcion ?? ''} ${process.processKey}');
    final words = normalizedText.split(' ').where((word) => word.length > 2);
    var score = 0;
    for (final word in words) {
      if (haystack.contains(word)) {
        score += word.length;
      }
    }
    if (haystack.contains(normalizedText)) {
      score += 20;
    }
    return score;
  }

  ClientProcessListItem? _selectProcessFromMessage(String text, List<ClientProcessListItem> candidates) {
    final numericChoice = int.tryParse(text.trim());
    if (numericChoice != null && numericChoice >= 1 && numericChoice <= candidates.length) {
      return candidates[numericChoice - 1];
    }

    final normalizedText = _normalize(text);
    for (final process in candidates) {
      final name = _normalize(process.nombre);
      final key = _normalize(process.processKey);
      if (normalizedText.contains(name) || name.contains(normalizedText) || normalizedText.contains(key)) {
        return process;
      }
    }
    return null;
  }

  List<FormFieldDefinition> get _sortedFields {
    final fields = [...(_preview?.formDefinition?.fields ?? const <FormFieldDefinition>[])];
    fields.sort((a, b) => a.order.compareTo(b.order));
    return fields;
  }

  List<FormFieldDefinition> _missingRequiredFields() {
    return _sortedFields.where((field) => field.required && !_hasValue(field, _collectedValues[field.name])).toList();
  }

  bool _hasValue(FormFieldDefinition field, dynamic value) {
    if (field.type == 'checkbox') {
      return value == true;
    }
    if (field.type == 'checklist') {
      return value is List && value.isNotEmpty;
    }
    if (value == null) {
      return false;
    }
    return value is String ? value.trim().isNotEmpty : true;
  }

  FormFieldDefinition? _findFieldForSuggestion(String fieldName) {
    final normalizedFieldName = _normalize(fieldName);
    for (final field in _sortedFields) {
      final aliases = _fieldAliases(field).map(_normalize).toSet();
      if (_normalize(field.name) == normalizedFieldName ||
          _normalize(field.label) == normalizedFieldName ||
          aliases.contains(normalizedFieldName)) {
        return field;
      }
    }

    for (final field in _sortedFields) {
      final fieldText = _normalize('${field.name} ${field.label} ${_fieldAliases(field).join(' ')}');
      if (normalizedFieldName.length > 1 && (fieldText.contains(normalizedFieldName) || normalizedFieldName.contains(fieldText))) {
        return field;
      }
    }
    return null;
  }

  List<String> _fieldAliases(FormFieldDefinition field) {
    final normalized = _normalize('${field.name} ${field.label}');
    final aliases = <String>[];
    if (normalized.contains('nombre') || normalized.contains('name')) {
      aliases.addAll(['name', 'nombre', 'nombre completo', 'mi nombre']);
    }
    if (normalized.contains('telefono') || normalized.contains('celular') || normalized.contains('phone')) {
      aliases.addAll(['telefono', 'celular', 'numero de telefono', 'phone']);
    }
    if (normalized.contains('carnet') || normalized.contains('ci') || normalized.contains('cedula') || normalized.contains('documento')) {
      aliases.addAll(['carnet', 'ci', 'cedula', 'documento', 'numero de documento']);
    }
    if (normalized.contains('correo') || normalized.contains('email')) {
      aliases.addAll(['correo', 'email', 'correo electronico']);
    }
    if (normalized.contains('direccion')) {
      aliases.addAll(['direccion', 'domicilio']);
    }
    return aliases;
  }

  dynamic _normalizeFieldValue(FormFieldDefinition field, dynamic value) {
    if (field.type == 'number') {
      final parsed = num.tryParse(value.toString());
      return parsed ?? value;
    }
    if (field.type == 'checkbox') {
      if (value is bool) {
        return value;
      }
      final normalized = _normalize(value.toString());
      return ['si', 'true', 'verdadero', 'acepto', 'confirmo'].contains(normalized);
    }
    if (field.type == 'checklist') {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return value.toString().split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    }
    return value;
  }

  bool _looksLikeFormData(String text) {
    final normalized = _normalize(text);
    final hints = _sortedFields.expand((field) => [field.name, field.label, field.placeholder ?? '', ..._fieldAliases(field)]);
    return hints.any((hint) {
      final normalizedHint = _normalize(hint);
      return normalizedHint.length > 1 && normalized.contains(normalizedHint);
    }) || RegExp(r'\d{4,}').hasMatch(normalized);
  }

  bool _looksLikeQuestion(String text) {
    final normalized = _normalize(text);
    return ['que', 'como', 'donde', 'cuando', 'porque', 'ayuda', 'duda'].any(normalized.contains) || text.contains('?');
  }

  bool _isProcessExplanationQuestion(String text) {
    final normalized = _normalize(text);
    return ['consiste', 'que hace', 'para que', 'explica', 'detalle', 'informacion', 'registro'].any(normalized.contains);
  }

  bool _isAffirmative(String text) {
    final normalized = _normalize(text);
    return normalized == 's' || ['si', 'ok', 'dale', 'confirmo', 'iniciar', 'claro', 'correcto', 'acepto'].any(normalized.contains);
  }

  bool _isNegative(String text) {
    final normalized = _normalize(text);
    return ['no', 'cancelar', 'cancela', 'salir', 'olvidalo'].any((word) {
      return normalized == word || normalized.startsWith('$word ') || normalized.contains(' $word ');
    });
  }

  String _formatProcessOptions(List<ClientProcessListItem> processes) {
    return processes
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value.nombre}${entry.value.descripcion?.trim().isNotEmpty == true ? ' - ${entry.value.descripcion}' : ''}')
        .join('\n');
  }

  String _formatMissingFields(List<FormFieldDefinition> fields) {
    return fields.map((field) => '- ${field.labelOrName}${field.helpText?.trim().isNotEmpty == true ? ': ${field.helpText}' : ''}').join('\n');
  }

  String _formatCollectedValues() {
    final lines = _sortedFields
        .where((field) => _hasValue(field, _collectedValues[field.name]))
        .map((field) => '- ${field.labelOrName}: ${_formatValue(_collectedValues[field.name])}')
        .toList();
    return lines.isNotEmpty ? lines.join('\n') : '- Sin datos capturados todavia.';
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    if (value is bool) {
      return value ? 'Si' : 'No';
    }
    return value?.toString() ?? '';
  }

  void _resetSession() {
    _stage = _AssistantStage.idle;
    _candidateProcesses = [];
    _selectedProcess = null;
    _preview = null;
    _collectedValues.clear();
  }

  void _appendAssistant(String text, {String? actionLabel, String? processInstanceId}) {
    setState(() {
      _messages.add(_AssistantMessage(
        role: 'assistant',
        text: text,
        actionLabel: actionLabel,
        processInstanceId: processInstanceId,
      ));
    });
    _scrollToBottom();
  }

  Future<void> _toggleVoice() async {
    if (!_speechAvailable) {
      setState(() => _voiceError = 'El reconocimiento de voz no esta disponible en este dispositivo.');
      return;
    }

    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    _voiceBaseText = _controller.text.trim();
    setState(() {
      _voiceError = null;
      _listening = true;
    });

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'es_ES',
        listenMode: ListenMode.dictation,
      ),
      onResult: _onSpeechResult,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final transcript = result.recognizedWords.trim();
    final nextText = [_voiceBaseText, transcript].where((item) => item.trim().isNotEmpty).join(' ').trim();
    setState(() => _controller.text = nextText);
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));

    if (result.finalResult && nextText.isNotEmpty && !_loading) {
      Future.microtask(_send);
    }
  }

  void _openTracking(String processInstanceId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientTrackingScreen(processInstanceId: processInstanceId),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    return raw.isNotEmpty ? raw : 'No se pudo conectar con el asistente.';
  }

  String _normalize(String text) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
      'ü': 'u',
    };
    var normalized = text.toLowerCase();
    accents.forEach((from, to) => normalized = normalized.replaceAll(from, to));
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.helpIa(prefs.localeCode))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asistente de tramites', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Describe lo que necesitas. Puedo recomendar un tramite, pedirte los datos y dejarlo iniciado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_loading && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Bubble(role: 'assistant', text: 'Pensando...'),
                  );
                }

                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Bubble(
                    role: message.role,
                    text: message.text,
                    actionLabel: message.actionLabel,
                    onAction: message.processInstanceId == null ? null : () => _openTracking(message.processInstanceId!),
                  ),
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
              ),
            ),
          if (_voiceError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_voiceError!, style: const TextStyle(color: Color(0xFFFCA5A5))),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _listening ? 'Escuchando...' : 'Ej. Quiero registrar una solicitud...',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _loading ? null : _toggleVoice,
                  icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded),
                  tooltip: _listening ? 'Detener dictado' : 'Dictar por voz',
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _send,
                  child: Text(_loading ? '...' : 'Enviar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantMessage {
  const _AssistantMessage({
    required this.role,
    required this.text,
    this.actionLabel,
    this.processInstanceId,
  });

  final String role;
  final String text;
  final String? actionLabel;
  final String? processInstanceId;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.role,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String role;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.route_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on FormFieldDefinition {
  String get labelOrName => label.trim().isNotEmpty ? label : name;
}
