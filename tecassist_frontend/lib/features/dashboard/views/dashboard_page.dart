import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Deseja realmente sair do sistema?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();

    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final nomeUsuario = auth.usuario?.nome ?? 'Usuário';

    final primeiroNome = nomeUsuario.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TecAssist',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Gestão de Assistência Técnica',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(primeiroNome, style: const TextStyle(fontSize: 14)),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, size: 30),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.usuario?.nome ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.usuario?.email ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.usuario?.tipo ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text('Sair'),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, $primeiroNome!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Acompanhe os atendimentos da assistência técnica.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  /*
                   * Por enquanto os valores são 0.
                   *
                   * Depois iremos criar:
                   * DashboardService
                   * DashboardProvider
                   *
                   * para buscar esses números
                   * diretamente do backend.
                   */
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final desktop = constraints.maxWidth >= 750;

                      if (desktop) {
                        return const Row(
                          children: [
                            Expanded(
                              child: _DashboardInfoCard(
                                titulo: 'Total de atendimentos',
                                valor: '0',
                                icone: Icons.assignment_outlined,
                                cor: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: _DashboardInfoCard(
                                titulo: 'Em andamento',
                                valor: '0',
                                icone: Icons.engineering_outlined,
                                cor: AppColors.warning,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: _DashboardInfoCard(
                                titulo: 'Estoque baixo',
                                valor: '0',
                                icone: Icons.inventory_2_outlined,
                                cor: AppColors.error,
                              ),
                            ),
                          ],
                        );
                      }

                      return const Column(
                        children: [
                          _DashboardInfoCard(
                            titulo: 'Total de atendimentos',
                            valor: '0',
                            icone: Icons.assignment_outlined,
                            cor: AppColors.primary,
                          ),
                          SizedBox(height: 12),
                          _DashboardInfoCard(
                            titulo: 'Em andamento',
                            valor: '0',
                            icone: Icons.engineering_outlined,
                            cor: AppColors.warning,
                          ),
                          SizedBox(height: 12),
                          _DashboardInfoCard(
                            titulo: 'Estoque baixo',
                            valor: '0',
                            icone: Icons.inventory_2_outlined,
                            cor: AppColors.error,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Acesso rápido',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      int colunas = 2;

                      if (constraints.maxWidth >= 900) {
                        colunas = 4;
                      }

                      return GridView.count(
                        crossAxisCount: colunas,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.35,
                        children: [
                          _DashboardActionCard(
                            titulo: 'Clientes',
                            icone: Icons.people_outline,
                            onTap: () {
                              context.go('/clientes');
                            },
                          ),
                          _DashboardActionCard(
                            titulo: 'Agenda',
                            icone: Icons.calendar_month_outlined,
                            onTap: () {
                              context.go('/agendamentos');
                            },
                          ),
                          _DashboardActionCard(
                            titulo: 'Serviços',
                            icone: Icons.construction_outlined,
                            onTap: () {
                              context.go('/servicos');
                            },
                          ),
                          _DashboardActionCard(
                            titulo: 'Estoque',
                            icone: Icons.inventory_2_outlined,
                            onTap: () {
                              context.go('/estoque');
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  if (auth.isAdmin) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Administração',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 250,
                      child: _DashboardActionCard(
                        titulo: 'Gerenciar Usuários',
                        icone: Icons.manage_accounts_outlined,
                        onTap: () {
                          context.go('/usuarios');
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
 * Card de informações do Dashboard.
 *
 * É privado porque somente o Dashboard
 * utiliza este componente.
 */
class _DashboardInfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _DashboardInfoCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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

/*
 * Ação rápida do Dashboard.
 *
 * Também fica neste arquivo porque
 * é utilizada somente pelo Dashboard.
 */
class _DashboardActionCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.titulo,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icone, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
