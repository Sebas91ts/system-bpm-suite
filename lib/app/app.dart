import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_widgets.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/client_shell.dart';
import 'theme/app_theme.dart';

class SystemMovileApp extends ConsumerWidget {
  const SystemMovileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).state;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema Clientes',
      theme: AppTheme.dark(),
      home: _AuthGate(authState: authState),
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate({required this.authState});

  final AuthState authState;

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = widget.authState;

    if (authState.bootstrapping) {
      return const Scaffold(
        body: LoadingView(label: 'Preparando tu sesion...'),
      );
    }

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    if (!authState.user!.isClient) {
      return const LoginScreen(forceMessage: 'Esta aplicacion es solo para clientes.');
    }

    return const ClientShell();
  }
}
