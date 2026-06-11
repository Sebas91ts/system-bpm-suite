import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/models/form_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/offline_support.dart';

final clientAssistantRepositoryProvider = Provider<ClientAssistantRepository>((ref) {
  return ClientAssistantRepository(ref.read(dioProvider));
});

class ClientAssistantRepository {
  ClientAssistantRepository(this._dio);

  final Dio _dio;

  Future<String> ask({
    required String message,
    required String contextHint,
  }) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/ai/assistant',
        data: {
          'message': _buildPrompt(message: message, contextHint: contextHint),
        },
      );
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => (json as Map<String, dynamic>)['response']?.toString() ?? '',
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo conectar con el asistente.');
    }

    return envelope.data;
  }

  Future<ClientProcessRecommendation> recommendProcess(String message) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/ai/recommend-process',
        data: {'message': message},
      );
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => ClientProcessRecommendation.fromJson(_asMap(json)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No pude recomendar un tramite.');
    }

    return envelope.data;
  }

  Future<FormFillResult> fillForm({
    required String transcript,
    required String processName,
    required String? taskName,
    required String? areaName,
    required Map<String, dynamic> currentValues,
    required List<FormFieldDefinition> fields,
  }) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/ai/fill-form',
        data: {
          'transcript': transcript,
          'processName': processName,
          'taskName': taskName,
          'areaName': areaName,
          'currentValues': currentValues,
          'fields': fields.map((field) {
            return {
              'name': field.name,
              'label': field.label,
              'type': field.type,
              'required': field.required,
              'placeholder': field.placeholder,
              'helpText': field.helpText,
              'options': field.optionItems.isNotEmpty
                  ? field.optionItems.map((option) => option.value.isNotEmpty ? option.value : option.label).toList()
                  : field.options,
            };
          }).toList(),
        },
      );
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => FormFillResult.fromJson(_asMap(json)),
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No pude interpretar los datos del formulario.');
    }

    return envelope.data;
  }

  Future<String> assist({
    required String message,
    String? processKey,
    String? formId,
    Map<String, dynamic>? currentFormValues,
  }) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/ai/assist',
        data: {
          'message': message,
          'processKey': processKey,
          'formId': formId,
          'currentFormValues': currentFormValues ?? const <String, dynamic>{},
        },
      );
    } catch (error) {
      throw Exception(friendlyOfflineMessage(error));
    }

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => (_asMap(json)['response'] as String?) ?? '',
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No pude responder en este momento.');
    }

    return envelope.data;
  }

  String _buildPrompt({required String message, required String contextHint}) {
    return '''
Eres el asistente IA de una app movil Android para clientes de un sistema BPM.
Contexto de uso: $contextHint.
Solo ayudas a usuarios con rol ROLE_CLIENT.
Responde de forma clara, corta y practica.
No hables de funciones internas de funcionarios salvo para decir que no estan disponibles para clientes.
Ayuda con:
- iniciar tramites
- ver mis tramites
- seguimiento
- tareas pendientes
- notificaciones
- carga de archivos

Pregunta del cliente:
$message
''';
  }
}

class ClientProcessRecommendation {
  const ClientProcessRecommendation({
    required this.intent,
    required this.confidence,
    required this.reason,
    this.processKey,
    this.requiredDocuments = const [],
    this.requiredForms = const [],
    this.alternatives = const [],
  });

  final String intent;
  final double confidence;
  final String reason;
  final String? processKey;
  final List<String> requiredDocuments;
  final List<String> requiredForms;
  final List<String> alternatives;

  factory ClientProcessRecommendation.fromJson(Map<String, dynamic> json) {
    return ClientProcessRecommendation(
      intent: (json['intent'] as String?) ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reason: (json['reason'] as String?) ?? '',
      processKey: json['processKey'] as String?,
      requiredDocuments: _stringList(json['requiredDocuments']),
      requiredForms: _stringList(json['requiredForms']),
      alternatives: _stringList(json['alternatives']),
    );
  }
}

class FormFillResult {
  const FormFillResult({
    required this.summary,
    required this.suggestions,
  });

  final String summary;
  final List<FormFillSuggestion> suggestions;

  factory FormFillResult.fromJson(Map<String, dynamic> json) {
    return FormFillResult(
      summary: (json['summary'] as String?) ?? '',
      suggestions: json['suggestions'] is List
          ? (json['suggestions'] as List)
              .whereType<Map>()
              .map((item) => FormFillSuggestion.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const <FormFillSuggestion>[],
    );
  }
}

class FormFillSuggestion {
  const FormFillSuggestion({
    required this.fieldName,
    this.value,
    this.rationale,
  });

  final String fieldName;
  final dynamic value;
  final String? rationale;

  factory FormFillSuggestion.fromJson(Map<String, dynamic> json) {
    return FormFillSuggestion(
      fieldName: (json['fieldName'] as String?) ?? '',
      value: json['value'],
      rationale: json['rationale'] as String?,
    );
  }
}

Map<String, dynamic> _asMap(dynamic json) {
  if (json is Map<String, dynamic>) {
    return json;
  }
  if (json is Map) {
    return Map<String, dynamic>.from(json);
  }
  return const <String, dynamic>{};
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
  }
  return const <String>[];
}
