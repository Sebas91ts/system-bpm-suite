import 'form_models.dart';

class ClientProcessListItem {
  const ClientProcessListItem({
    required this.processId,
    required this.processKey,
    required this.nombre,
    required this.version,
    this.descripcion,
  });

  final String processId;
  final String processKey;
  final String nombre;
  final int version;
  final String? descripcion;

  factory ClientProcessListItem.fromJson(Map<String, dynamic> json) {
    return ClientProcessListItem(
      processId: (json['processId'] as String?) ?? '',
      processKey: (json['processKey'] as String?) ?? '',
      nombre: (json['nombre'] as String?) ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      descripcion: json['descripcion'] as String?,
    );
  }
}

class ClientProcessStartPreview {
  const ClientProcessStartPreview({
    required this.processId,
    required this.processKey,
    required this.processVersion,
    required this.processName,
    this.firstTaskDefinitionKey,
    this.firstTaskName,
    this.firstTaskAreaId,
    this.firstTaskAreaName,
    this.formDefinition,
  });

  final String processId;
  final String processKey;
  final int processVersion;
  final String processName;
  final String? firstTaskDefinitionKey;
  final String? firstTaskName;
  final String? firstTaskAreaId;
  final String? firstTaskAreaName;
  final FormDefinition? formDefinition;

  factory ClientProcessStartPreview.fromJson(Map<String, dynamic> json) {
    return ClientProcessStartPreview(
      processId: (json['processId'] as String?) ?? '',
      processKey: (json['processKey'] as String?) ?? '',
      processVersion: (json['processVersion'] as num?)?.toInt() ?? 0,
      processName: (json['processName'] as String?) ?? '',
      firstTaskDefinitionKey: json['firstTaskDefinitionKey'] as String?,
      firstTaskName: json['firstTaskName'] as String?,
      firstTaskAreaId: json['firstTaskAreaId'] as String?,
      firstTaskAreaName: json['firstTaskAreaName'] as String?,
      formDefinition: json['formDefinition'] is Map<String, dynamic>
          ? FormDefinition.fromJson(Map<String, dynamic>.from(json['formDefinition'] as Map))
          : null,
    );
  }
}

class ClientProcessStartResult {
  const ClientProcessStartResult({
    required this.id,
    required this.clientUserId,
    required this.clientEmail,
    required this.processId,
    required this.processKey,
    required this.processVersion,
    required this.processName,
    required this.processInstanceId,
    required this.estado,
    required this.startedAt,
    this.message = '',
    this.finishedAt,
  });

  final String id;
  final String clientUserId;
  final String clientEmail;
  final String processId;
  final String processKey;
  final int processVersion;
  final String processName;
  final String processInstanceId;
  final String estado;
  final String startedAt;
  final String message;
  final String? finishedAt;

  factory ClientProcessStartResult.fromJson(Map<String, dynamic> json) {
    return ClientProcessStartResult(
      id: (json['id'] as String?) ?? '',
      clientUserId: (json['clientUserId'] as String?) ?? '',
      clientEmail: (json['clientEmail'] as String?) ?? '',
      processId: (json['processId'] as String?) ?? '',
      processKey: (json['processKey'] as String?) ?? '',
      processVersion: (json['processVersion'] as num?)?.toInt() ?? 0,
      processName: (json['processName'] as String?) ?? '',
      processInstanceId: (json['processInstanceId'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? '',
      startedAt: (json['startedAt'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      finishedAt: json['finishedAt'] as String?,
    );
  }
}

class ClientProcessInstanceItem {
  const ClientProcessInstanceItem({
    required this.id,
    required this.processName,
    required this.processKey,
    required this.processVersion,
    required this.processInstanceId,
    required this.estado,
    required this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String processName;
  final String processKey;
  final int processVersion;
  final String processInstanceId;
  final String estado;
  final String startedAt;
  final String? finishedAt;

  factory ClientProcessInstanceItem.fromJson(Map<String, dynamic> json) {
    return ClientProcessInstanceItem(
      id: (json['id'] as String?) ?? '',
      processName: (json['processName'] as String?) ?? '',
      processKey: (json['processKey'] as String?) ?? '',
      processVersion: (json['processVersion'] as num?)?.toInt() ?? 0,
      processInstanceId: (json['processInstanceId'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? '',
      startedAt: (json['startedAt'] as String?) ?? '',
      finishedAt: json['finishedAt'] as String?,
    );
  }
}
