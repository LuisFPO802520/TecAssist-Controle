import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/usuario_provider.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../../core/widgets/blue_pattern_background.dart';
import '../../../core/widgets/user_avatar.dart';

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

  final _imagePicker = ImagePicker();
  Uint8List? _fotoBytes;
  XFile? _fotoSelecionada;
  String? _fotoPerfilAtual;

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

    _fotoPerfilAtual = usuario.fotoPerfil;

    setState(() {
      _carregandoInicial = false;
    });
  }

  Future<void> _selecionarFoto() async {
    try {
      final arquivo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (arquivo == null) return;

      final bytes = await arquivo.readAsBytes();

      if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escolha uma imagem válida de até 4 MB.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _fotoBytes = bytes;
        _fotoSelecionada = arquivo;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível selecionar a foto.')),
      );
    }
  }

  String _tipoMimeFoto() {
    final mime = _fotoSelecionada?.mimeType?.toLowerCase();

    if (mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp') {
      return mime!;
    }

    final nome = _fotoSelecionada?.name.toLowerCase() ?? '';
    if (nome.endsWith('.png')) return 'image/png';
    if (nome.endsWith('.webp')) return 'image/webp';

    return 'image/jpeg';
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
        fotoBase64: _fotoBytes != null ? base64Encode(_fotoBytes!) : null,
        fotoMimeType: _fotoBytes != null ? _tipoMimeFoto() : null,
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

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/usuarios');
      }

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

    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          toolbarHeight: 85,
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,

          flexibleSpace: BluePatternBackground(
            showTopCircles: true,
            showBottomCircles: false,
            compactTopCircles: true,
            child: const SizedBox.expand(),
          ),

          leading: Transform.translate(
            offset: const Offset(0, 18),
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/usuarios');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          title: Transform.translate(
            offset: const Offset(0, 18),
            child: Text(
              widget.editando ? 'Editar usuário' : 'Novo usuário',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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

                            if (widget.editando) ...[
                              Center(
                                child: Column(
                                  children: [
                                    UserAvatar(
                                      size: 104,
                                      fotoPerfil: _fotoPerfilAtual,
                                      previewBytes: _fotoBytes,
                                      iconSize: 74,
                                      borderWidth: 2,
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _selecionarFoto,
                                      icon: const Icon(
                                        Icons.photo_camera_outlined,
                                      ),
                                      label: const Text(
                                        'Alterar foto de perfil',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'JPG, PNG ou WebP • até 4 MB',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

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
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/usuarios');
                                      }
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
        bottomNavigationBar: const AppBottomNavigation(),
      ),
    );
  }
}
