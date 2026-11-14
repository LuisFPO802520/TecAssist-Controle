import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/estoque_model.dart';
import '../providers/estoque_provider.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  final _buscaController = TextEditingController();

  String _busca = '';
  String _filtro = 'TODOS';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EstoqueProvider>().carregar();
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _confirmarExclusao(EstoqueModel item) async {
    if (!context.read<AuthProvider>().isAdmin) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir item'),
          content: Text('Deseja excluir "${item.nome}" do estoque?'),
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

    final provider = context.read<EstoqueProvider>();
    final sucesso = await provider.excluir(item.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Item excluído com sucesso.'
              : provider.errorMessage ?? 'Não foi possível excluir o item.',
        ),
      ),
    );
  }

  Color _corQuantidade(EstoqueModel item) {
    if (item.semEstoque) {
      return AppColors.error;
    }

    if (item.estoqueBaixo) {
      return Colors.orange.shade800;
    }

    return Colors.green.shade700;
  }

  String _statusQuantidade(EstoqueModel item) {
    if (item.semEstoque) {
      return 'Sem estoque';
    }

    if (item.estoqueBaixo) {
      return 'Estoque baixo';
    }

    return 'Disponível';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstoqueProvider>();
    final auth = context.watch<AuthProvider>();

    final termo = _busca.trim().toLowerCase();

    final filtrados = provider.itens.where((item) {
      final correspondeTexto =
          termo.isEmpty ||
          item.nome.toLowerCase().contains(termo) ||
          item.descricao.toLowerCase().contains(termo) ||
          (item.fornecedor ?? '').toLowerCase().contains(termo);

      final correspondeFiltro = switch (_filtro) {
        'ZERADO' => item.semEstoque,
        'BAIXO' => item.estoqueBaixo,
        _ => true,
      };

      return correspondeTexto && correspondeFiltro;
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
              'Estoque',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: provider.carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _buscaController,
              onChanged: (value) {
                setState(() {
                  _busca = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar item/peça ou fornecedor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
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
              value: _filtro,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar estoque',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: const [
                DropdownMenuItem(value: 'TODOS', child: Text('Todos os itens')),
                DropdownMenuItem(
                  value: 'BAIXO',
                  child: Text('Estoque baixo (até 5)'),
                ),
                DropdownMenuItem(value: 'ZERADO', child: Text('Sem estoque')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _filtro = value;
                });
              },
            ),

            const SizedBox(height: 12),

            if (auth.isAdmin) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final compacto = constraints.maxWidth < 600;

                  final botao = ElevatedButton.icon(
                    onPressed: () {
                      context.push('/estoque/novo');
                    },
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Adicionar item'),
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
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: _ResumoEstoque(
                    titulo: 'Itens',
                    valor: '${provider.totalItens}',
                    icone: Icons.inventory_2_outlined,
                    cor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResumoEstoque(
                    titulo: 'Estoque baixo',
                    valor: '${provider.totalEstoqueBaixo}',
                    icone: Icons.warning_amber_outlined,
                    cor: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResumoEstoque(
                    titulo: 'Zerados',
                    valor: '${provider.totalSemEstoque}',
                    icone: Icons.remove_shopping_cart_outlined,
                    cor: AppColors.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            if (provider.isLoading && provider.itens.isEmpty)
              const Padding(
                padding: EdgeInsets.all(45),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.errorMessage != null && provider.itens.isEmpty)
              _EstadoEstoque(
                mensagem: provider.errorMessage!,
                onTentar: provider.carregar,
              )
            else if (filtrados.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 45),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 52,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum item encontrado.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${filtrados.length} '
                  '${filtrados.length == 1 ? 'item encontrado' : 'itens encontrados'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ...filtrados.map(
                (item) => _EstoqueCard(
                  item: item,
                  podeEditar: auth.isAdmin,
                  corQuantidade: _corQuantidade(item),
                  statusQuantidade: _statusQuantidade(item),
                  onDetalhes: () {
                    context.push('/estoque/${item.id}');
                  },
                  onEditar: () {
                    context.push('/estoque/${item.id}/editar');
                  },
                  onExcluir: () => _confirmarExclusao(item),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumoEstoque extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _ResumoEstoque({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 23),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstoqueCard extends StatelessWidget {
  final EstoqueModel item;
  final bool podeEditar;
  final Color corQuantidade;
  final String statusQuantidade;
  final VoidCallback onDetalhes;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _EstoqueCard({
    required this.item,
    required this.podeEditar,
    required this.corQuantidade,
    required this.statusQuantidade,
    required this.onDetalhes,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onDetalhes,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EDF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quantidade: ${item.quantidade}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: corQuantidade,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusQuantidade,
                      style: TextStyle(fontSize: 12, color: corQuantidade),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'pt_BR',
                        symbol: 'R\$',
                      ).format(item.valor),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),

              if (podeEditar)
                PopupMenuButton<String>(
                  tooltip: 'Ações do item',
                  onSelected: (acao) {
                    switch (acao) {
                      case 'detalhes':
                        onDetalhes();
                        break;
                      case 'editar':
                        onEditar();
                        break;
                      case 'excluir':
                        onExcluir();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'detalhes',
                      child: Text('Ver detalhes'),
                    ),
                    PopupMenuItem(value: 'editar', child: Text('Editar item')),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Text(
                        'Excluir item',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoEstoque extends StatelessWidget {
  final String mensagem;
  final Future<void> Function() onTentar;

  const _EstadoEstoque({required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => onTentar(),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
