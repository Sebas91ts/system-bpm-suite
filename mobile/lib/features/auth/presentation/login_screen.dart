import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import 'register_screen.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.forceMessage});

  final String? forceMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final locale = prefs.localeCode;
    final authState = ref.watch(authControllerProvider).state;
    final controller = ref.read(authControllerProvider.notifier);
    final errorMessage = widget.forceMessage ?? authState.errorMessage;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050B14), Color(0xFF07192C), Color(0xFF050B14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.loginTitle(locale),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF67E8F9),
                                letterSpacing: 3,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.loginSubtitle(locale),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.loginDescription(locale),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (errorMessage != null && errorMessage.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: errorMessage),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: AppStrings.emailLabel(locale),
                            hintText: AppStrings.emailHint(locale),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.enterEmail(locale);
                            }
                            if (!value.contains('@')) {
                              return AppStrings.validEmail(locale);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: AppStrings.passwordLabel(locale),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.enterPassword(locale);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        AppPrimaryButton(
                          label: AppStrings.enter(locale),
                          isLoading: authState.loading,
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            controller.clearError();
                            await controller.login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: authState.loading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text('Crear cuenta'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.onlyClients(locale),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B1D1D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFCA5A5)),
      ),
    );
  }
}
