import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/agendamento_provider.dart';
import 'agendamentos_calendario_view.dart';
import 'agendamentos_lista_view.dart';

class AgendamentosPage extends StatefulWidget {
  const AgendamentosPage({super.key});

  @override
  State<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends State<AgendamentosPage> {
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgendamentoProvider>().carregar();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    int agendamentoId,
  ) async {
    final auth = context.read<AuthProvider>();

    final tipo = auth.usuario?.tipo.toUpperCase() ?? '';

    final bool podeExcluir = tipo == 'ADMIN' || tipo == 'FUNCIONARIO';

    if (!podeExcluir) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem permissão para excluir agendamentos.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir agendamento'),
          content: const Text('Deseja realmente excluir este agendamento?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    final sucesso = await context.read<AgendamentoProvider>().remover(
      agendamentoId,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Agendamento excluído com sucesso.'
              : context.read<AgendamentoProvider>().errorMessage ??
                    'Não foi possível excluir o agendamento.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendamentoProvider>();

    final auth = context.watch<AuthProvider>();
    final nomeUsuario = auth.usuario?.nome ?? 'Usuário';

    final hojeFormatado = DateFormat(
      "dd 'de' MMMM",
      'pt_BR',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Novo agendamento',
            onPressed: () {
              context.go('/agendamentos/novo');
            },
            icon: const Icon(Icons.add),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo, $nomeUsuario',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Controle de agendamentos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hoje: $hojeFormatado',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _buscaController,
                          onChanged: provider.setBusca,
                          decoration: InputDecoration(
                            hintText: 'Buscar por cliente, descrição ou status',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _buscaController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _buscaController.clear();
                                      provider.setBusca('');
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _ToggleViewButton(
                                ativo:
                                    provider.visualizacao ==
                                    AgendamentoVisualizacao.lista,
                                icon: Icons.view_list_rounded,
                                label: 'Lista',
                                onTap: () {
                                  provider.setVisualizacao(
                                    AgendamentoVisualizacao.lista,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ToggleViewButton(
                                ativo:
                                    provider.visualizacao ==
                                    AgendamentoVisualizacao.calendario,
                                icon: Icons.calendar_month_rounded,
                                label: 'Calendário',
                                onTap: () {
                                  provider.setVisualizacao(
                                    AgendamentoVisualizacao.calendario,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.isLoading && provider.agendamentos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.errorMessage != null &&
                      provider.agendamentos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: provider.carregar,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  else
                    provider.visualizacao == AgendamentoVisualizacao.lista
                        ? AgendamentosListaView(
                            agendamentos: provider.agendamentosFiltrados,

                            onEditar: (agendamentoId) {
                              context.go('/agendamentos/$agendamentoId/editar');
                            },

                            onConverter: (agendamentoId) {
                              context.go(
                                '/agendamentos/$agendamentoId/converter',
                              );
                            },

                            onExcluir: (agendamentoId) {
                              _confirmarExclusao(context, agendamentoId);
                            },
                          )
                        : AgendamentosCalendarioView(
                            provider: provider,

                            onEditar: (agendamentoId) {
                              context.go('/agendamentos/$agendamentoId/editar');
                            },

                            onConverter: (agendamentoId) {
                              context.go(
                                '/agendamentos/$agendamentoId/converter',
                              );
                            },

                            onExcluir: (agendamentoId) {
                              _confirmarExclusao(context, agendamentoId);
                            },
                          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleViewButton extends StatelessWidget {
  final bool ativo;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToggleViewButton({
    required this.ativo,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: ativo ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ativo ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ativo ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: ativo ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
