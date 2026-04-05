import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/adaptive_glass_card.dart';
import '../../../core/widgets/adaptive_glass_pill_button.dart';
import '../data/auth_service.dart';
import '../providers/auth_state_provider.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _submitting = false;
  String? _lastError;

  Future<void> _showErrorDetails(String title, Object error) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: AdaptiveGlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            glassAlpha: 0.18,
            borderAlpha: 0.34,
            tintColor: colors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: SelectableText('${error.runtimeType}: $error'),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AdaptiveGlassPillButton(
                    label: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _lastError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      switch (_mode) {
        case _AuthMode.signIn:
          await authService.signInWithPassword(
            email: email,
            password: password,
          );
        case _AuthMode.signUp:
          await authService.signUpWithPassword(
            email: email,
            password: password,
          );
      }

      if (!mounted) {
        return;
      }

      final session = ref.read(currentSessionProvider);
      if (session == null && _mode == _AuthMode.signUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email, then sign in.')),
        );
        return;
      }

      widget.onAuthenticated();
    } on AuthException catch (error) {
      final message = '${error.runtimeType}: ${error.message}';
      debugPrint('ZAIRN_AUTH_ERROR $message');
      if (!mounted) {
        return;
      }
      setState(() => _lastError = message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      await _showErrorDetails(
        _mode == _AuthMode.signUp ? 'Create account failed' : 'Sign in failed',
        error,
      );
    } catch (error, stackTrace) {
      final message = '${error.runtimeType}: $error';
      debugPrint('ZAIRN_AUTH_ERROR $message');
      debugPrint('Auth submit failed (${error.runtimeType}): $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _lastError = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _AuthMode.signUp
                ? 'Create account failed (${error.runtimeType}): $error'
                : 'Sign in failed (${error.runtimeType}): $error',
          ),
        ),
      );
      await _showErrorDetails(
        _mode == _AuthMode.signUp ? 'Create account failed' : 'Sign in failed',
        error,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentSession = ref.watch(currentSessionProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Text(
                  'Zairn Core',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start with email auth and the core mobile shell. This keeps the Flutter port focused on the platform basics first.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SegmentedButton<_AuthMode>(
                  segments: const [
                    ButtonSegment<_AuthMode>(
                      value: _AuthMode.signIn,
                      label: Text('Sign in'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment<_AuthMode>(
                      value: _AuthMode.signUp,
                      label: Text('Create account'),
                      icon: Icon(Icons.person_add_alt_1),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
                const SizedBox(height: 20),
                AdaptiveGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@example.com',
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 8 characters',
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.length < 8) {
                              return 'Use at least 8 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AdaptiveGlassPillButton(
                          onPressed: _submitting ? null : _submit,
                          icon: Icon(
                            _mode == _AuthMode.signIn
                                ? Icons.login
                                : Icons.person_add_alt_1,
                          ),
                          label: _submitting
                              ? 'Working...'
                              : _mode == _AuthMode.signIn
                              ? 'Sign in'
                              : 'Create account',
                          compact: false,
                          expanded: true,
                          tintColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                        ),
                        if (_lastError != null) ...[
                          const SizedBox(height: 16),
                          AdaptiveGlassCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(12),
                            glassAlpha: 0.24,
                            borderAlpha: 0.36,
                            tintColor: colors.errorContainer,
                            borderColor: colors.error,
                            child: Text(
                              _lastError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (currentSession != null) ...[
                          const SizedBox(height: 12),
                          AdaptiveGlassPillButton(
                            onPressed: widget.onAuthenticated,
                            icon: const Icon(Icons.arrow_forward),
                            label:
                                'Continue with current session (${currentSession.user.email ?? 'signed-in'})',
                            compact: false,
                            expanded: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
