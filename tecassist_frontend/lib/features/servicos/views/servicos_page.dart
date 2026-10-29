import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/servico_model.dart';
import '../providers/servico_provider.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class ServicosPage extends StatefulWidget {
  const ServicosPage({super.key});

  @override
  State<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends State<ServicosPage> {
  final _buscaController = TextEditingController();

  String _busca = '';
  String _filtroStatus = 'TODOS';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ServicoProvider>().carregar();
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
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

  Future<void> _excluir(ServicoModel servico) async {
    final auth = context.read<AuthProvider>();

    if (!auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Somente o administrador pode excluir serviços.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir serviço'),
          content: Text(
            'Deseja realmente excluir o serviço '
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Serviço excluído com sucesso.'
              : provider.errorMessage ?? 'Não foi possível excluir o serviço.',
        ),
      ),
    );
  }

  Future<void> _alterarStatus(ServicoModel servico) async {
    var selecionado = servico.status;

    final opcoes = [...servicoStatusDisponiveis];

    if (!opcoes.contains(selecionado)) {
      opcoes.add(selecionado);
    }

    final novoStatus = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizarDialogo) {
            return AlertDialog(
              title: const Text('Atualizar status'),
              content: DropdownButtonFormField<String>(
                value: selecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status do serviço',
                ),
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

    if (novoStatus == null || novoStatus == servico.status || !mounted) {
      return;
    }

    final provider = context.read<ServicoProvider>();

    final sucesso = await provider.atualizarStatus(servico, novoStatus);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Status atualizado com sucesso.'
              : provider.errorMessage ?? 'Não foi possível atualizar o status.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServicoProvider>();
    final auth = context.watch<AuthProvider>();

    final termo = _busca.trim().toLowerCase();

    final filtrados = provider.servicos.where((servico) {
      final correspondeBusca =
          termo.isEmpty ||
          (servico.codigo ?? '').toLowerCase().contains(termo) ||
          servico.equipamento.toLowerCase().contains(termo) ||
          (servico.marca ?? '').toLowerCase().contains(termo) ||
          (servico.modelo ?? '').toLowerCase().contains(termo) ||
          servico.clienteNome.toLowerCase().contains(termo) ||
          (servico.problema ?? '').toLowerCase().contains(termo);

      final correspondeStatus =
          _filtroStatus == 'TODOS' ||
          servico.status.toUpperCase() == _filtroStatus;

      return correspondeBusca && correspondeStatus;
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
              'Serviços',
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _buscaController,
                  onChanged: (value) {
                    setState(() {
                      _busca = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar código, equipamento ou cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busca.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _buscaController.clear();
                              setState(() {
                                _busca = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _filtroStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por status',
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'TODOS',
                      child: Text('Todos os status'),
                    ),
                    ...servicoStatusDisponiveis.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(servicoStatusLabel(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _filtroStatus = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final compacto = constraints.maxWidth < 600;

                    final botaoNovo = ElevatedButton.icon(
                      onPressed: () {
                        context.go('/servicos/novo');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Novo serviço'),
                    );

                    if (compacto) {
                      return SizedBox(width: double.infinity, child: botaoNovo);
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [botaoNovo],
                    );
                  },
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.carregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (provider.isLoading && provider.servicos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(45),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.errorMessage != null &&
                      provider.servicos.isEmpty)
                    _EstadoVazio(
                      icone: Icons.error_outline,
                      mensagem: provider.errorMessage!,
                      textoBotao: 'Tentar novamente',
                      onPressed: provider.carregar,
                    )
                  else if (filtrados.isEmpty)
                    _EstadoVazio(
                      icone: Icons.construction_outlined,
                      mensagem: 'Nenhum serviço encontrado.',
                      textoBotao: 'Atualizar',
                      onPressed: provider.carregar,
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${filtrados.length} '
                        '${filtrados.length == 1 ? 'serviço encontrado' : 'serviços encontrados'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ...filtrados.map(
                      (servico) => _ServicoCard(
                        servico: servico,
                        podeExcluir: auth.isAdmin,
                        corStatus: _corStatus(servico.status),
                        onDetalhes: () {
                          context.go('/servicos/${servico.id}');
                        },
                        onEditar: () {
                          context.go('/servicos/${servico.id}/editar');
                        },
                        onAlterarStatus: () {
                          _alterarStatus(servico);
                        },
                        onExcluir: () {
                          _excluir(servico);
                        },
                      ),
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

class _ServicoCard extends StatelessWidget {
  final ServicoModel servico;
  final bool podeExcluir;
  final Color corStatus;
  final VoidCallback onDetalhes;
  final VoidCallback onEditar;
  final VoidCallback onAlterarStatus;
  final VoidCallback onExcluir;

  const _ServicoCard({
    required this.servico,
    required this.podeExcluir,
    required this.corStatus,
    required this.onDetalhes,
    required this.onEditar,
    required this.onAlterarStatus,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final codigo = servico.codigo ?? '#${servico.id}';

    final equipamentoDetalhe = [
      if (servico.marca?.isNotEmpty == true) servico.marca!,
      if (servico.modelo?.isNotEmpty == true) servico.modelo!,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onDetalhes,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: corStatus),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  codigo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  servico.equipamento,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Ações do serviço',
                            onSelected: (valor) {
                              switch (valor) {
                                case 'detalhes':
                                  onDetalhes();
                                  break;
                                case 'editar':
                                  onEditar();
                                  break;
                                case 'status':
                                  onAlterarStatus();
                                  break;
                                case 'excluir':
                                  onExcluir();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'detalhes',
                                child: Text('Ver detalhes'),
                              ),
                              const PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar serviço'),
                              ),
                              const PopupMenuItem(
                                value: 'status',
                                child: Text('Alterar status'),
                              ),
                              if (podeExcluir)
                                const PopupMenuItem(
                                  value: 'excluir',
                                  child: Text(
                                    'Excluir serviço',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (equipamentoDetalhe.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          equipamentoDetalhe,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      _LinhaServico(
                        icone: Icons.person_outline,
                        texto: servico.clienteNome,
                      ),
                      const SizedBox(height: 8),
                      _LinhaServico(
                        icone: Icons.engineering_outlined,
                        texto: servico.usuarioNome,
                      ),
                      if (servico.createdAt != null) ...[
                        const SizedBox(height: 8),
                        _LinhaServico(
                          icone: Icons.calendar_today_outlined,
                          texto: DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(servico.createdAt!),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: corStatus.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              servicoStatusLabel(servico.status),
                              style: TextStyle(
                                color: corStatus,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (servico.valor != null)
                            Text(
                              NumberFormat.currency(
                                locale: 'pt_BR',
                                symbol: 'R\$',
                              ).format(servico.valor),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
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
    );
  }
}

class _LinhaServico extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _LinhaServico({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String textoBotao;
  final Future<void> Function() onPressed;

  const _EstadoVazio({
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
