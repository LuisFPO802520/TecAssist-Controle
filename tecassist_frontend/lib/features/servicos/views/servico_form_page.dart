import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';

import '../../clientes/models/cliente_model.dart';
import '../../clientes/providers/cliente_provider.dart';

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

  String _status = 'ABERTO';
  bool _carregandoInicial = true;

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

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editando
                ? 'Serviço atualizado com sucesso.'
                : 'Serviço registrado com sucesso.',
          ),
        ),
      );

      context.go('/app/servicos');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Erro ao salvar serviço.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClienteProvider>();
    final servicoProvider = context.watch<ServicoProvider>();

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
                context.go('/app/servicos');
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
                                  context.go('/clientes/novo');
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
                              onPressed: servicoProvider.isSaving
                                  ? null
                                  : _salvar,
                              icon: servicoProvider.isSaving
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
                                servicoProvider.isSaving
                                    ? 'Salvando...'
                                    : 'Salvar serviço',
                              ),
                            ),

                            const SizedBox(height: 10),

                            OutlinedButton(
                              onPressed: () {
                                context.go('/app/servicos');
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
