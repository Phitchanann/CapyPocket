import 'package:flutter/material.dart';

import 'ui_kit.dart';

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CapyPageFrame(
      showBottomBar: false,
      showFab: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: AuthCard(
          title: 'Create account',
          subtitle: 'Set up your calm little pocket home.',
          buttonLabel: 'Create',
          fields: ['Username', 'Email', 'Password'],
        ),
      ),
    );
  }
}
