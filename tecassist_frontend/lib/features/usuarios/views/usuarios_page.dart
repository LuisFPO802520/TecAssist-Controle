import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/usuario_model.dart';
import '../providers/usuario_provider.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final TextEditingController _pesquisaController = TextEditingController();

  String _pesquisa = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().carregarUsuarios();
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();

    super.dispose();
  }

  Future<void> _excluir(UsuarioModel usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir usuário'),
          content: Text(
            'Deseja realmente excluir o usuário "${usuario.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    final provider = context.read<UsuarioProvider>();

    final sucesso = await provider.excluirUsuario(usuario.id);

    if (!mounted) {
      return;
    }

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário excluído com sucesso.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao excluir usuário.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsuarioProvider>();

    final usuarios = provider.usuarios.where((usuario) {
      if (_pesquisa.isEmpty) {
        return true;
      }

      final termo = _pesquisa.toLowerCase();

      return usuario.nome.toLowerCase().contains(termo) ||
          usuario.email.toLowerCase().contains(termo) ||
          usuario.tipo.toLowerCase().contains(termo);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.go('/dashboard');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Usuários'),
      ),

      body: RefreshIndicator(
        onRefresh: provider.carregarUsuarios,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compacto = constraints.maxWidth < 600;

                      final titulo = const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gerenciamento de usuários',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Cadastre e gerencie os usuários do sistema.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      );

                      final botao = ElevatedButton.icon(
                        onPressed: () {
                          context.go('/usuarios/novo');
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Novo usuário'),
                      );

                      if (compacto) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [titulo, const SizedBox(height: 16), botao],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [titulo, botao],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _pesquisaController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome, e-mail ou perfil...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _pesquisa = value.trim();
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  if (provider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (provider.errorMessage != null)
                    _ErroUsuarios(
                      mensagem: provider.errorMessage!,
                      onTentarNovamente: provider.carregarUsuarios,
                    )
                  else if (usuarios.isEmpty)
                    const _ListaVazia()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: usuarios.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final usuario = usuarios[index];

                        return _UsuarioCard(
                          usuario: usuario,
                          onEditar: () {
                            context.go('/usuarios/${usuario.id}/editar');
                          },
                          onExcluir: () {
                            _excluir(usuario);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _UsuarioCard({
    required this.usuario,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final admin = usuario.tipo == 'ADMIN';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.lightBlue,
            child: Icon(
              admin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  usuario.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                if (usuario.telefone != null &&
                    usuario.telefone!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    usuario.telefone!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: admin
                        ? AppColors.lightBlue
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    admin ? 'Administrador' : 'Funcionário',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Editar',
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),

          IconButton(
            tooltip: 'Excluir',
            onPressed: onExcluir,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 55,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Nenhum usuário encontrado.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroUsuarios extends StatelessWidget {
  final String mensagem;
  final Future<void> Function() onTentarNovamente;

  const _ErroUsuarios({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 50, color: AppColors.error),

            const SizedBox(height: 10),

            Text(mensagem, textAlign: TextAlign.center),

            const SizedBox(height: 15),

            OutlinedButton(
              onPressed: () {
                onTentarNovamente();
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
