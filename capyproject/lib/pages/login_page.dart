import 'package:flutter/material.dart';

import '../data/capy_database.dart';
import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final Future<List<CapyUser>> _usersFuture;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usersFuture = CapyDatabase.instance.fetchUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter username and password.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final database = CapyDatabase.instance;
      final existingUser = await database.fetchUserByUsername(username);
      if (existingUser == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = 'No account found. Create one first.';
        });
        return;
      }

      final authenticatedUser = await database.authenticateUser(
        username: username,
        password: password,
      );
      if (authenticatedUser == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = 'Wrong password for this account.';
        });
        return;
      }

      if (!mounted) {
        return;
      }

      final store = CapyScope.read(context);
      store.loginUser(authenticatedUser);
      if (rootTabNotifier.value != AppTab.home) {
        rootTabNotifier.value = AppTab.home;
      }
      Navigator.of(context).pushReplacementNamed('/root');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CapyPageFrame(
      showBottomBar: false,
      showFab: false,
      child: FutureBuilder<List<CapyUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          final users = snapshot.data ?? const <CapyUser>[];
          final hasAccounts = users.isNotEmpty;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: WarmCard(
                child: Column(
                  children: [
                    const Center(child: CapyBadge(size: 66, halo: true)),
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Loading accounts...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasAccounts)
                  EmptyStateCard(
                    title: 'No account yet',
                    subtitle:
                        'Create one first, then log in with username and password.',
                    actionLabel: 'Create account',
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed('/create-account');
                    },
                  )
                else
                  WarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: CapyBadge(size: 66, halo: true)),
                        const SizedBox(height: 16),
                        Text('Login', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Use your username and password to enter your wallet.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
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
                      ],
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
                          if (rootTabNotifier.value != AppTab.home) {
                            rootTabNotifier.value = AppTab.home;
                          }
                          Navigator.of(context).pushReplacementNamed('/root');
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
                          ).pushReplacementNamed('/create-account');
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
          );
        },
      ),
    );
  }
}
