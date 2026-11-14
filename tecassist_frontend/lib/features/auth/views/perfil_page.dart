import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../../core/widgets/blue_pattern_background.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/auth_provider.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final _imagePicker = ImagePicker();

  Uint8List? _fotoBytes;
  XFile? _fotoSelecionada;

  bool _mostrarSenhaAtual = false;
  bool _mostrarNovaSenha = false;
  bool _mostrarConfirmacao = false;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();

    _preencherCampos(context.read<AuthProvider>().usuario);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarPerfilAtualizado();
    });
  }

  void _preencherCampos(dynamic usuario) {
    if (usuario == null) return;

    _nomeController.text = usuario.nome ?? '';
    _emailController.text = usuario.email ?? '';
    _telefoneController.text = usuario.telefone ?? '';
  }

  Future<void> _carregarPerfilAtualizado() async {
    final auth = context.read<AuthProvider>();
    final sucesso = await auth.recarregarPerfil();

    if (!mounted) return;

    if (sucesso) {
      _preencherCampos(auth.usuario);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _carregandoPerfil = false;
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarFoto() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar uma foto'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    if (origem == null || !mounted) return;

    try {
      final arquivo = await _imagePicker.pickImage(
        source: origem,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (arquivo == null) return;

      final bytes = await arquivo.readAsBytes();

      if (bytes.isEmpty) {
        _mostrarMensagem('Não foi possível ler a imagem selecionada.');
        return;
      }

      // O backend aceita imagens de até 4 MB.
      if (bytes.length > 4 * 1024 * 1024) {
        _mostrarMensagem('A imagem ficou maior que 4 MB. Escolha outra foto.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _fotoSelecionada = arquivo;
        _fotoBytes = bytes;
      });
    } catch (_) {
      _mostrarMensagem('Não foi possível selecionar a foto.');
    }
  }

  String _tipoMime(XFile arquivo) {
    final mime = arquivo.mimeType?.toLowerCase();

    if (mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp') {
      return mime!;
    }

    final nome = arquivo.name.toLowerCase();

    if (nome.endsWith('.png')) return 'image/png';
    if (nome.endsWith('.webp')) return 'image/webp';

    return 'image/jpeg';
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail.';
    }

    final email = value.trim();
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!regex.hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  String? _validarTelefone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final telefone = value.trim();

    if (telefone.length < 10 || telefone.length > 11) {
      return 'Informe um telefone com 10 ou 11 dígitos.';
    }

    return null;
  }

  String? _validarNovaSenha(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length < 6) {
      return 'A nova senha deve ter pelo menos 6 caracteres.';
    }

    if (_senhaAtualController.text.isEmpty) {
      return 'Informe sua senha atual.';
    }

    return null;
  }

  String? _validarConfirmacao(String? value) {
    if (_novaSenhaController.text.isEmpty) {
      return null;
    }

    if (value != _novaSenhaController.text) {
      return 'As senhas não coincidem.';
    }

    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final senhaNova = _novaSenhaController.text;

    final sucesso = await auth.atualizarPerfil(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      telefone: _telefoneController.text.trim(),
      senhaAtual: senhaNova.isNotEmpty ? _senhaAtualController.text : null,
      novaSenha: senhaNova.isNotEmpty ? senhaNova : null,
      fotoBase64: _fotoBytes != null ? base64Encode(_fotoBytes!) : null,
      fotoMimeType: _fotoSelecionada != null
          ? _tipoMime(_fotoSelecionada!)
          : null,
    );

    if (!mounted) return;

    if (sucesso) {
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();

      setState(() {
        _fotoBytes = null;
        _fotoSelecionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informações atualizadas com sucesso.')),
      );

      return;
    }

    _mostrarMensagem(
      auth.errorMessage ?? 'Não foi possível salvar as informações.',
      erro: true,
    );
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: erro ? AppColors.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    final tipoUsuario = usuario?.tipo == 'ADMIN'
        ? 'Administrador'
        : 'Funcionário';

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
                  context.go('/app/home');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          title: Transform.translate(
            offset: const Offset(0, 18),
            child: const Text(
              'Editar informações',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
        body: _carregandoPerfil
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
                            const Text(
                              'Meu perfil',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Atualize seus dados e sua foto de perfil.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),

                            Center(
                              child: Column(
                                children: [
                                  UserAvatar(
                                    size: 116,
                                    fotoPerfil: usuario?.fotoPerfil,
                                    previewBytes: _fotoBytes,
                                    iconSize: 82,
                                    borderWidth: 2,
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: auth.isSavingProfile
                                        ? null
                                        : _selecionarFoto,
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                    ),
                                    label: const Text('Alterar foto de perfil'),
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
                            TextFormField(
                              controller: _nomeController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe seu nome.';
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
                              validator: _validarEmail,
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
                              validator: _validarTelefone,
                            ),
                            const SizedBox(height: 16),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Perfil de acesso',
                                prefixIcon: Icon(
                                  Icons.admin_panel_settings_outlined,
                                ),
                              ),
                              child: Text(
                                tipoUsuario,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),
                            const Text(
                              'Alterar senha',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Deixe os campos em branco para manter sua senha atual.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _senhaAtualController,
                              obscureText: !_mostrarSenhaAtual,
                              decoration: InputDecoration(
                                labelText: 'Senha atual',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarSenhaAtual = !_mostrarSenhaAtual;
                                    });
                                  },
                                  icon: Icon(
                                    _mostrarSenhaAtual
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _novaSenhaController,
                              obscureText: !_mostrarNovaSenha,
                              decoration: InputDecoration(
                                labelText: 'Nova senha',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_outlined,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarNovaSenha = !_mostrarNovaSenha;
                                    });
                                  },
                                  icon: Icon(
                                    _mostrarNovaSenha
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: _validarNovaSenha,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmarSenhaController,
                              obscureText: !_mostrarConfirmacao,
                              decoration: InputDecoration(
                                labelText: 'Confirmar nova senha',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarConfirmacao =
                                          !_mostrarConfirmacao;
                                    });
                                  },
                                  icon: Icon(
                                    _mostrarConfirmacao
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: _validarConfirmacao,
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: auth.isSavingProfile ? null : _salvar,
                              icon: auth.isSavingProfile
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
                                auth.isSavingProfile
                                    ? 'Salvando...'
                                    : 'Salvar alterações',
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: auth.isSavingProfile
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/app/home');
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
      ),
    );
  }
}
