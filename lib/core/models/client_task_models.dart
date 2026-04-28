import 'form_models.dart';

class ClientTaskListItem {
  const ClientTaskListItem({
    required this.taskId,
    required this.taskName,
    required this.processInstanceId,
    required this.processKey,
    required this.processVersion,
    required this.processName,
    this.areaName,
    this.assignee,
    required this.assignedToClient,
    this.formDefinition,
  });

  final String taskId;
  final String taskName;
  final String processInstanceId;
  final String processKey;
  final int processVersion;
  final String processName;
  final String? areaName;
  final String? assignee;
  final bool assignedToClient;
  final FormDefinition? formDefinition;

  factory ClientTaskListItem.fromJson(Map<String, dynamic> json) {
    return ClientTaskListItem(
      taskId: (json['taskId'] as String?) ?? '',
      taskName: (json['taskName'] as String?) ?? '',
      processInstanceId: (json['processInstanceId'] as String?) ?? '',
      processKey: (json['processKey'] as String?) ?? '',
      processVersion: (json['processVersion'] as num?)?.toInt() ?? 0,
      processName: (json['processName'] as String?) ?? '',
      areaName: json['areaName'] as String?,
      assignee: json['assignee'] as String?,
      assignedToClient: json['assignedToClient'] == true,
      formDefinition: json['formDefinition'] is Map<String, dynamic>
          ? FormDefinition.fromJson(Map<String, dynamic>.from(json['formDefinition'] as Map))
          : null,
    );
  }
}

class ClientTaskFormResponse {
  const ClientTaskFormResponse({
    required this.taskId,
    required this.taskName,
    required this.processInstanceId,
    required this.processKey,
    required this.processVersion,
    required this.processName,
    this.areaName,
    this.assignee,
    this.formDefinition,
    required this.currentValues,
  });

  final String taskId;
  final String taskName;
  final String processInstanceId;
  final String processKey;
  final int processVersion;
  final String processName;
  final String? areaName;
  final String? assignee;
  final FormDefinition? formDefinition;
  final Map<String, dynamic> currentValues;

  factory ClientTaskFormResponse.fromJson(Map<String, dynamic> json) {
    return ClientTaskFormResponse(
      taskId: (json['taskId'] as String?) ?? '',
      taskName: (json['taskName'] as String?) ?? '',
      processInstanceId: (json['processInstanceId'] as String?) ?? '',
      processKey: (json['processKey'] as String?) ?? '',
      processVersion: (json['processVersion'] as num?)?.toInt() ?? 0,
      processName: (json['processName'] as String?) ?? '',
      areaName: json['areaName'] as String?,
      assignee: json['assignee'] as String?,
      formDefinition: json['formDefinition'] is Map<String, dynamic>
          ? FormDefinition.fromJson(Map<String, dynamic>.from(json['formDefinition'] as Map))
          : null,
      currentValues: Map<String, dynamic>.from(json['currentValues'] as Map? ?? const {}),
    );
  }
}

class ClientTaskCompleteResponse {
  const ClientTaskCompleteResponse({
    required this.taskId,
    required this.processInstanceId,
    required this.processName,
    required this.completedBy,
    required this.completedAt,
    required this.message,
  });

  final String taskId;
  final String processInstanceId;
  final String processName;
  final String completedBy;
  final String completedAt;
  final String message;

  factory ClientTaskCompleteResponse.fromJson(Map<String, dynamic> json) {
    return ClientTaskCompleteResponse(
      taskId: (json['taskId'] as String?) ?? '',
      processInstanceId: (json['processInstanceId'] as String?) ?? '',
      processName: (json['processName'] as String?) ?? '',
      completedBy: (json['completedBy'] as String?) ?? '',
      completedAt: (json['completedAt'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
    );
  }
}
