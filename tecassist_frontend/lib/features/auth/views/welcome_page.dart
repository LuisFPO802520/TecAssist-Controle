import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/blue_pattern_background.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SizedBox.expand(
          child: BluePatternBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  children: [
                    const Spacer(flex: 4),

                    SizedBox(
                      width: 280,
                      height: 210,
                      child: Image.asset(
                        'assets/images/tecassist_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'TecAssist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(flex: 2),

                    _WelcomeButton(
                      texto: 'Entrar',
                      onPressed: () {
                        context.go('/login');
                      },
                    ),

                    const SizedBox(height: 20),

                    _WelcomeButton(
                      texto: 'Cadastrar-se',
                      onPressed: () {
                        context.go('/cadastro');
                      },
                    ),

                    const SizedBox(height: 14),

                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Ao continuar, você aceita o nosso\n',
                          ),

                          const TextSpan(
                            text: 'Contrato do Usuário',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),

                          const TextSpan(text: ', a '),

                          const TextSpan(
                            text: 'Política de\nPrivacidade',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),

                          const TextSpan(text: ' do TecAssist.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const _WelcomeButton({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
