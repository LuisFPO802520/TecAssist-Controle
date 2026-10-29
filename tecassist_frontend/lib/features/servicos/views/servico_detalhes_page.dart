import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../../core/widgets/blue_pattern_background.dart';

import '../../auth/providers/auth_provider.dart';

import '../models/servico_model.dart';
import '../providers/servico_provider.dart';

class ServicoDetalhesPage extends StatefulWidget {
  final int servicoId;

  const ServicoDetalhesPage({super.key, required this.servicoId});

  @override
  State<ServicoDetalhesPage> createState() => _ServicoDetalhesPageState();
}

class _ServicoDetalhesPageState extends State<ServicoDetalhesPage> {
  ServicoModel? _servico;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    final servico = await context.read<ServicoProvider>().buscarPorId(
      widget.servicoId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _servico = servico;
      _carregando = false;
    });
  }

  Color _corStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ABERTO':
        return Colors.blue;
      case 'EM_ANDAMENTO':
        return Colors.orange;
      case 'AGUARDANDO_PECA':
        return Colors.deepOrange;
      case 'CONCLUIDO':
        return Colors.green;
      case 'ENTREGUE':
        return Colors.teal;
      case 'CANCELADO':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _alterarStatus() async {
    final servico = _servico;

    if (servico == null) {
      return;
    }

    var selecionado = servico.status;

    final opcoes = [...servicoStatusDisponiveis];

    if (!opcoes.contains(selecionado)) {
      opcoes.add(selecionado);
    }

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizarDialogo) {
            return AlertDialog(
              title: const Text('Alterar status'),
              content: DropdownButtonFormField<String>(
                value: selecionado,
                isExpanded: true,
                items: opcoes.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(servicoStatusLabel(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  atualizarDialogo(() {
                    selecionado = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selecionado);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado == null || resultado == servico.status || !mounted) {
      return;
    }

    final provider = context.read<ServicoProvider>();

    final sucesso = await provider.atualizarStatus(servico, resultado);

    if (!mounted) {
      return;
    }

    if (sucesso) {
      await _carregar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Não foi possível atualizar o status.',
          ),
        ),
      );
    }
  }

  Future<void> _excluir() async {
    final auth = context.read<AuthProvider>();

    if (!auth.isAdmin) {
      return;
    }

    final servico = _servico;

    if (servico == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir serviço'),
          content: Text(
            'Deseja realmente excluir '
            '${servico.codigo ?? '#${servico.id}'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

    final provider = context.read<ServicoProvider>();
    final sucesso = await provider.excluir(servico.id);

    if (!mounted) {
      return;
    }

    if (sucesso) {
      context.go('/app/servicos');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Não foi possível excluir o serviço.',
          ),
        ),
      );
    }
  }

  String _data(DateTime? data) {
    if (data == null) {
      return 'Não informada';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  String _texto(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Não informado';
    }

    return valor;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                context.go('/app/servicos');
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          title: Transform.translate(
            offset: const Offset(0, 18),
            child: Text(
              _servico?.codigo ?? 'Detalhes do serviço',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _servico == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Não foi possível carregar o serviço.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _carregando = true;
                          });
                          _carregar();
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : _conteudo(_servico!, auth),
      ),
    );
  }

  Widget _conteudo(ServicoModel servico, AuthProvider auth) {
    final cor = _corStatus(servico.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servico.codigo ?? 'Serviço #${servico.id}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      servico.equipamento,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                            if (servico.marca?.isNotEmpty == true)
                              servico.marca!,
                            if (servico.modelo?.isNotEmpty == true)
                              servico.modelo!,
                          ].join(' • ').isEmpty
                          ? 'Marca e modelo não informados'
                          : [
                              if (servico.marca?.isNotEmpty == true)
                                servico.marca!,
                              if (servico.modelo?.isNotEmpty == true)
                                servico.modelo!,
                            ].join(' • '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        servicoStatusLabel(servico.status),
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _alterarStatus,
                          icon: const Icon(Icons.sync_alt),
                          label: const Text('Alterar status'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.go('/servicos/${widget.servicoId}/editar');
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        if (auth.isAdmin)
                          OutlinedButton.icon(
                            onPressed: _excluir,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Excluir'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SecaoServico(
                titulo: 'Cliente e responsável',
                filhos: [
                  _InfoServico(
                    titulo: 'Cliente',
                    valor: servico.clienteNome,
                    icone: Icons.person_outline,
                  ),
                  _InfoServico(
                    titulo: 'Telefone do cliente',
                    valor: _texto(servico.clienteTelefone),
                    icone: Icons.phone_outlined,
                  ),
                  _InfoServico(
                    titulo: 'Funcionário responsável',
                    valor: servico.usuarioNome,
                    icone: Icons.engineering_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SecaoServico(
                titulo: 'Relato e execução',
                filhos: [
                  _InfoServico(
                    titulo: 'Problema relatado',
                    valor: _texto(servico.problema),
                    icone: Icons.report_problem_outlined,
                  ),
                  _InfoServico(
                    titulo: 'Diagnóstico técnico',
                    valor: _texto(servico.diagnostico),
                    icone: Icons.search_outlined,
                  ),
                  _InfoServico(
                    titulo: 'Solução aplicada',
                    valor: _texto(servico.solucao),
                    icone: Icons.build_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SecaoServico(
                titulo: 'Registro',
                filhos: [
                  _InfoServico(
                    titulo: 'Data de registro',
                    valor: _data(servico.createdAt),
                    icone: Icons.calendar_today_outlined,
                  ),
                  _InfoServico(
                    titulo: 'Finalizado em',
                    valor: _data(servico.finishedAt),
                    icone: Icons.event_available_outlined,
                  ),
                  _InfoServico(
                    titulo: 'Valor',
                    valor: servico.valor == null
                        ? 'Não informado'
                        : NumberFormat.currency(
                            locale: 'pt_BR',
                            symbol: 'R\$',
                          ).format(servico.valor),
                    icone: Icons.payments_outlined,
                  ),
                  _InfoServico(
                    titulo: 'Peças vinculadas',
                    valor: '${servico.quantidadePecas}',
                    icone: Icons.inventory_2_outlined,
                  ),
                  if (servico.agendamentoId != null)
                    _InfoServico(
                      titulo: 'Agendamento de origem',
                      valor: '#${servico.agendamentoId}',
                      icone: Icons.event_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecaoServico extends StatelessWidget {
  final String titulo;
  final List<Widget> filhos;

  const _SecaoServico({required this.titulo, required this.filhos});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          ...filhos,
        ],
      ),
    );
  }
}

class _InfoServico extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _InfoServico({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
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
