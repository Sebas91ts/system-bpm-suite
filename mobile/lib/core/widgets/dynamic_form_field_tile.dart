import 'package:flutter/material.dart';

import '../models/form_models.dart';
import 'app_widgets.dart';

class DynamicFormFieldTile extends StatelessWidget {
  const DynamicFormFieldTile({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.onPickFile,
    this.onPickDate,
    this.errorText,
  });

  final FormFieldDefinition field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final Future<void> Function()? onPickFile;
  final Future<void> Function()? onPickDate;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case 'textarea':
        return _TextAreaField(
          field: field,
          value: value as String?,
          errorText: errorText,
          onChanged: onChanged,
        );
      case 'number':
        return _NumberField(field: field, value: value, errorText: errorText, onChanged: onChanged);
      case 'date':
        return _DateField(
          field: field,
          value: value as String?,
          errorText: errorText,
          onChanged: onChanged,
          onPickDate: onPickDate,
        );
      case 'select':
        return _SelectField(field: field, value: value as String?, errorText: errorText, onChanged: onChanged);
      case 'checkbox':
        return _CheckboxField(field: field, value: value == true, errorText: errorText, onChanged: onChanged);
      case 'checklist':
        return _ChecklistField(field: field, values: _asStringList(value), onChanged: onChanged);
      case 'file':
        return _FileField(field: field, value: value, errorText: errorText, onPickFile: onPickFile, onChanged: onChanged);
      default:
        return _TextField(field: field, value: value as String?, errorText: errorText, onChanged: onChanged);
    }
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const <String>[];
  }
}

class _BaseLabel extends StatelessWidget {
  const _BaseLabel({required this.field});

  final FormFieldDefinition field;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (field.required)
          const Text(
            '*',
            style: TextStyle(color: Color(0xFF67E8F9), fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

class _FieldWrapper extends StatelessWidget {
  const _FieldWrapper({
    required this.field,
    required this.child,
    this.errorText,
  });

  final FormFieldDefinition field;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BaseLabel(field: field),
          if ((field.helpText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(field.helpText!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          child,
          if (errorText != null && errorText!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(errorText!, style: const TextStyle(color: Color(0xFFFCA5A5))),
          ],
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final FormFieldDefinition field;
  final String? value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      field: field,
      errorText: errorText,
      child: TextFormField(
        initialValue: value ?? '',
        decoration: InputDecoration(
          hintText: field.placeholder,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _TextAreaField extends StatelessWidget {
  const _TextAreaField({
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final FormFieldDefinition field;
  final String? value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      field: field,
      errorText: errorText,
      child: TextFormField(
        initialValue: value ?? '',
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: field.placeholder,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final FormFieldDefinition field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      field: field,
      errorText: errorText,
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: field.placeholder,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.field,
    required this.value,
    required this.onChanged,
    this.onPickDate,
    this.errorText,
  });

  final FormFieldDefinition field;
  final String? value;
  final ValueChanged<dynamic> onChanged;
  final Future<void> Function()? onPickDate;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      field: field,
      errorText: errorText,
      child: GestureDetector(
        onTap: onPickDate,
        child: AbsorbPointer(
          child: TextFormField(
            initialValue: value ?? '',
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Selecciona una fecha',
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final FormFieldDefinition field;
  final String? value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final options = field.optionItems.isNotEmpty
        ? field.optionItems
        : field.options.map((item) => FormFieldOptionDefinition(label: item, value: item)).toList();

    return _FieldWrapper(
      field: field,
      errorText: errorText,
      child: DropdownButtonFormField<String>(
        value: options.any((option) => option.value == value) ? value : null,
        decoration: InputDecoration(
          hintText: field.placeholder,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              ),
            )
            .toList(),
        onChanged: (next) => onChanged(next ?? ''),
      ),
    );
  }
}

class _CheckboxField extends StatelessWidget {
  const _CheckboxField({
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final FormFieldDefinition field;
  final bool value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      field: field,
      errorText: errorText,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        onChanged: (next) => onChanged(next == true),
        title: Text(field.placeholder?.trim().isNotEmpty == true ? field.placeholder! : field.label),
      ),
    );
  }
}

class _ChecklistField extends StatelessWidget {
  const _ChecklistField({
    required this.field,
    required this.values,
    required this.onChanged,
  });

  final FormFieldDefinition field;
  final List<String> values;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = field.optionItems.isNotEmpty
        ? field.optionItems
        : field.options.map((item) => FormFieldOptionDefinition(label: item, value: item)).toList();

    return _FieldWrapper(
      field: field,
      child: Column(
        children: options
            .map(
              (option) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: values.contains(option.value),
                onChanged: (checked) {
                  final next = [...values];
                  if (checked == true) {
                    if (!next.contains(option.value)) {
                      next.add(option.value);
                    }
                  } else {
                    next.remove(option.value);
                  }
                  onChanged(next);
                },
                title: Text(option.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FileField extends StatelessWidget {
  const _FileField({
    required this.field,
    required this.value,
    required this.onChanged,
    this.onPickFile,
    this.errorText,
  });

  final FormFieldDefinition field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final Future<void> Function()? onPickFile;
  final String? errorText;

  String _fileLabel() {
    if (value is PendingFileSelection) {
      return value.fileName;
    }
    if (value is UploadedFileMetadata) {
      return value.fileName;
    }
    if (value is String && (value as String).trim().isNotEmpty) {
      return value as String;
    }
    return 'Ningun archivo seleccionado';
  }

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      field: field,
      errorText: errorText,
      child: Row(
        children: [
          Expanded(child: Text(_fileLabel())),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () async {
              await onPickFile?.call();
            },
            child: const Text('Seleccionar'),
          ),
        ],
      ),
    );
  }
}
