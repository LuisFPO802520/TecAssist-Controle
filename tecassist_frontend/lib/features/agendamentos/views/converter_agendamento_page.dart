import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';

import '../models/agendamento_model.dart';
import '../providers/agendamento_provider.dart';

class ConverterAgendamentoPage extends StatefulWidget {
  final int agendamentoId;

  const ConverterAgendamentoPage({super.key, required this.agendamentoId});

  @override
  State<ConverterAgendamentoPage> createState() =>
      _ConverterAgendamentoPageState();
}

class _ConverterAgendamentoPageState extends State<ConverterAgendamentoPage> {
  final _formKey = GlobalKey<FormState>();

  final _equipamentoController = TextEditingController();

  final _marcaController = TextEditingController();

  final _modeloController = TextEditingController();

  final _problemaController = TextEditingController();

  AgendamentoModel? _agendamento;

  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    final agendamento = await context.read<AgendamentoProvider>().buscarPorId(
      widget.agendamentoId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _agendamento = agendamento;
      _carregando = false;
    });
  }

  @override
  void dispose() {
    _equipamentoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _problemaController.dispose();

    super.dispose();
  }

  Future<void> _converter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<AgendamentoProvider>();

    final sucesso = await provider.converterEmServico(
      agendamentoId: widget.agendamentoId,

      equipamento: _equipamentoController.text,

      marca: _marcaController.text,

      modelo: _modeloController.text,

      problema: _problemaController.text,
    );

    if (!mounted) {
      return;
    }

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento convertido em serviço com sucesso.'),
        ),
      );

      context.go('/app/servicos');

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? 'Erro ao converter agendamento.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendamentoProvider>();

    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          title: const Text('Converter em serviço'),

          leading: IconButton(
            onPressed: () {
              context.go('/app/agenda');
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),

        bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),

        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _agendamento == null
            ? _erro()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),

                    child: Column(
                      children: [
                        _resumo(),

                        const SizedBox(height: 16),

                        Container(
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
                                const Text(
                                  'Dados do serviço',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                TextFormField(
                                  controller: _equipamentoController,

                                  decoration: const InputDecoration(
                                    labelText: 'Equipamento *',
                                    prefixIcon: Icon(
                                      Icons.devices_other_outlined,
                                    ),
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

                                  minLines: 3,
                                  maxLines: 5,

                                  decoration: const InputDecoration(
                                    labelText: 'Problema relatado',
                                    alignLabelWithHint: true,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(bottom: 55),
                                      child: Icon(
                                        Icons.report_problem_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                ElevatedButton.icon(
                                  onPressed: provider.isSaving
                                      ? null
                                      : _converter,

                                  icon: const Icon(Icons.construction_outlined),

                                  label: Text(
                                    provider.isSaving
                                        ? 'Convertendo...'
                                        : 'Converter em Serviço',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _resumo() {
    final agendamento = _agendamento!;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFFE7EDF7),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(Icons.event_available_outlined, color: AppColors.primary),

              SizedBox(width: 8),

              Text(
                'Agendamento selecionado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            agendamento.clienteNome,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          Text(
            agendamento.descricao,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
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

          const Text('Não foi possível carregar o agendamento.'),

          const SizedBox(height: 15),

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
    );
  }
}
