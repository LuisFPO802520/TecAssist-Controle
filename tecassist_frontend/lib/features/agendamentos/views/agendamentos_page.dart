import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/agendamento_provider.dart';
import 'agendamentos_calendario_view.dart';
import 'agendamentos_lista_view.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class AgendamentosPage extends StatefulWidget {
  const AgendamentosPage({super.key});

  @override
  State<AgendamentosPage> createState() => _AgendamentosPageState();
}

class _AgendamentosPageState extends State<AgendamentosPage> {
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AgendamentoProvider>().carregar();
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _novoAgendamento() {
    context.go('/agendamentos/novo');
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    int agendamentoId,
  ) async {
    final auth = context.read<AuthProvider>();
    final tipo = auth.usuario?.tipo.toUpperCase() ?? '';

    final podeExcluir = tipo == 'ADMIN' || tipo == 'FUNCIONARIO';

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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    final provider = context.read<AgendamentoProvider>();
    final sucesso = await provider.remover(agendamentoId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Agendamento excluído com sucesso.'
              : provider.errorMessage ??
                    'Não foi possível excluir o agendamento.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendamentoProvider>();
    final largura = MediaQuery.sizeOf(context).width;
    final compacto = largura < 600;

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
              'Agenda',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compacto ? 14 : 16,
              16,
              compacto ? 14 : 16,
              8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _buscaController,
                  onChanged: provider.setBusca,
                  decoration: InputDecoration(
                    hintText: 'Buscar agendamento...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _buscaController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _buscaController.clear();
                              provider.setBusca('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

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

                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final compacto = constraints.maxWidth < 600;

                    final botao = ElevatedButton.icon(
                      onPressed: _novoAgendamento,
                      icon: const Icon(Icons.event_available),
                      label: const Text('Novo agendamento'),
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
              ],
            ),
          ),

          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.carregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(compacto ? 14 : 16),
                children: [
                  if (provider.isLoading && provider.agendamentos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(45),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.errorMessage != null &&
                      provider.agendamentos.isEmpty)
                    _EstadoAgendamentos(
                      icone: Icons.error_outline_rounded,
                      mensagem: provider.errorMessage!,
                      textoBotao: 'Tentar novamente',
                      onPressed: provider.carregar,
                    )
                  else if (provider.agendamentosFiltrados.isEmpty)
                    _EstadoAgendamentos(
                      icone: Icons.calendar_month_outlined,
                      mensagem: 'Nenhum agendamento encontrado.',
                      textoBotao: 'Atualizar',
                      onPressed: provider.carregar,
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${provider.agendamentosFiltrados.length} '
                        '${provider.agendamentosFiltrados.length == 1 ? 'agendamento encontrado' : 'agendamentos encontrados'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    if (provider.visualizacao == AgendamentoVisualizacao.lista)
                      AgendamentosListaView(
                        agendamentos: provider.agendamentosFiltrados,
                        onEditar: (id) {
                          context.go('/agendamentos/$id/editar');
                        },
                        onConverter: (id) {
                          context.go('/agendamentos/$id/converter');
                        },
                        onExcluir: (id) {
                          _confirmarExclusao(context, id);
                        },
                      )
                    else
                      AgendamentosCalendarioView(
                        provider: provider,
                        onEditar: (id) {
                          context.go('/agendamentos/$id/editar');
                        },
                        onConverter: (id) {
                          context.go('/agendamentos/$id/converter');
                        },
                        onExcluir: (id) {
                          _confirmarExclusao(context, id);
                        },
                      ),
                  ],
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
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: ativo ? AppColors.primary : Colors.white,
        foregroundColor: ativo ? Colors.white : AppColors.textSecondary,
        elevation: 0,
        side: BorderSide(color: ativo ? AppColors.primary : AppColors.border),
      ),
    );
  }
}

class _EstadoAgendamentos extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String textoBotao;
  final Future<void> Function() onPressed;

  const _EstadoAgendamentos({
    required this.icone,
    required this.mensagem,
    required this.textoBotao,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 45),
      child: Column(
        children: [
          Icon(icone, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 14),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => onPressed(), child: Text(textoBotao)),
        ],
      ),
    );
  }
}
