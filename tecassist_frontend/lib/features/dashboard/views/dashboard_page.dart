import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../agendamentos/models/agendamento_model.dart';
import '../../agendamentos/providers/agendamento_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../estoque/providers/estoque_provider.dart';
import '../../servicos/models/servico_model.dart';
import '../../servicos/providers/servico_provider.dart';
import 'dashboard_header.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onOpenDrawer;

  const DashboardPage({super.key, required this.onOpenDrawer});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inicializarDashboard();
      }
    });
  }

  Future<void> _inicializarDashboard() async {
    await Future.wait<void>([_carregarDados(), _sincronizarPerfil()]);
  }

  Future<void> _sincronizarPerfil() async {
    try {
      await context.read<AuthProvider>().recarregarPerfil();
    } catch (_) {}
  }

  Future<void> _carregarDados({bool forcar = false}) async {
    if (!mounted) return;

    final agendamentos = context.read<AgendamentoProvider>();
    final servicos = context.read<ServicoProvider>();
    final estoque = context.read<EstoqueProvider>();

    final tarefas = <Future<void>>[];

    if (forcar || !agendamentos.jaCarregou) {
      tarefas.add(agendamentos.carregar());
    }

    if (forcar || !servicos.jaCarregou) {
      tarefas.add(servicos.carregar());
    }

    if (forcar || !estoque.jaCarregou) {
      tarefas.add(estoque.carregar());
    }

    if (tarefas.isNotEmpty) {
      await Future.wait(tarefas);
    }
  }

  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _mesmoMes(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _mesmoAno(DateTime a, DateTime b) {
    return a.year == b.year;
  }

  int _contarAgendamentos(
    List<AgendamentoModel> lista,
    DateTime agora,
    bool Function(DateTime, DateTime) periodo,
  ) {
    return lista.where((item) {
      if (item.status.toUpperCase() == 'CANCELADO') {
        return false;
      }

      return periodo(item.data.toLocal(), agora);
    }).length;
  }

  int _contarServicosAtivos(
    List<ServicoModel> lista,
    DateTime agora,
    bool Function(DateTime, DateTime) periodo,
  ) {
    const statusAtivos = {'ABERTO', 'EM_ANDAMENTO', 'AGUARDANDO_PECA'};

    return lista.where((item) {
      final data = item.createdAt;

      if (data == null || !statusAtivos.contains(item.status.toUpperCase())) {
        return false;
      }

      return periodo(data.toLocal(), agora);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final agendaProvider = context.watch<AgendamentoProvider>();
    final servicoProvider = context.watch<ServicoProvider>();
    final estoqueProvider = context.watch<EstoqueProvider>();

    final agora = DateTime.now();
    final primeiroNome = (auth.usuario?.nome ?? 'Usuário').split(' ').first;

    final atendimentos = agendaProvider.agendamentos;
    final servicos = servicoProvider.servicos;
    final itensEstoque = estoqueProvider.itens;

    final mediaEstoque = itensEstoque.isEmpty
        ? 0.0
        : itensEstoque.fold<int>(0, (total, item) => total + item.quantidade) /
              itensEstoque.length;

    final mediaFormatada = mediaEstoque.toStringAsFixed(1).replaceAll('.', ',');

    final dataHoje = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(agora);

    final algumCarregando =
        agendaProvider.isLoading ||
        servicoProvider.isLoading ||
        estoqueProvider.isLoading;

    final erros = [
      agendaProvider.errorMessage,
      servicoProvider.errorMessage,
      estoqueProvider.errorMessage,
    ].where((mensagem) => mensagem != null).toList();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: RefreshIndicator(
        onRefresh: () => _carregarDados(forcar: true),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: DashboardHeader(
                nome: primeiroNome,
                fotoPerfil: auth.usuario?.fotoPerfil,
                onPerfil: widget.onOpenDrawer,
                onSac: () {
                  context.push('/sac');
                },
                onConfiguracoes: () {
                  context.push('/configuracoes');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: ClipPath(
                clipper: SmoothClipper(),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Visão geral',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dataHoje,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (algumCarregando)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: 'Atualizar informações',
                                  onPressed: () => _carregarDados(forcar: true),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _DashboardSection(
                            titulo: 'Atendimentos',
                            subtitulo: 'Agendamentos registrados',
                            icone: Icons.event_note_outlined,
                            metricas: [
                              _DashboardMetric(
                                titulo: 'Hoje',
                                valor:
                                    '${_contarAgendamentos(atendimentos, agora, _mesmaData)}',
                              ),
                              _DashboardMetric(
                                titulo: 'Este mês',
                                valor:
                                    '${_contarAgendamentos(atendimentos, agora, _mesmoMes)}',
                              ),
                              _DashboardMetric(
                                titulo: 'Este ano',
                                valor:
                                    '${_contarAgendamentos(atendimentos, agora, _mesmoAno)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _DashboardSection(
                            titulo: 'Em andamento',
                            subtitulo: 'Serviços ainda não encerrados',
                            icone: Icons.handyman_outlined,
                            metricas: [
                              _DashboardMetric(
                                titulo: 'Hoje',
                                valor:
                                    '${_contarServicosAtivos(servicos, agora, _mesmaData)}',
                              ),
                              _DashboardMetric(
                                titulo: 'Este mês',
                                valor:
                                    '${_contarServicosAtivos(servicos, agora, _mesmoMes)}',
                              ),
                              _DashboardMetric(
                                titulo: 'Este ano',
                                valor:
                                    '${_contarServicosAtivos(servicos, agora, _mesmoAno)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _DashboardSection(
                            titulo: 'Estoque',
                            subtitulo: 'Situação atual das peças',
                            icone: Icons.inventory_2_outlined,
                            metricas: [
                              _DashboardMetric(
                                titulo: 'Em falta',
                                valor:
                                    '${itensEstoque.where((item) => item.quantidade <= 0).length}',
                              ),
                              _DashboardMetric(
                                titulo: 'Média',
                                valor: mediaFormatada,
                                complemento: 'unidades por peça',
                              ),
                            ],
                          ),
                          if (erros.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF8A6415),
                                    size: 19,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Algumas informações não puderam ser atualizadas. Puxe a tela para baixo ou use o botão de atualizar.',
                                      style: TextStyle(
                                        color: Color(0xFF765A1C),
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMetric {
  final String titulo;
  final String valor;
  final String? complemento;

  const _DashboardMetric({
    required this.titulo,
    required this.valor,
    this.complemento,
  });
}

class _DashboardSection extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final List<_DashboardMetric> metricas;

  const _DashboardSection({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.metricas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: AppColors.primary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < metricas.length; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                Expanded(child: _DashboardMetricTile(metrica: metricas[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricTile extends StatelessWidget {
  final _DashboardMetric metrica;

  const _DashboardMetricTile({required this.metrica});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metrica.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metrica.valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (metrica.complemento != null) ...[
            const SizedBox(height: 2),
            Text(
              metrica.complemento!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SmoothClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const larguraCurva = 50.0;
    const alturaCurva = 50.0;

    path.moveTo(0, size.height);
    path.lineTo(0, alturaCurva);
    path.quadraticBezierTo(0, 0, larguraCurva, 0);
    path.lineTo(size.width - larguraCurva, 0);
    path.quadraticBezierTo(size.width, 0, size.width, alturaCurva);
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
