import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/usuario_provider.dart';

class UsuarioFormPage extends StatefulWidget {
  final int? usuarioId;

  const UsuarioFormPage({super.key, this.usuarioId});

  bool get editando => usuarioId != null;

  @override
  State<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends State<UsuarioFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();

  final _emailController = TextEditingController();

  final _telefoneController = TextEditingController();

  final _senhaController = TextEditingController();

  String _tipo = 'FUNCIONARIO';

  bool _mostrarSenha = false;
  bool _carregandoInicial = false;

  @override
  void initState() {
    super.initState();

    if (widget.editando) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarUsuario();
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();

    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    setState(() {
      _carregandoInicial = true;
    });

    final provider = context.read<UsuarioProvider>();

    final usuario = await provider.buscarUsuario(widget.usuarioId!);

    if (!mounted) {
      return;
    }

    if (usuario == null) {
      setState(() {
        _carregandoInicial = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Usuário não encontrado.'),
          backgroundColor: AppColors.error,
        ),
      );

      return;
    }

    _nomeController.text = usuario.nome;

    _emailController.text = usuario.email;

    _telefoneController.text = usuario.telefone ?? '';

    _tipo = usuario.tipo;

    setState(() {
      _carregandoInicial = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<UsuarioProvider>();

    final telefone = _telefoneController.text.trim();

    bool sucesso;

    if (widget.editando) {
      sucesso = await provider.atualizarUsuario(
        id: widget.usuarioId!,
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        tipo: _tipo,
        telefone: telefone,
        senha: _senhaController.text,
      );
    } else {
      sucesso = await provider.criarUsuario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        tipo: _tipo,
        telefone: telefone,
      );
    }

    if (!mounted) {
      return;
    }

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editando
                ? 'Usuário atualizado com sucesso.'
                : 'Usuário cadastrado com sucesso.',
          ),
        ),
      );

      context.go('/usuarios');

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Erro ao salvar usuário.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.go('/usuarios');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.editando ? 'Editar usuário' : 'Novo usuário'),
      ),

      body: _carregandoInicial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.editando
                                ? 'Dados do usuário'
                                : 'Cadastrar usuário',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            widget.editando
                                ? 'Altere os dados necessários.'
                                : 'Informe os dados do novo usuário.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _nomeController,
                            textCapitalization: TextCapitalization.words,
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

                          const SizedBox(height: 16),

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

                              final email = value.trim();

                              if (!email.contains('@')) {
                                return 'Informe um e-mail válido.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _telefoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 11,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Telefone (opcional)',
                              prefixIcon: Icon(Icons.phone_outlined),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }

                              if (value.length < 10 || value.length > 11) {
                                return 'Informe um telefone com 10 ou 11 dígitos.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: _tipo,
                            decoration: const InputDecoration(
                              labelText: 'Perfil',
                              prefixIcon: Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'FUNCIONARIO',
                                child: Text('Funcionário'),
                              ),
                              DropdownMenuItem(
                                value: 'ADMIN',
                                child: Text('Administrador'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _tipo = value;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _senhaController,
                            obscureText: !_mostrarSenha,
                            decoration: InputDecoration(
                              labelText: widget.editando
                                  ? 'Nova senha (opcional)'
                                  : 'Senha',
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
                              if (!widget.editando &&
                                  (value == null || value.isEmpty)) {
                                return 'Informe a senha.';
                              }

                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 6) {
                                return 'A senha deve ter pelo menos 6 caracteres.';
                              }

                              return null;
                            },
                          ),

                          if (widget.editando) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Deixe a senha em branco para manter a senha atual.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          ElevatedButton.icon(
                            onPressed: provider.isSaving ? null : _salvar,
                            icon: provider.isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              provider.isSaving ? 'Salvando...' : 'Salvar',
                            ),
                          ),

                          const SizedBox(height: 10),

                          OutlinedButton(
                            onPressed: provider.isSaving
                                ? null
                                : () {
                                    context.go('/usuarios');
                                  },
                            child: const Text('Cancelar'),
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
