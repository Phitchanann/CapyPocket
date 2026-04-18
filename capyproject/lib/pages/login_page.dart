import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/root');
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter email/username and password.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final user = await FirebaseService.instance.signIn(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      if (user == null) {
        setState(() => _errorMessage = 'Sign in failed. Try again.');
        return;
      }

      final store = CapyScope.read(context);
      store.loginUser(user);
      if (rootTabNotifier.value != AppTab.home) {
        rootTabNotifier.value = AppTab.home;
      }
      Navigator.of(context).pushReplacementNamed('/root');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'No account found for this email or username.',
          'wrong-password' => 'Wrong password.',
          'invalid-credential' => 'Invalid email/username or password.',
          'invalid-email' => 'Invalid email or username.',
          'too-many-requests' => 'Too many attempts. Try again later.',
          _ => e.message ?? 'Authentication failed.',
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CapyPageFrame(
      showBottomBar: false,
      showFab: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: SizedBox(
              height: constraints.maxHeight - 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                    ),
                    label: Text('Back', style: theme.textTheme.bodyMedium),
                    style: TextButton.styleFrom(
                      foregroundColor: capyInkColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: WarmCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Center(
                                child: CapyBadge(size: 66, halo: true),
                              ),
                              const SizedBox(height: 16),
                              Text('Login', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text(
                                'Sign in with your email or username and password.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _identifierController,
                                decoration: const InputDecoration(
                                  labelText: 'Email or username',
                                ),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                onSubmitted: (_) => _login(),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: capyNegativeColor,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isSubmitting ? null : _login,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Login'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Column(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        final store = CapyScope.read(context);
                                        store.logout();
                                        if (rootTabNotifier.value !=
                                            AppTab.home) {
                                          rootTabNotifier.value = AppTab.home;
                                        }
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed('/root');
                                      },
                                      child: Text(
                                        'Continue as guest',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pushNamed('/create-account');
                                      },
                                      child: Text(
                                        'Create account instead?',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
