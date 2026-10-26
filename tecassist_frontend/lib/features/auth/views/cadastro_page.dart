import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_background.dart';
import '../../../core/widgets/tecassist_brand.dart';

import '../providers/auth_provider.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();

  final _emailController = TextEditingController();

  final _telefoneController = TextEditingController();

  final _senhaController = TextEditingController();

  final _confirmarSenhaController = TextEditingController();

  final _codigoController = TextEditingController();

  bool _mostrarSenha = false;

  DateTime? _ultimoVoltar;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _codigoController.dispose();

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

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final sucesso = await auth.cadastrarFuncionario(
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      senha: _senhaController.text,
      codigoCadastro: _codigoController.text,
    );

    if (!mounted) {
      return;
    }

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastro realizado com sucesso. Faça login para continuar.',
          ),
        ),
      );

      context.go('/login');
    }
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
        child: AuthBackground(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

            padding: EdgeInsets.fromLTRB(24, 35, 24, 35 + teclado),

            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),

                child: Column(
                  children: [
                    const TecAssistBrand(),

                    const SizedBox(height: 35),

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(26),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(22),
                      ),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            const Text(
                              'Criar conta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Cadastro destinado aos funcionários da assistência técnica.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),

                            const SizedBox(height: 25),

                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

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

                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _telefoneController,

                              keyboardType: TextInputType.phone,

                              maxLength: 11,

                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],

                              decoration: const InputDecoration(
                                labelText: 'Telefone (opcional)',
                                counterText: '',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),

                            const SizedBox(height: 14),

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
                                if (value == null || value.length < 6) {
                                  return 'A senha deve possuir pelo menos 6 caracteres.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _confirmarSenhaController,

                              obscureText: !_mostrarSenha,

                              decoration: const InputDecoration(
                                labelText: 'Confirmar senha',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),

                              validator: (value) {
                                if (value != _senhaController.text) {
                                  return 'As senhas não são iguais.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _codigoController,

                              decoration: const InputDecoration(
                                labelText: 'Código de cadastro',

                                prefixIcon: Icon(Icons.vpn_key_outlined),

                                helperText:
                                    'Solicite o código ao responsável pela assistência técnica.',
                              ),

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o código de cadastro.';
                                }

                                return null;
                              },
                            ),

                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 15),

                              Text(
                                auth.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ],

                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: auth.isLoading ? null : _cadastrar,

                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Cadastrar-se'),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Já possui conta?'),

                                TextButton(
                                  onPressed: () {
                                    context.go('/login');
                                  },
                                  child: const Text('Entrar'),
                                ),
                              ],
                            ),
                          ],
                        ),
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
