class FormFieldOptionDefinition {
  const FormFieldOptionDefinition({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  factory FormFieldOptionDefinition.fromJson(Map<String, dynamic> json) {
    return FormFieldOptionDefinition(
      label: (json['label'] as String?) ?? '',
      value: (json['value'] as String?) ?? '',
    );
  }
}

class UploadedFileMetadata {
  const UploadedFileMetadata({
    required this.publicId,
    required this.fileName,
    required this.secureUrl,
    this.mimeType,
    this.size,
    this.resourceType,
  });

  final String publicId;
  final String fileName;
  final String secureUrl;
  final String? mimeType;
  final int? size;
  final String? resourceType;

  factory UploadedFileMetadata.fromJson(Map<String, dynamic> json) {
    return UploadedFileMetadata(
      publicId: (json['publicId'] as String?) ?? '',
      fileName: (json['fileName'] as String?) ?? '',
      secureUrl: (json['secureUrl'] as String?) ?? '',
      mimeType: json['mimeType'] as String?,
      size: (json['size'] as num?)?.toInt(),
      resourceType: json['resourceType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'fileName': fileName,
      'secureUrl': secureUrl,
      'mimeType': mimeType,
      'size': size,
      'resourceType': resourceType,
    };
  }
}

class PendingFileSelection {
  const PendingFileSelection({
    required this.fileName,
    required this.bytes,
    this.mimeType,
  });

  final String fileName;
  final List<int> bytes;
  final String? mimeType;
}

class FormFieldDefinition {
  const FormFieldDefinition({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    required this.order,
    this.placeholder,
    this.helpText,
    this.options = const [],
    this.optionItems = const [],
  });

  final String name;
  final String label;
  final String type;
  final bool required;
  final String? placeholder;
  final String? helpText;
  final int order;
  final List<String> options;
  final List<FormFieldOptionDefinition> optionItems;

  factory FormFieldDefinition.fromJson(Map<String, dynamic> json) {
    return FormFieldDefinition(
      name: (json['name'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'text',
      required: json['required'] == true,
      placeholder: json['placeholder'] as String?,
      helpText: json['helpText'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      options: _asStringList(json['options']),
      optionItems: _asOptionList(json['optionItems']),
    );
  }
}

class FormDefinition {
  const FormDefinition({
    required this.id,
    required this.processKey,
    required this.processVersion,
    required this.taskDefinitionKey,
    required this.title,
    required this.fields,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String processKey;
  final int processVersion;
  final String taskDefinitionKey;
  final String title;
  final List<FormFieldDefinition> fields;
  final bool active;
  final String? createdAt;
  final String? updatedAt;

  List<FormFieldDefinition> get sortedFields {
    final sorted = [...fields];
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  factory FormDefinition.fromJson(Map<String, dynamic> json) {
    return FormDefinition(
      id: (json['id'] as String?) ?? '',
      processKey: (json['processKey'] as String?) ?? '',
      processVersion: (json['processVersion'] as num?)?.toInt() ?? 0,
      taskDefinitionKey: (json['taskDefinitionKey'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      fields: _asFieldList(json['fields']),
      active: json['active'] == true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }

  return const <String>[];
}

List<FormFieldDefinition> _asFieldList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => FormFieldDefinition.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  return const <FormFieldDefinition>[];
}

List<FormFieldOptionDefinition> _asOptionList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => FormFieldOptionDefinition.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  return const <FormFieldOptionDefinition>[];
}
