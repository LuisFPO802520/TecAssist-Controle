import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../../core/widgets/blue_pattern_background.dart';

import '../../auth/providers/auth_provider.dart';
import '../../estoque/models/estoque_model.dart';
import '../../estoque/providers/estoque_provider.dart';

import '../models/servico_model.dart';
import '../models/servico_peca_model.dart';
import '../models/notificacao_model.dart';
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

  Future<void> _carregar({bool mostrarCarregamento = true}) async {
    if (mostrarCarregamento && mounted) {
      setState(() {
        _carregando = true;
      });
    }

    final estoqueProvider = context.read<EstoqueProvider>();

    if (estoqueProvider.itens.isEmpty) {
      await estoqueProvider.carregar();
    }

    if (!mounted) {
      return;
    }

    final servicoProvider = context.read<ServicoProvider>();
    final servico = await servicoProvider.buscarPorId(widget.servicoId);

    if (!mounted) {
      return;
    }

    if (servico != null) {
      await servicoProvider.carregarNotificacoes(servico.id);
    }

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

  bool _podeAlterarPecas(ServicoModel servico) {
    const estadosBloqueados = {'ENTREGUE', 'CANCELADO', 'FINALIZADO'};

    return !estadosBloqueados.contains(servico.status.toUpperCase());
  }

  EstoqueModel? _buscarItemEstoque(int estoqueId, List<EstoqueModel> itens) {
    for (final item in itens) {
      if (item.id == estoqueId) {
        return item;
      }
    }

    return null;
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
                  return DropdownMenuItem<String>(
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
      await _carregar(mostrarCarregamento: false);

      if (!mounted) {
        return;
      }

      final atualizado = _servico;
      if (atualizado?.clienteTelefone?.trim().isNotEmpty == true) {
        final preparar = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Avisar o cliente?'),
              content: const Text(
                'O status foi atualizado. Deseja preparar uma mensagem para o cliente abrir no WhatsApp?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Depois'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Preparar mensagem'),
                ),
              ],
            );
          },
        );

        if (preparar == true && mounted) {
          await _prepararMensagemWhatsApp();
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Não foi possível atualizar o status.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _normalizarTelefoneWhatsApp(String telefone) {
    var digitos = telefone.replaceAll(RegExp(r'\D'), '');

    if (digitos.startsWith('55') &&
        (digitos.length == 12 || digitos.length == 13)) {
      return digitos;
    }

    if (digitos.startsWith('0')) {
      digitos = digitos.substring(1);
    }

    if (digitos.length == 10 || digitos.length == 11) {
      return '55$digitos';
    }

    return null;
  }

  String _montarMensagemWhatsApp(ServicoModel servico) {
    final equipamento = [
      servico.equipamento,
      if (servico.marca?.trim().isNotEmpty == true) servico.marca!.trim(),
      if (servico.modelo?.trim().isNotEmpty == true) servico.modelo!.trim(),
    ].join(' ');

    final codigo = servico.codigo ?? '#${servico.id}';

    return 'Olá, ${servico.clienteNome}!\n\n'
        'Aqui é da assistência técnica. Temos uma atualização sobre o seu atendimento.\n\n'
        'Código do serviço: $codigo\n'
        'Equipamento: $equipamento\n'
        'Status atual: ${servicoStatusLabel(servico.status)}\n\n'
        'Em caso de dúvidas, estamos à disposição!';
  }

  Future<void> _prepararMensagemWhatsApp() async {
    final servico = _servico;

    if (servico == null) {
      return;
    }

    final telefoneOriginal = servico.clienteTelefone?.trim() ?? '';
    if (telefoneOriginal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente não possui telefone cadastrado.'),
        ),
      );
      return;
    }

    final mensagem = _montarMensagemWhatsApp(servico);
    final provider = context.read<ServicoProvider>();

    final resultado = await provider.prepararWhatsApp(
      servicoId: servico.id,
      mensagem: mensagem,
    );

    if (!mounted) {
      return;
    }

    if (resultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Não foi possível preparar a mensagem.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final numero = _normalizarTelefoneWhatsApp(resultado.telefone);
    if (numero == null) {
      await Clipboard.setData(ClipboardData(text: mensagem));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mensagem registrada, mas o telefone não está em um formato válido. O texto foi copiado.',
          ),
        ),
      );
      return;
    }

    final uri = Uri.https('wa.me', '/$numero', {'text': mensagem});

    var abriuWhatsApp = false;
    try {
      abriuWhatsApp = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      abriuWhatsApp = false;
    }

    if (!mounted) {
      return;
    }

    if (!abriuWhatsApp) {
      await Clipboard.setData(ClipboardData(text: mensagem));
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          abriuWhatsApp
              ? 'Mensagem aberta no WhatsApp. Revise e envie manualmente.'
              : 'Não foi possível abrir o WhatsApp. A mensagem foi copiada e ficou registrada como preparada.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _marcarNotificacaoComoEnviada(
    NotificacaoModel notificacao,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar envio'),
          content: const Text(
            'Você enviou esta mensagem ao cliente pelo WhatsApp?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Ainda não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sim, foi enviada'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    final provider = context.read<ServicoProvider>();
    final sucesso = await provider.marcarNotificacaoComoEnviada(notificacao.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Mensagem marcada como enviada.'
              : provider.errorMessage ??
                    'Não foi possível atualizar o histórico.',
        ),
        backgroundColor: sucesso ? null : AppColors.error,
      ),
    );
  }

  Future<void> _excluir() async {
    if (!context.read<AuthProvider>().isAdmin || _servico == null) {
      return;
    }

    final servico = _servico!;

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
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/app/servicos');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Não foi possível excluir o serviço.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _adicionarPeca(ServicoModel servico) async {
    if (!_podeAlterarPecas(servico)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não é possível alterar itens/peças de um serviço encerrado.',
          ),
        ),
      );
      return;
    }

    final estoqueProvider = context.read<EstoqueProvider>();

    if (estoqueProvider.itens.isEmpty) {
      await estoqueProvider.carregar();
    }

    if (!mounted) {
      return;
    }

    final disponiveis = estoqueProvider.itens
        .where((item) => item.quantidade > 0)
        .toList();

    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há itens/peças disponíveis no estoque.'),
        ),
      );
      return;
    }

    final dados = await _dialogAdicionarPeca(disponiveis);

    if (dados == null || !mounted) {
      return;
    }

    final servicoProvider = context.read<ServicoProvider>();
    final sucesso = await servicoProvider.adicionarPeca(
      servicoId: servico.id,
      estoqueId: dados.estoqueId,
      quantidade: dados.quantidade,
    );

    if (!mounted) {
      return;
    }

    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            servicoProvider.errorMessage ??
                'Não foi possível adicionar a peça.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await estoqueProvider.carregar();
    await _carregar(mostrarCarregamento: false);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peça adicionada ao serviço.')),
    );
  }

  Future<_DadosNovaPeca?> _dialogAdicionarPeca(List<EstoqueModel> itens) {
    return showDialog<_DadosNovaPeca>(
      context: context,
      builder: (dialogContext) {
        return _AdicionarPecaDialog(itens: itens);
      },
    );
  }

  Future<void> _removerPeca(ServicoModel servico, ServicoPecaModel peca) async {
    if (!_podeAlterarPecas(servico)) {
      return;
    }

    final item = _buscarItemEstoque(
      peca.estoqueId,
      context.read<EstoqueProvider>().itens,
    );
    final nome = peca.estoqueNome ?? item?.nome ?? 'Peça #${peca.estoqueId}';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover peça do serviço'),
          content: Text(
            'Deseja remover "$nome" deste serviço? '
            'A quantidade vinculada será devolvida ao estoque.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Remover',
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

    final servicoProvider = context.read<ServicoProvider>();
    final sucesso = await servicoProvider.removerPeca(
      servicoId: servico.id,
      servicoPecaId: peca.id,
    );

    if (!mounted) {
      return;
    }

    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            servicoProvider.errorMessage ?? 'Não foi possível remover a peça.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final estoqueProvider = context.read<EstoqueProvider>();
    await estoqueProvider.carregar();
    await _carregar(mostrarCarregamento: false);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peça removida e devolvida ao estoque.')),
    );
  }

  Widget _pecasSection(ServicoModel servico, EstoqueProvider estoqueProvider) {
    final podeAlterar = _podeAlterarPecas(servico);
    final quantidadeTotal = servico.pecas.fold<int>(
      0,
      (total, peca) => total + peca.quantidade,
    );

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Itens/Peças utilizados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (podeAlterar)
                IconButton(
                  tooltip: 'Adicionar peça',
                  onPressed: () => _adicionarPeca(servico),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          Text(
            '${servico.pecas.length} registro(s) • '
            '$quantidadeTotal unidade(s)',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (servico.pecas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nenhuma peça foi vinculada a este serviço.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...servico.pecas.map((peca) {
              final itemEstoque = _buscarItemEstoque(
                peca.estoqueId,
                estoqueProvider.itens,
              );
              final nome =
                  peca.estoqueNome ??
                  itemEstoque?.nome ??
                  'Peça #${peca.estoqueId}';
              final quantidadeDisponivel = itemEstoque?.quantidade;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 25,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Utilizada: ${peca.quantidade} unidade(s)',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (quantidadeDisponivel != null)
                            Text(
                              'Restante no estoque: $quantidadeDisponivel',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (podeAlterar)
                      IconButton(
                        tooltip: 'Devolver peça ao estoque',
                        onPressed: () => _removerPeca(servico, peca),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
              );
            }),
          if (!podeAlterar)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'O serviço está encerrado. Os itens vinculados não podem ser alterados.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final estoqueProvider = context.watch<EstoqueProvider>();
    final servicoProvider = context.watch<ServicoProvider>();

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
                        onPressed: () => _carregar(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : _conteudo(_servico!, auth, estoqueProvider),
      ),
    );
  }

  Widget _conteudo(
    ServicoModel servico,
    AuthProvider auth,
    EstoqueProvider estoqueProvider,
  ) {
    final cor = _corStatus(servico.status);
    final equipamentoDetalhe = [
      if (servico.marca?.isNotEmpty == true) servico.marca!,
      if (servico.modelo?.isNotEmpty == true) servico.modelo!,
    ].join(' • ');

    return RefreshIndicator(
      onRefresh: () => _carregar(mostrarCarregamento: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        equipamentoDetalhe.isEmpty
                            ? 'Marca e modelo não informados'
                            : equipamentoDetalhe,
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
                              context.push(
                                '/servicos/${widget.servicoId}/editar',
                              );
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

                _pecasSection(servico, estoqueProvider),

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
                      titulo: 'Itens/Peças vinculados',
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
      ),
    );
  }

  Widget _comunicacaoSection(ServicoModel servico, ServicoProvider provider) {
    final telefoneDisponivel =
        servico.clienteTelefone?.trim().isNotEmpty == true;

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
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Comunicação com o cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Prepare uma atualização e abra o WhatsApp para revisar e enviar a mensagem manualmente.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !telefoneDisponivel || provider.isSaving
                  ? null
                  : _prepararMensagemWhatsApp,
              icon: provider.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chat_outlined),
              label: Text(
                provider.isSaving
                    ? 'Preparando mensagem...'
                    : 'Atualizar cliente pelo WhatsApp',
              ),
            ),
          ),
          if (!telefoneDisponivel) ...[
            const SizedBox(height: 8),
            const Text(
              'Cadastre um telefone para este cliente para habilitar o WhatsApp.',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const Divider(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Histórico de mensagens',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar histórico',
                onPressed: provider.isLoadingNotificacoes
                    ? null
                    : () => provider.carregarNotificacoes(servico.id),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (provider.isLoadingNotificacoes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.notificacaoError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                provider.notificacaoError!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            )
          else if (provider.notificacoes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhuma mensagem foi preparada para este serviço.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ...provider.notificacoes.map(
              (notificacao) => _NotificacaoItem(
                notificacao: notificacao,
                onMarcarEnviada: notificacao.estaPreparada && !provider.isSaving
                    ? () => _marcarNotificacaoComoEnviada(notificacao)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificacaoItem extends StatelessWidget {
  final NotificacaoModel notificacao;
  final VoidCallback? onMarcarEnviada;

  const _NotificacaoItem({
    required this.notificacao,
    required this.onMarcarEnviada,
  });

  @override
  Widget build(BuildContext context) {
    final enviada = notificacao.foiEnviada;
    final cor = enviada ? Colors.green.shade700 : Colors.orange.shade800;
    final data = notificacao.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                enviada ? Icons.check_circle_outline : Icons.schedule,
                color: cor,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  enviada ? 'Enviada' : 'Preparada — envio manual pendente',
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (data != null)
                Text(
                  DateFormat('dd/MM/yy HH:mm').format(data),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notificacao.mensagem,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          if (onMarcarEnviada != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onMarcarEnviada,
                icon: const Icon(Icons.check, size: 17),
                label: const Text('Marcar como enviada'),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
    if (widget.itens.isNotEmpty) {
      _estoqueIdSelecionado = widget.itens.first.id;
    }
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

  void _adicionar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = _itemSelecionado;
    if (item == null) {
      return;
    }

    Navigator.of(context).pop(
      _DadosNovaPeca(
        estoqueId: item.id,
        quantidade: int.parse(_quantidadeController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemSelecionado = _itemSelecionado;

    return AlertDialog(
      title: const Text('Adicionar peça'),
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
                  items: widget.itens.map((item) {
                    return DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(
                        '${item.nome} — disponível: ${item.quantidade}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _estoqueIdSelecionado = value;
                    });
                    _formKey.currentState?.validate();
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma peça.';
                    }
                    return null;
                  },
                ),
                if (itemSelecionado != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Disponível: ${itemSelecionado.quantidade} unidade(s)',
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

                    final item = _itemSelecionado;
                    if (item == null) {
                      return 'Selecione uma peça.';
                    }

                    if (quantidade > item.quantidade) {
                      return 'Saldo disponível: ${item.quantidade}.';
                    }

                    return null;
                  },
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
        ElevatedButton(onPressed: _adicionar, child: const Text('Adicionar')),
      ],
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
