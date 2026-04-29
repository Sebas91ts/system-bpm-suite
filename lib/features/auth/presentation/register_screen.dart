import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _isError = false;
    });

    try {
      await ref.read(authRepositoryProvider).register(
            nombre: _nombreController.text.trim(),
            apellido: _apellidoController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;
      setState(() {
        _message = 'Cuenta creada correctamente. Ya puedes iniciar sesion.';
        _isError = false;
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isError = true;
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
    final locale = prefs.localeCode;

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
                          'Registro',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF67E8F9),
                                letterSpacing: 3,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu cuenta',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registra tu acceso como cliente para usar la aplicacion movil.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          _messageBanner(context, _message!, _isError),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _apellidoController,
                          decoration: const InputDecoration(labelText: 'Apellido'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu apellido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
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
                            if (value.trim().length < 6) {
                              return 'La contrasena debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar contrasena',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Confirma tu contrasena';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contrasenas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        AppPrimaryButton(
                          label: 'Crear cuenta',
                          isLoading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading ? null : () => Navigator.of(context).pop(),
                          child: const Text('Ya tengo cuenta'),
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

  Widget _messageBanner(BuildContext context, String message, bool isError) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFF3B1D1D) : const Color(0xFF123524),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E)).withOpacity(0.35),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0),
        ),
      ),
    );
  }
}
