import 'form_models.dart';

class ClientTrackingHistoryItem {
  const ClientTrackingHistoryItem({
    this.taskName,
    this.areaName,
    this.completedAt,
    this.formData,
  });

  final String? taskName;
  final String? areaName;
  final String? completedAt;
  final Map<String, dynamic>? formData;

  factory ClientTrackingHistoryItem.fromJson(Map<String, dynamic> json) {
    return ClientTrackingHistoryItem(
      taskName: json['taskName'] as String?,
      areaName: json['areaName'] as String?,
      completedAt: json['completedAt'] as String?,
      formData: json['formData'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['formData'] as Map)
          : null,
    );
  }
}

class ClientInstanceTracking {
  const ClientInstanceTracking({
    this.processName,
    this.estado,
    this.startedAt,
    this.progressPercentage,
    this.currentTaskName,
    this.currentAreaName,
    required this.history,
    this.xmlBpmn,
    required this.completedTaskKeys,
    required this.activeTaskKeys,
    required this.pendingTaskKeys,
  });

  final String? processName;
  final String? estado;
  final String? startedAt;
  final int? progressPercentage;
  final String? currentTaskName;
  final String? currentAreaName;
  final List<ClientTrackingHistoryItem> history;
  final String? xmlBpmn;
  final List<String> completedTaskKeys;
  final List<String> activeTaskKeys;
  final List<String> pendingTaskKeys;

  factory ClientInstanceTracking.fromJson(Map<String, dynamic> json) {
    return ClientInstanceTracking(
      processName: json['processName'] as String?,
      estado: json['estado'] as String?,
      startedAt: json['startedAt'] as String?,
      progressPercentage: (json['progressPercentage'] as num?)?.toInt(),
      currentTaskName: json['currentTaskName'] as String?,
      currentAreaName: json['currentAreaName'] as String?,
      history: _historyList(json['history']),
      xmlBpmn: json['xmlBpmn'] as String?,
      completedTaskKeys: _stringList(json['completedTaskKeys']),
      activeTaskKeys: _stringList(json['activeTaskKeys']),
      pendingTaskKeys: _stringList(json['pendingTaskKeys']),
    );
  }
}

List<ClientTrackingHistoryItem> _historyList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => ClientTrackingHistoryItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
  return const <ClientTrackingHistoryItem>[];
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const <String>[];
}
