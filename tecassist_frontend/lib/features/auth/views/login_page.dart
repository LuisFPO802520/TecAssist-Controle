import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_background.dart';
import '../../../core/widgets/tecassist_brand.dart';

import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _senhaController = TextEditingController();

  bool _mostrarSenha = false;

  DateTime? _ultimoVoltar;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();

    super.dispose();
  }

  Future<void> _botaoVoltar() async {
    final agora = DateTime.now();

    if (_ultimoVoltar == null ||
        agora.difference(_ultimoVoltar!) > const Duration(seconds: 2)) {
      _ultimoVoltar = agora;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pressione voltar novamente para sair.'),
            duration: Duration(seconds: 2),
          ),
        );

      return;
    }

    await SystemNavigator.pop();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final sucesso = await auth.login(
      email: _emailController.text,
      senha: _senhaController.text,
    );

    if (!mounted) {
      return;
    }

    if (sucesso) {
      context.go('/app/home');
    }
  }

  void _esqueceuSenha() {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Esqueceu sua senha?'),

          content: const Text(
            'Solicite a redefinição da sua senha a um administrador.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: false,

      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }

        _botaoVoltar();
      },
      child: AuthBackground(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: EdgeInsets.fromLTRB(24, 45, 24, 35 + teclado),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  80,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),

                child: Column(
                  children: [
                    const TecAssistBrand(),

                    const SizedBox(height: 55),

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(26),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(22),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            const Text(
                              'Entrar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Acesse sua conta para continuar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),

                            const SizedBox(height: 28),

                            TextFormField(
                              controller: _emailController,

                              keyboardType: TextInputType.emailAddress,

                              decoration: const InputDecoration(
                                labelText: 'E-mail',

                                prefixIcon: Icon(Icons.email_outlined),
                              ),

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o e-mail.';
                                }

                                if (!value.contains('@')) {
                                  return 'Informe um e-mail válido.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _senhaController,

                              obscureText: !_mostrarSenha,

                              decoration: InputDecoration(
                                labelText: 'Senha',

                                prefixIcon: const Icon(Icons.lock_outline),

                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarSenha = !_mostrarSenha;
                                    });
                                  },

                                  icon: Icon(
                                    _mostrarSenha
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),

                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a senha.';
                                }

                                return null;
                              },
                            ),

                            Align(
                              alignment: Alignment.centerRight,

                              child: TextButton(
                                onPressed: _esqueceuSenha,

                                child: const Text('Esqueceu sua senha?'),
                              ),
                            ),

                            if (auth.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(11),

                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(
                                    alpha: 0.08,
                                  ),

                                  borderRadius: BorderRadius.circular(8),
                                ),

                                child: Text(
                                  auth.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),
                            ],

                            ElevatedButton(
                              onPressed: auth.isLoading ? null : _entrar,

                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 20),

                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('Ainda não possui conta?'),

                                TextButton(
                                  onPressed: () {
                                    context.go('/cadastro');
                                  },

                                  child: const Text('Cadastrar-se'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton.icon(
                      onPressed: () {
                        context.go('/');
                      },

                      icon: const Icon(Icons.arrow_back, color: Colors.white),

                      label: const Text(
                        'Voltar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
