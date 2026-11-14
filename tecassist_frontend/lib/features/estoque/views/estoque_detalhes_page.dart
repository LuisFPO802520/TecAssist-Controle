import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';

import '../../auth/providers/auth_provider.dart';

import '../models/estoque_model.dart';
import '../models/movimentacao_estoque_model.dart';
import '../providers/estoque_provider.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class EstoqueDetalhesPage extends StatefulWidget {
  final int estoqueId;

  const EstoqueDetalhesPage({super.key, required this.estoqueId});

  @override
  State<EstoqueDetalhesPage> createState() => _EstoqueDetalhesPageState();
}

class _QuantidadeDialog extends StatefulWidget {
  final String titulo;

  const _QuantidadeDialog({required this.titulo});

  @override
  State<_QuantidadeDialog> createState() => _QuantidadeDialogState();
}

class _QuantidadeDialogState extends State<_QuantidadeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantidade = int.parse(_controller.text.trim());

    Navigator.of(context).pop(quantidade);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade',
            prefixIcon: Icon(Icons.numbers_outlined),
          ),
          validator: (value) {
            final numero = int.tryParse(value ?? '');

            if (numero == null || numero <= 0) {
              return 'Digite um número maior que zero.';
            }

            return null;
          },
          onFieldSubmitted: (_) => _confirmar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _confirmar, child: const Text('Continuar')),
      ],
    );
  }
}

class _EstoqueDetalhesPageState extends State<EstoqueDetalhesPage> {
  EstoqueModel? _item;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    final provider = context.read<EstoqueProvider>();

    final item = await provider.buscarPorId(widget.estoqueId);

    await provider.carregarHistorico(widget.estoqueId);

    if (!mounted) {
      return;
    }

    setState(() {
      _item = item;
      _carregando = false;
    });
  }

  Future<int?> _pedirQuantidade(String titulo) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _QuantidadeDialog(titulo: titulo);
      },
    );
  }

  Future<void> _movimentar({required bool entrada}) async {
    final auth = context.read<AuthProvider>();

    if (!auth.isAdmin || _item == null) {
      return;
    }

    final quantidade = await _pedirQuantidade(
      entrada ? 'Registrar entrada' : 'Registrar saída',
    );

    if (quantidade == null || !mounted) {
      return;
    }

    final provider = context.read<EstoqueProvider>();

    final sucesso = entrada
        ? await provider.registrarEntrada(
            estoqueId: widget.estoqueId,
            quantidade: quantidade,
          )
        : await provider.registrarSaida(
            estoqueId: widget.estoqueId,
            quantidade: quantidade,
          );

    if (!mounted) {
      return;
    }

    if (sucesso) {
      await _carregar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Não foi possível registrar a movimentação.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _excluir() async {
    if (!context.read<AuthProvider>().isAdmin || _item == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir item'),
          content: Text('Deseja excluir "${_item!.nome}"?'),
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
    final sucesso = await provider.excluir(_item!.id);

    if (!mounted) {
      return;
    }

    if (sucesso) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/app/estoque');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Não foi possível excluir o item. Verifique se há vínculos com serviços ou movimentações.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<EstoqueProvider>();

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
                  context.go('/app/estoque');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          title: Transform.translate(
            offset: const Offset(0, 18),
            child: Text(
              _item?.nome ?? 'Detalhes da item',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 4),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _item == null
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
                      const Text('Não foi possível carregar o item.'),
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
            : _conteudo(_item!, auth.isAdmin, provider),
      ),
    );
  }

  Widget _conteudo(
    EstoqueModel item,
    bool podeGerenciar,
    EstoqueProvider provider,
  ) {
    final corQuantidade = item.semEstoque
        ? AppColors.error
        : item.estoqueBaixo
        ? Colors.orange.shade800
        : Colors.green.shade700;

    final historico = provider.historicoDoItem(item.id);

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
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
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 42,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  item.nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.descricao,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 30),
                _DetalheEstoque(
                  titulo: 'Quantidade disponível',
                  valor: '${item.quantidade}',
                  cor: corQuantidade,
                ),
                _DetalheEstoque(
                  titulo: 'Valor unitário',
                  valor: NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$',
                  ).format(item.valor),
                ),
                _DetalheEstoque(
                  titulo: 'Fornecedor',
                  valor: item.fornecedor?.isNotEmpty == true
                      ? item.fornecedor!
                      : 'Não informado',
                ),
                _DetalheEstoque(
                  titulo: 'Cadastro',
                  valor: item.dataCadastro == null
                      ? 'Não informado'
                      : DateFormat('dd/MM/yyyy').format(item.dataCadastro!),
                ),
              ],
            ),
          ),

          if (podeGerenciar) ...[
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _movimentar(entrada: true),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Entrada'),
                ),

                OutlinedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _movimentar(entrada: false),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Saída'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () {
                          context.push('/estoque/${widget.estoqueId}/editar');
                        },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),

                OutlinedButton.icon(
                  onPressed: provider.isSaving ? null : _excluir,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Histórico de movimentações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                if (provider.historicoError != null)
                  Text(
                    provider.historicoError!,
                    style: const TextStyle(color: AppColors.error),
                  )
                else if (historico.isEmpty)
                  const Text(
                    'Ainda não há movimentações registradas para este item.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ...historico.map(
                    (movimentacao) =>
                        _MovimentacaoLinha(movimentacao: movimentacao),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalheEstoque extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color? cor;

  const _DetalheEstoque({required this.titulo, required this.valor, this.cor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimentacaoLinha extends StatelessWidget {
  final MovimentacaoEstoqueModel movimentacao;

  const _MovimentacaoLinha({required this.movimentacao});

  @override
  Widget build(BuildContext context) {
    final entrada = movimentacao.ehEntrada;
    final cor = entrada ? Colors.green.shade700 : AppColors.error;

    final data = movimentacao.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entrada ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: cor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movimentacao.tipoLabel}: '
                  '${movimentacao.quantidade} unidade(s)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: cor),
                ),
                if (data != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(data),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
