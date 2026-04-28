import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_response.dart';
import '../../../core/network/api_client.dart';

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
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/assistant',
      data: {
        'message': _buildPrompt(message: message, contextHint: contextHint),
      },
    );

    final envelope = ApiResponse.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
      (json) => (json as Map<String, dynamic>)['response']?.toString() ?? '',
    );

    if (!envelope.success) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'No se pudo conectar con el asistente.');
    }

    return envelope.data;
  }

  String _buildPrompt({required String message, required String contextHint}) {
    return '''
Eres el asistente IA de una app movile Android para clientes de un sistema BPM.
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
