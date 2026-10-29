import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/cliente_model.dart';
import '../providers/cliente_provider.dart';
import 'clientes_cards_view.dart';
import 'clientes_lista_view.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final TextEditingController _pesquisaController = TextEditingController();

  bool _visualizacaoCards = true;

  String _pesquisa = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().carregarClientes();
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();

    super.dispose();
  }

  Future<void> _excluirCliente(ClienteModel cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir cliente'),

          content: Text(
            'Deseja realmente excluir o cliente "${cliente.nome}"?',
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

    final provider = context.read<ClienteProvider>();

    final sucesso = await provider.excluirCliente(cliente.id);

    if (!mounted) {
      return;
    }

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente excluído com sucesso.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao excluir cliente.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();

    final auth = context.watch<AuthProvider>();

    final podeExcluir = auth.isAdmin;

    final clientesFiltrados = provider.clientes.where((cliente) {
      if (_pesquisa.isEmpty) {
        return true;
      }

      final termo = _pesquisa.toLowerCase();

      return cliente.nome.toLowerCase().contains(termo) ||
          cliente.telefone.toLowerCase().contains(termo) ||
          (cliente.email ?? '').toLowerCase().contains(termo) ||
          (cliente.cpf ?? '').toLowerCase().contains(termo) ||
          (cliente.endereco ?? '').toLowerCase().contains(termo);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        toolbarHeight: 85,
        automaticallyImplyLeading: false,

        surfaceTintColor: Colors.transparent,
        elevation: 0,

        flexibleSpace: BluePatternBackground(
          showTopCircles: true,
          showBottomCircles: false,

          compactTopCircles: true,

          child: const SizedBox.expand(),
        ),

        title: const SizedBox(
          height: 60,
          width: double.infinity,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              'Clientes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: provider.carregarClientes,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  TextField(
                    controller: _pesquisaController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _pesquisa = value.trim();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compacto = constraints.maxWidth < 600;

                      final botao = ElevatedButton.icon(
                        onPressed: () {
                          context.go('/clientes/novo');
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Novo cliente'),
                      );

                      if (compacto) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [botao],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [botao],
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        _visualizacaoCards
                            ? Icons.view_agenda_outlined
                            : Icons.view_list_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        _visualizacaoCards
                            ? 'Visualização em cartões'
                            : 'Visualização em lista',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        tooltip: _visualizacaoCards
                            ? 'Visualização em lista'
                            : 'Visualização em cartões',

                        onPressed: () {
                          setState(() {
                            _visualizacaoCards = !_visualizacaoCards;
                          });
                        },

                        icon: Icon(
                          size: 32,
                          _visualizacaoCards
                              ? Icons.view_list_outlined
                              : Icons.view_agenda_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (provider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(45),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (provider.errorMessage != null)
                    _ErroClientes(
                      mensagem: provider.errorMessage!,

                      onTentarNovamente: provider.carregarClientes,
                    )
                  else if (clientesFiltrados.isEmpty)
                    const _ClientesVazio()
                  else if (_visualizacaoCards)
                    ClientesCardsView(
                      clientes: clientesFiltrados,

                      podeExcluir: podeExcluir,

                      onAbrir: (cliente) {
                        context.go('/clientes/${cliente.id}');
                      },

                      onEditar: (cliente) {
                        context.go('/clientes/${cliente.id}/editar');
                      },

                      onExcluir: _excluirCliente,
                    )
                  else
                    ClientesListaView(
                      clientes: clientesFiltrados,

                      podeExcluir: podeExcluir,

                      onAbrir: (cliente) {
                        context.go('/clientes/${cliente.id}');
                      },

                      onEditar: (cliente) {
                        context.go('/clientes/${cliente.id}/editar');
                      },

                      onExcluir: _excluirCliente,
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

class _ClientesVazio extends StatelessWidget {
  const _ClientesVazio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(45),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 55,
              color: AppColors.textSecondary,
            ),

            SizedBox(height: 12),

            Text(
              'Nenhum cliente encontrado.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroClientes extends StatelessWidget {
  final String mensagem;

  final Future<void> Function() onTentarNovamente;

  const _ErroClientes({
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
