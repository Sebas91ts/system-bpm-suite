import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/client_assistant_repository.dart';

class ClientAssistantScreen extends ConsumerStatefulWidget {
  const ClientAssistantScreen({super.key, required this.contextHint});

  final String contextHint;

  @override
  ConsumerState<ClientAssistantScreen> createState() => _ClientAssistantScreenState();
}

class _ClientAssistantScreenState extends ConsumerState<ClientAssistantScreen> {
  final _controller = TextEditingController();
  final List<_AssistantMessage> _messages = [
    const _AssistantMessage(
      role: 'assistant',
      text: 'Hola, soy tu asistente movil. Puedo ayudarte con tramites, seguimiento y tareas pendientes.',
    ),
  ];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) {
      return;
    }

    setState(() {
      _messages.add(_AssistantMessage(role: 'user', text: text));
      _controller.clear();
      _loading = true;
      _error = null;
    });

    try {
      final answer = await ref.read(clientAssistantRepositoryProvider).ask(
            message: text,
            contextHint: widget.contextHint,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(_AssistantMessage(
          role: 'assistant',
          text: answer.trim().isNotEmpty ? answer.trim() : 'No pude generar una respuesta en este momento.',
        ));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
                  Text(AppStrings.mobileAssistant(prefs.localeCode), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(AppStrings.assistantHint(prefs.localeCode), style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                  child: _Bubble(role: message.role, text: message.text),
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                ),
              ),
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
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu duda...',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 12),
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
  const _AssistantMessage({required this.role, required this.text});

  final String role;
  final String text;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.role, required this.text});

  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF123E60) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(text),
      ),
    );
  }
}
