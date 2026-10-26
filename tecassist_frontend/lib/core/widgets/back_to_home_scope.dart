import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackToHomeScope extends StatelessWidget {
  final Widget child;

  const BackToHomeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }

        context.go('/app/home');
      },

      child: child,
    );
  }
}
