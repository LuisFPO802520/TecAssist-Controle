import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/estoque_model.dart';
import '../providers/estoque_provider.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class EstoqueFormPage extends StatefulWidget {
  final int? estoqueId;

  const EstoqueFormPage({super.key, this.estoqueId});

  bool get editando => estoqueId != null;

  @override
  State<EstoqueFormPage> createState() => _EstoqueFormPageState();
}

class _EstoqueFormPageState extends State<EstoqueFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '0');
  final _valorController = TextEditingController();

  bool _carregando = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editando) {
        _carregarItem();
      } else {
        setState(() {
          _carregando = false;
        });
      }
    });
  }

  Future<void> _carregarItem() async {
    setState(() {
      _carregando = true;
    });

    final provider = context.read<EstoqueProvider>();
    final item = await provider.buscarPorId(widget.estoqueId!);

    if (!mounted) {
      return;
    }

    if (item != null) {
      _preencher(item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Não foi possível carregar o item.',
          ),
        ),
      );
    }

    setState(() {
      _carregando = false;
    });
  }

  void _preencher(EstoqueModel item) {
    _nomeController.text = item.nome;
    _descricaoController.text = item.descricao;
    _fornecedorController.text = item.fornecedor ?? '';
    _quantidadeController.text = '${item.quantidade}';
    _valorController.text = item.valor.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _fornecedorController.dispose();
    _quantidadeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  double? _lerValor() {
    var texto = _valorController.text.trim();

    if (texto.isEmpty) {
      return null;
    }

    if (texto.contains(',')) {
      texto = texto.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(texto);
  }

  String? _validarValor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o valor unitário.';
    }

    final valor = _lerValor();

    if (valor == null || valor < 0) {
      return 'Informe um valor válido.';
    }

    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    if (!auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Somente o administrador pode gerenciar o estoque.'),
        ),
      );
      return;
    }

    final provider = context.read<EstoqueProvider>();
    final valor = _lerValor()!;

    bool sucesso;

    if (widget.editando) {
      sucesso = await provider.atualizar(
        id: widget.estoqueId!,
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        fornecedor: _fornecedorController.text,
        valor: valor,
      );
    } else {
      sucesso = await provider.criar(
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        fornecedor: _fornecedorController.text,
        quantidade: int.parse(_quantidadeController.text),
        valor: valor,
      );
    }

    if (!mounted) {
      return;
    }

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editando
                ? 'Item atualizado com sucesso.'
                : 'Item cadastrado com sucesso.',
          ),
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/app/estoque');
      }

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? 'Não foi possível salvar o item.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<EstoqueProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso restrito')),
        body: const Center(
          child: Text(
            'Somente o administrador pode gerenciar o estoque.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
              widget.editando ? 'Editar item' : 'Novo item',
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.editando
                                  ? 'Dados do item/peça'
                                  : 'Cadastrar item, peça ou equipamento',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _nomeController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Nome *',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome do item/peça.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _descricaoController,
                              textCapitalization: TextCapitalization.sentences,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Descrição *',
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe a descrição.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _fornecedorController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Fornecedor (opcional)',
                                prefixIcon: Icon(Icons.local_shipping_outlined),
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (!widget.editando) ...[
                              TextFormField(
                                controller: _quantidadeController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade inicial *',
                                  prefixIcon: Icon(Icons.numbers_outlined),
                                  helperText:
                                      'Use entrada/saída para alterar o saldo após o cadastro.',
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      int.tryParse(value) == null) {
                                    return 'Informe uma quantidade válida.';
                                  }

                                  if (int.parse(value) < 0) {
                                    return 'A quantidade não pode ser negativa.';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              const ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.swap_vert_circle_outlined,
                                  color: AppColors.primary,
                                ),
                                title: Text('Alterar quantidade'),
                                subtitle: Text(
                                  'A quantidade é controlada pelas movimentações de entrada e saída.',
                                ),
                              ),
                            ],

                            TextFormField(
                              controller: _valorController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9,.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Valor unitário *',
                                prefixText: 'R\$ ',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              validator: _validarValor,
                            ),

                            const SizedBox(height: 28),

                            ElevatedButton.icon(
                              onPressed: provider.isSaving ? null : _salvar,
                              icon: provider.isSaving
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
                                provider.isSaving
                                    ? 'Salvando...'
                                    : 'Salvar item',
                              ),
                            ),

                            const SizedBox(height: 10),

                            OutlinedButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/app/estoque');
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
