import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';

import '../../clientes/models/cliente_model.dart';
import '../../clientes/providers/cliente_provider.dart';
import '../../estoque/models/estoque_model.dart';
import '../../estoque/providers/estoque_provider.dart';

import '../models/servico_model.dart';
import '../providers/servico_provider.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class ServicoFormPage extends StatefulWidget {
  final int? servicoId;

  const ServicoFormPage({super.key, this.servicoId});

  bool get editando => servicoId != null;

  @override
  State<ServicoFormPage> createState() => _ServicoFormPageState();
}

class _ServicoFormPageState extends State<ServicoFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _equipamentoController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _problemaController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _solucaoController = TextEditingController();
  final _valorController = TextEditingController();

  int? _clienteId;

  final List<_PecaSelecionada> _pecasSelecionadas = [];

  String _status = 'ABERTO';
  bool _carregandoInicial = true;
  bool _salvandoPecas = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  Future<void> _carregarDados() async {
    final clientes = context.read<ClienteProvider>();

    if (clientes.clientes.isEmpty) {
      await clientes.carregarClientes();
    }

    if (!mounted) {
      return;
    }

    if (!widget.editando) {
      final estoque = context.read<EstoqueProvider>();
      if (estoque.itens.isEmpty) {
        await estoque.carregar();
      }
    }

    if (widget.editando) {
      final servico = await context.read<ServicoProvider>().buscarPorId(
        widget.servicoId!,
      );

      if (!mounted) {
        return;
      }

      if (servico != null) {
        _preencherFormulario(servico);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<ServicoProvider>().errorMessage ??
                  'Não foi possível carregar o serviço.',
            ),
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _carregandoInicial = false;
    });
  }

  void _preencherFormulario(ServicoModel servico) {
    _clienteId = servico.clienteId;
    _equipamentoController.text = servico.equipamento;
    _marcaController.text = servico.marca ?? '';
    _modeloController.text = servico.modelo ?? '';
    _problemaController.text = servico.problema ?? '';
    _diagnosticoController.text = servico.diagnostico ?? '';
    _solucaoController.text = servico.solucao ?? '';

    _valorController.text = servico.valor?.toStringAsFixed(2) ?? '';

    _status = servico.status;
  }

  @override
  void dispose() {
    _equipamentoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _problemaController.dispose();
    _diagnosticoController.dispose();
    _solucaoController.dispose();
    _valorController.dispose();

    super.dispose();
  }

  double? _lerValor() {
    final texto = _valorController.text.trim();

    if (texto.isEmpty) {
      return null;
    }

    var normalizado = texto.replaceAll('R\$', '').trim();

    if (normalizado.contains(',')) {
      normalizado = normalizado.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(normalizado);
  }

  String? _validarValor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final valor = _lerValor();

    if (valor == null) {
      return 'Informe um valor numérico válido.';
    }

    if (valor < 0) {
      return 'O valor não pode ser negativo.';
    }

    return null;
  }

  Future<void> _adicionarPeca() async {
    final estoqueProvider = context.read<EstoqueProvider>();

    if (estoqueProvider.itens.isEmpty && !estoqueProvider.isLoading) {
      await estoqueProvider.carregar();
    }

    if (!mounted) {
      return;
    }

    final idsSelecionados = _pecasSelecionadas
        .map((peca) => peca.item.id)
        .toSet();

    final disponiveis = estoqueProvider.itens
        .where(
          (item) => item.quantidade > 0 && !idsSelecionados.contains(item.id),
        )
        .toList();

    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não há outros itens disponíveis para adicionar. '
            'Verifique o estoque ou remova uma peça já selecionada.',
          ),
        ),
      );
      return;
    }

    final dados = await showDialog<_DadosNovaPeca>(
      context: context,
      builder: (dialogContext) {
        return _AdicionarPecaDialog(itens: disponiveis);
      },
    );

    if (dados == null || !mounted) {
      return;
    }

    final item = disponiveis.firstWhere((item) => item.id == dados.estoqueId);

    setState(() {
      _pecasSelecionadas.add(
        _PecaSelecionada(item: item, quantidade: dados.quantidade),
      );
    });
  }

  void _removerPecaSelecionada(int estoqueId) {
    setState(() {
      _pecasSelecionadas.removeWhere((peca) => peca.item.id == estoqueId);
    });
  }

  String _normalizarCampo(String? valor) {
    return (valor ?? '').trim();
  }

  ServicoModel? _encontrarServicoRecemCriado(
    ServicoProvider provider,
    Set<int> idsAnteriores,
  ) {
    final equipamento = _equipamentoController.text.trim();
    final candidatos = provider.servicos.where((servico) {
      return !idsAnteriores.contains(servico.id) &&
          servico.clienteId == _clienteId &&
          _normalizarCampo(servico.equipamento) == equipamento &&
          _normalizarCampo(servico.marca) ==
              _normalizarCampo(_marcaController.text) &&
          _normalizarCampo(servico.modelo) ==
              _normalizarCampo(_modeloController.text) &&
          _normalizarCampo(servico.problema) ==
              _normalizarCampo(_problemaController.text) &&
          _normalizarCampo(servico.diagnostico) ==
              _normalizarCampo(_diagnosticoController.text) &&
          _normalizarCampo(servico.solucao) ==
              _normalizarCampo(_solucaoController.text);
    }).toList()..sort((a, b) => b.id.compareTo(a.id));

    if (candidatos.isNotEmpty) {
      return candidatos.first;
    }

    final novosServicos = provider.servicos
        .where((servico) => !idsAnteriores.contains(servico.id))
        .toList();

    if (novosServicos.length == 1) {
      return novosServicos.single;
    }

    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente para o serviço.')),
      );
      return;
    }

    final provider = context.read<ServicoProvider>();
    final estoqueProvider = context.read<EstoqueProvider>();
    final vincularPecas = !widget.editando && _pecasSelecionadas.isNotEmpty;
    final idsAnteriores = <int>{};

    if (vincularPecas) {
      setState(() {
        _salvandoPecas = true;
      });

      await provider.carregar();

      if (!mounted) {
        return;
      }

      idsAnteriores.addAll(provider.servicos.map((servico) => servico.id));
    }

    bool sucesso;

    if (widget.editando) {
      sucesso = await provider.atualizar(
        id: widget.servicoId!,
        clienteId: _clienteId!,
        equipamento: _equipamentoController.text.trim(),
        marca: _marcaController.text,
        modelo: _modeloController.text,
        problema: _problemaController.text,
        diagnostico: _diagnosticoController.text,
        solucao: _solucaoController.text,
        valor: _lerValor(),
        status: _status,
      );
    } else {
      sucesso = await provider.criar(
        clienteId: _clienteId!,
        equipamento: _equipamentoController.text.trim(),
        marca: _marcaController.text,
        modelo: _modeloController.text,
        problema: _problemaController.text,
        diagnostico: _diagnosticoController.text,
        solucao: _solucaoController.text,
        valor: _lerValor(),
      );
    }

    if (!mounted) {
      return;
    }

    if (!sucesso) {
      if (_salvandoPecas) {
        setState(() {
          _salvandoPecas = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao salvar serviço.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (vincularPecas) {
      await provider.carregar();

      if (!mounted) {
        return;
      }

      final novoServico = _encontrarServicoRecemCriado(provider, idsAnteriores);

      if (novoServico == null) {
        setState(() {
          _salvandoPecas = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O serviço foi cadastrado, mas não foi possível localizar '
              'seu registro para vincular as peças. Você poderá adicioná-las '
              'posteriormente nos detalhes do serviço.',
            ),
            backgroundColor: AppColors.error,
          ),
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/app/servicos');
        }
        return;
      }

      var pecasVinculadas = 0;
      String? erroVinculo;

      for (final peca in _pecasSelecionadas) {
        final vinculada = await provider.adicionarPeca(
          servicoId: novoServico.id,
          estoqueId: peca.item.id,
          quantidade: peca.quantidade,
        );

        if (!mounted) {
          return;
        }

        if (!vinculada) {
          erroVinculo =
              provider.errorMessage ??
              'Não foi possível vincular ${peca.item.nome}.';
          break;
        }

        pecasVinculadas++;
      }

      await estoqueProvider.carregar();
      await provider.carregar();

      if (!mounted) {
        return;
      }

      setState(() {
        _salvandoPecas = false;
      });

      if (erroVinculo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Serviço cadastrado. $pecasVinculadas de '
              '${_pecasSelecionadas.length} peça(s) vinculada(s). '
              '$erroVinculo Você pode concluir o vínculo nos detalhes.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );

        context.pushReplacement('/servicos/${novoServico.id}');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Serviço registrado com $pecasVinculadas '
            'peça(s) vinculada(s).',
          ),
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/app/servicos');
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.editando
              ? 'Serviço atualizado com sucesso.'
              : 'Serviço registrado com sucesso.',
        ),
      ),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/servicos');
    }
  }

  Widget _secaoPecas(EstoqueProvider estoqueProvider) {
    final idsSelecionados = _pecasSelecionadas
        .map((peca) => peca.item.id)
        .toSet();
    final existemDisponiveis = estoqueProvider.itens.any(
      (item) => item.quantidade > 0 && !idsSelecionados.contains(item.id),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Itens utilizados (opcional)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _salvandoPecas || !existemDisponiveis
                    ? null
                    : _adicionarPeca,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecione as peças ou itens que serão utilizadas. '
            'Você também poderá adicioná-las depois, nos detalhes do serviço.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (estoqueProvider.isLoading && estoqueProvider.itens.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (estoqueProvider.errorMessage != null &&
              estoqueProvider.itens.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estoqueProvider.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: estoqueProvider.carregar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (_pecasSelecionadas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhuma peça adicionada. O cadastro do serviço não exige peças.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ..._pecasSelecionadas.map((peca) {
              final restante = peca.item.quantidade - peca.quantidade;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peca.item.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantidade utilizada: ${peca.quantidade}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Saldo após a utilização: $restante',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remover peça selecionada',
                      onPressed: _salvandoPecas
                          ? null
                          : () => _removerPecaSelecionada(peca.item.id),
                      icon: const Icon(Icons.close, color: AppColors.error),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClienteProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final estoqueProvider = context.watch<EstoqueProvider>();

    final salvando = servicoProvider.isSaving || _salvandoPecas;

    final opcoesStatus = [...servicoStatusDisponiveis];

    if (!opcoesStatus.contains(_status)) {
      opcoesStatus.add(_status);
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
                  context.go('/app/servicos');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          title: Transform.translate(
            offset: const Offset(0, 18),
            child: Text(
              widget.editando ? 'Editar serviço' : 'Novo serviço',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
        body: _carregandoInicial
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
                                  ? 'Dados do serviço'
                                  : 'Registrar serviço',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Preencha as informações do equipamento e do atendimento.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),

                            if (clientesProvider.clientes.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Não há clientes cadastrados. '
                                  'Cadastre um cliente antes de registrar o serviço.',
                                ),
                              )
                            else
                              DropdownButtonFormField<int>(
                                value: _clienteId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Cliente *',
                                  prefixIcon: Icon(Icons.people_outline),
                                ),
                                items: clientesProvider.clientes.map((
                                  ClienteModel cliente,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: cliente.id,
                                    child: Text(
                                      cliente.nome,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _clienteId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Selecione um cliente.';
                                  }

                                  return null;
                                },
                              ),

                            if (clientesProvider.clientes.isEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  context.push('/clientes/novo');
                                },
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Cadastrar cliente'),
                              ),
                            ],

                            const SizedBox(height: 18),

                            TextFormField(
                              controller: _equipamentoController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Equipamento *',
                                prefixIcon: Icon(Icons.devices_other_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o equipamento.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _marcaController,
                              decoration: const InputDecoration(
                                labelText: 'Marca',
                                prefixIcon: Icon(
                                  Icons.branding_watermark_outlined,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _modeloController,
                              decoration: const InputDecoration(
                                labelText: 'Modelo',
                                prefixIcon: Icon(Icons.numbers_outlined),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _problemaController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Problema relatado',
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _diagnosticoController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Diagnóstico técnico',
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _solucaoController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Solução aplicada',
                                alignLabelWithHint: true,
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _valorController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Valor do serviço',
                                prefixText: 'R\$ ',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              validator: _validarValor,
                            ),

                            if (!widget.editando) ...[
                              const SizedBox(height: 20),
                              _secaoPecas(estoqueProvider),
                            ],

                            if (widget.editando) ...[
                              const SizedBox(height: 18),
                              DropdownButtonFormField<String>(
                                value: _status,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  prefixIcon: Icon(Icons.sync_alt),
                                ),
                                items: opcoesStatus.map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(servicoStatusLabel(status)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    _status = value;
                                  });
                                },
                              ),
                            ],

                            const SizedBox(height: 28),

                            ElevatedButton.icon(
                              onPressed: salvando ? null : _salvar,
                              icon: salvando
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
                                _salvandoPecas
                                    ? 'Vinculando peças...'
                                    : servicoProvider.isSaving
                                    ? 'Salvando...'
                                    : 'Salvar serviço',
                              ),
                            ),

                            const SizedBox(height: 10),

                            OutlinedButton(
                              onPressed: salvando
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/app/servicos');
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

class _PecaSelecionada {
  final EstoqueModel item;
  final int quantidade;

  const _PecaSelecionada({required this.item, required this.quantidade});
}

class _DadosNovaPeca {
  final int estoqueId;
  final int quantidade;

  const _DadosNovaPeca({required this.estoqueId, required this.quantidade});
}

class _AdicionarPecaDialog extends StatefulWidget {
  final List<EstoqueModel> itens;

  const _AdicionarPecaDialog({required this.itens});

  @override
  State<_AdicionarPecaDialog> createState() => _AdicionarPecaDialogState();
}

class _AdicionarPecaDialogState extends State<_AdicionarPecaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController(text: '1');

  int? _estoqueIdSelecionado;

  @override
  void initState() {
    super.initState();
    _estoqueIdSelecionado = widget.itens.isNotEmpty
        ? widget.itens.first.id
        : null;
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  EstoqueModel? get _itemSelecionado {
    for (final item in widget.itens) {
      if (item.id == _estoqueIdSelecionado) {
        return item;
      }
    }
    return null;
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _DadosNovaPeca(
        estoqueId: _estoqueIdSelecionado!,
        quantidade: int.parse(_quantidadeController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _itemSelecionado;

    return AlertDialog(
      title: const Text('Adicionar peça ao serviço'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _estoqueIdSelecionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Peça do estoque',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: widget.itens.map((peca) {
                    return DropdownMenuItem<int>(
                      value: peca.id,
                      child: Text(
                        '${peca.nome} — disponível: ${peca.quantidade}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _estoqueIdSelecionado = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma peça.';
                    }
                    return null;
                  },
                ),
                if (item != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Disponível no estoque: ${item.quantidade} unidade(s)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TextFormField(
                  controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantidade utilizada',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (value) {
                    final quantidade = int.tryParse(value ?? '');

                    if (quantidade == null || quantidade <= 0) {
                      return 'Informe uma quantidade maior que zero.';
                    }

                    if (item == null) {
                      return 'Selecione uma peça.';
                    }

                    if (quantidade > item.quantidade) {
                      return 'Saldo disponível: ${item.quantidade}.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) => _confirmar(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _confirmar, child: const Text('Adicionar')),
      ],
    );
  }
}
