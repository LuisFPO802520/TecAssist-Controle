import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cliente_model.dart';
import '../providers/cliente_provider.dart';

class ClienteDetalhesPage extends StatefulWidget {
  final int clienteId;

  const ClienteDetalhesPage({super.key, required this.clienteId});

  @override
  State<ClienteDetalhesPage> createState() => _ClienteDetalhesPageState();
}

class _ClienteDetalhesPageState extends State<ClienteDetalhesPage> {
  ClienteModel? _cliente;

  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCliente();
    });
  }

  Future<void> _carregarCliente() async {
    final provider = context.read<ClienteProvider>();

    final cliente = await provider.buscarCliente(widget.clienteId);

    if (!mounted) {
      return;
    }

    setState(() {
      _cliente = cliente;
      _carregando = false;
    });
  }

  Future<void> _excluir() async {
    final cliente = _cliente;

    if (cliente == null) {
      return;
    }

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
      context.go('/app/clientes');

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
    final auth = context.watch<AuthProvider>();
    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          title: const Text('Cliente'),

          leading: IconButton(
            onPressed: () {
              context.go('/app/clientes');
            },
            icon: const Icon(Icons.arrow_back),
          ),

          actions: [
            if (_cliente != null)
              IconButton(
                tooltip: 'Editar',
                onPressed: () {
                  context.go('/clientes/${widget.clienteId}/editar');
                },
                icon: const Icon(Icons.edit_outlined),
              ),

            if (_cliente != null && auth.isAdmin)
              IconButton(
                tooltip: 'Excluir',
                onPressed: _excluir,
                icon: const Icon(Icons.delete_outline),
              ),

            const SizedBox(width: 6),
          ],
        ),

        bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),

        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _cliente == null
            ? _erro()
            : _conteudo(_cliente!),
      ),
    );
  }

  Widget _erro() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 55, color: AppColors.error),

          const SizedBox(height: 12),

          const Text('Não foi possível carregar o cliente.'),

          const SizedBox(height: 15),

          OutlinedButton(
            onPressed: () {
              setState(() {
                _carregando = true;
              });

              _carregarCliente();
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(ClienteModel cliente) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),

          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: AppColors.surface,

                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: AppColors.border),
                ),

                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE7EDF7),
                      child: Icon(
                        Icons.person_outline,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      cliente.nome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      cliente.telefone,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SecaoDetalhes(
                titulo: 'Informações do cliente',

                children: [
                  _DetalheLinha(
                    icone: Icons.phone_outlined,
                    titulo: 'Telefone',
                    valor: cliente.telefone,
                  ),

                  _DetalheLinha(
                    icone: Icons.email_outlined,
                    titulo: 'E-mail',
                    valor: cliente.email ?? 'Não informado',
                  ),

                  _DetalheLinha(
                    icone: Icons.badge_outlined,
                    titulo: 'CPF',
                    valor: cliente.cpf ?? 'Não informado',
                  ),

                  _DetalheLinha(
                    icone: Icons.location_on_outlined,
                    titulo: 'Endereço',
                    valor: cliente.endereco ?? 'Não informado',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SecaoDetalhes(
                titulo: 'Observações',
                children: [
                  Text(
                    cliente.observacoes?.trim().isNotEmpty == true
                        ? cliente.observacoes!
                        : 'Nenhuma observação cadastrada.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              if (cliente.quantidadeServicos != null) ...[
                const SizedBox(height: 16),

                _SecaoDetalhes(
                  titulo: 'Atendimentos',
                  children: [
                    _DetalheLinha(
                      icone: Icons.construction_outlined,
                      titulo: 'Serviços registrados',
                      valor: cliente.quantidadeServicos.toString(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecaoDetalhes extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _SecaoDetalhes({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 15),

          ...children,
        ],
      ),
    );
  }
}

class _DetalheLinha extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _DetalheLinha({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icone, size: 22, color: AppColors.primary),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
