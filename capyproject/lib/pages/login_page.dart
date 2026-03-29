import 'package:flutter/material.dart';

import 'ui_kit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CapyPageFrame(
      showBottomBar: false,
      showFab: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthCard(
              title: 'Login',
              subtitle: 'Jump back into your pockets.',
              buttonLabel: 'Login',
              fields: ['Username', 'Password'],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Create account instead?',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
