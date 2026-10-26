import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';

import '../../clientes/models/cliente_model.dart';
import '../../clientes/providers/cliente_provider.dart';

import '../providers/agendamento_provider.dart';

class AgendamentoFormPage extends StatefulWidget {
  final int? agendamentoId;

  const AgendamentoFormPage({super.key, this.agendamentoId});

  bool get editando => agendamentoId != null;

  @override
  State<AgendamentoFormPage> createState() => _AgendamentoFormPageState();
}

class _AgendamentoFormPageState extends State<AgendamentoFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _descricaoController = TextEditingController();

  int? _clienteId;

  DateTime _data = DateTime.now();
  TimeOfDay _horario = TimeOfDay.now();

  String _status = 'AGENDADO';

  bool _carregando = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializar();
    });
  }

  Future<void> _inicializar() async {
    final clientes = context.read<ClienteProvider>();

    if (clientes.clientes.isEmpty) {
      await clientes.carregarClientes();
    }

    if (widget.editando) {
      await _carregarAgendamento();
    }
  }

  Future<void> _carregarAgendamento() async {
    setState(() {
      _carregando = true;
    });

    final agendamento = await context.read<AgendamentoProvider>().buscarPorId(
      widget.agendamentoId!,
    );

    if (!mounted) {
      return;
    }

    if (agendamento == null) {
      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar o agendamento.'),
        ),
      );

      return;
    }

    _descricaoController.text = agendamento.descricao;

    _clienteId = agendamento.clienteId;

    _data = agendamento.data;

    _horario = TimeOfDay(
      hour: agendamento.data.hour,
      minute: agendamento.data.minute,
    );

    _status = agendamento.status;

    setState(() {
      _carregando = false;
    });
  }

  @override
  void dispose() {
    _descricaoController.dispose();

    super.dispose();
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (selecionada == null) {
      return;
    }

    setState(() {
      _data = selecionada;
    });
  }

  Future<void> _selecionarHorario() async {
    final horario = await showTimePicker(
      context: context,
      initialTime: _horario,
    );

    if (horario == null) {
      return;
    }

    setState(() {
      _horario = horario;
    });
  }

  DateTime _montarDataHora() {
    return DateTime(
      _data.year,
      _data.month,
      _data.day,
      _horario.hour,
      _horario.minute,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_clienteId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um cliente.')));

      return;
    }

    final provider = context.read<AgendamentoProvider>();

    bool sucesso;

    if (widget.editando) {
      sucesso = await provider.atualizar(
        id: widget.agendamentoId!,
        descricao: _descricaoController.text.trim(),
        data: _montarDataHora(),
        clienteId: _clienteId!,
        status: _status,
      );
    } else {
      sucesso = await provider.criar(
        descricao: _descricaoController.text.trim(),
        data: _montarDataHora(),
        clienteId: _clienteId!,
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
                ? 'Agendamento atualizado com sucesso.'
                : 'Agendamento criado com sucesso.',
          ),
        ),
      );

      context.go('/app/agenda');

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Erro ao salvar agendamento.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClienteProvider>();

    final agendamentoProvider = context.watch<AgendamentoProvider>();

    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          title: Text(
            widget.editando ? 'Editar agendamento' : 'Novo agendamento',
          ),

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
                            const Text(
                              'Dados do agendamento',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 24),

                            DropdownButtonFormField<int>(
                              value: _clienteId,

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

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _descricaoController,

                              maxLines: 3,

                              textCapitalization: TextCapitalization.sentences,

                              decoration: const InputDecoration(
                                labelText: 'Descrição *',
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 45),
                                  child: Icon(Icons.description_outlined),
                                ),
                              ),

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe a descrição.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _DateTimeBox(
                                    titulo: 'Data',
                                    valor: DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_data),
                                    icone: Icons.calendar_month_outlined,
                                    onTap: _selecionarData,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: _DateTimeBox(
                                    titulo: 'Horário',
                                    valor: _horario.format(context),
                                    icone: Icons.access_time,
                                    onTap: _selecionarHorario,
                                  ),
                                ),
                              ],
                            ),

                            if (widget.editando) ...[
                              const SizedBox(height: 20),

                              DropdownButtonFormField<String>(
                                value: _status,

                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  prefixIcon: Icon(Icons.info_outline),
                                ),

                                items: const [
                                  DropdownMenuItem(
                                    value: 'AGENDADO',
                                    child: Text('Agendado'),
                                  ),

                                  DropdownMenuItem(
                                    value: 'CANCELADO',
                                    child: Text('Cancelado'),
                                  ),
                                ],

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
                              onPressed: agendamentoProvider.isSaving
                                  ? null
                                  : _salvar,

                              icon: agendamentoProvider.isSaving
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
                                agendamentoProvider.isSaving
                                    ? 'Salvando...'
                                    : 'Salvar',
                              ),
                            ),

                            const SizedBox(height: 10),

                            OutlinedButton(
                              onPressed: () {
                                context.go('/app/agenda');
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

class _DateTimeBox extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final VoidCallback onTap;

  const _DateTimeBox({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(12),

      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: AppColors.primary),

                const SizedBox(width: 6),

                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
