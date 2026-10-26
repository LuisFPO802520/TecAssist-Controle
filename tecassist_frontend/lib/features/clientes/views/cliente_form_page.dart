import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../providers/cliente_provider.dart';

class ClienteFormPage extends StatefulWidget {
  final int? clienteId;

  const ClienteFormPage({super.key, this.clienteId});

  bool get editando => clienteId != null;

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();

  final _telefoneController = TextEditingController();

  final _emailController = TextEditingController();

  final _cpfController = TextEditingController();

  final _enderecoController = TextEditingController();

  final _observacoesController = TextEditingController();

  bool _carregandoInicial = false;

  @override
  void initState() {
    super.initState();

    if (widget.editando) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarCliente();
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _enderecoController.dispose();
    _observacoesController.dispose();

    super.dispose();
  }

  Future<void> _carregarCliente() async {
    setState(() {
      _carregandoInicial = true;
    });

    final provider = context.read<ClienteProvider>();

    final cliente = await provider.buscarCliente(widget.clienteId!);

    if (!mounted) {
      return;
    }

    if (cliente == null) {
      setState(() {
        _carregandoInicial = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Cliente não encontrado.'),
          backgroundColor: AppColors.error,
        ),
      );

      return;
    }

    _nomeController.text = cliente.nome;

    _telefoneController.text = cliente.telefone;

    _emailController.text = cliente.email ?? '';

    _cpfController.text = cliente.cpf ?? '';

    _enderecoController.text = cliente.endereco ?? '';

    _observacoesController.text = cliente.observacoes ?? '';

    setState(() {
      _carregandoInicial = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ClienteProvider>();

    bool sucesso;

    if (widget.editando) {
      sucesso = await provider.atualizarCliente(
        id: widget.clienteId!,

        nome: _nomeController.text.trim(),

        telefone: _telefoneController.text.trim(),

        email: _emailController.text.trim(),

        cpf: _cpfController.text.trim(),

        endereco: _enderecoController.text.trim(),

        observacoes: _observacoesController.text.trim(),
      );
    } else {
      sucesso = await provider.criarCliente(
        nome: _nomeController.text.trim(),

        telefone: _telefoneController.text.trim(),

        email: _emailController.text.trim(),

        cpf: _cpfController.text.trim(),

        endereco: _enderecoController.text.trim(),

        observacoes: _observacoesController.text.trim(),
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
                ? 'Cliente atualizado com sucesso.'
                : 'Cliente cadastrado com sucesso.',
          ),
        ),
      );

      context.go('/app/clientes');

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Erro ao salvar cliente.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();

    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          title: Text(widget.editando ? 'Editar cliente' : 'Novo cliente'),

          leading: IconButton(
            onPressed: () {
              context.go('/app/clientes');
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),

        bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),

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
                        color: AppColors.surface,

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(color: AppColors.border),
                      ),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            Text(
                              widget.editando
                                  ? 'Dados do cliente'
                                  : 'Cadastrar cliente',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _nomeController,

                              textCapitalization: TextCapitalization.words,

                              decoration: const InputDecoration(
                                labelText: 'Nome *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _telefoneController,

                              keyboardType: TextInputType.phone,

                              maxLength: 11,

                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],

                              decoration: const InputDecoration(
                                labelText: 'Telefone *',
                                prefixIcon: Icon(Icons.phone_outlined),
                                counterText: '',
                              ),

                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o telefone.';
                                }

                                if (value.length < 10 || value.length > 11) {
                                  return 'Informe um telefone com 10 ou 11 dígitos.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailController,

                              keyboardType: TextInputType.emailAddress,

                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),

                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }

                                if (!value.contains('@')) {
                                  return 'Informe um e-mail válido.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _cpfController,

                              keyboardType: TextInputType.number,

                              maxLength: 11,

                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],

                              decoration: const InputDecoration(
                                labelText: 'CPF',
                                prefixIcon: Icon(Icons.badge_outlined),
                                counterText: '',
                              ),

                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }

                                if (value.length != 11) {
                                  return 'O CPF deve possuir 11 dígitos.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _enderecoController,

                              textCapitalization: TextCapitalization.words,

                              decoration: const InputDecoration(
                                labelText: 'Endereço',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _observacoesController,

                              minLines: 3,
                              maxLines: 5,

                              decoration: const InputDecoration(
                                labelText: 'Observações',
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 55),
                                  child: Icon(Icons.notes_outlined),
                                ),
                              ),
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
                                provider.isSaving ? 'Salvando...' : 'Salvar',
                              ),
                            ),

                            const SizedBox(height: 10),

                            OutlinedButton(
                              onPressed: provider.isSaving
                                  ? null
                                  : () {
                                      context.go('/app/clientes');
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
