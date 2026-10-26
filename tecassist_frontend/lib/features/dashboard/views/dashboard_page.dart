import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'dashboard_header.dart';

class DashboardPage extends StatelessWidget {
  final VoidCallback onOpenDrawer;

  const DashboardPage({super.key, required this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final primeiroNome = (auth.usuario?.nome ?? 'Usuário').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.primary,

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHeader(
              nome: primeiroNome,

              onPerfil: onOpenDrawer,

              onSac: () {
                context.go('/sac');
              },

              onConfiguracoes: () {
                context.go('/configuracoes');
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, 0),
              child: ClipPath(
                clipper: SmoothClipper(),

                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),

                  decoration: const BoxDecoration(color: Colors.white),

                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DashboardSection(
                        titulo: 'Atendimentos',
                        linhas: [
                          _DashboardRow(texto: 'Hoje', valor: '0'),
                          _DashboardRow(texto: 'Este mês', valor: '0'),
                          _DashboardRow(texto: 'Este ano', valor: '0'),
                        ],
                      ),

                      SizedBox(height: 50),

                      _DashboardSection(
                        titulo: 'Em andamento',
                        linhas: [
                          _DashboardRow(texto: 'Hoje', valor: '0'),
                          _DashboardRow(texto: 'Este mês', valor: '0'),
                          _DashboardRow(texto: 'Este ano', valor: '0'),
                        ],
                      ),

                      SizedBox(height: 50),

                      _DashboardSection(
                        titulo: 'Estoque',
                        linhas: [
                          _DashboardRow(texto: 'Em falta', valor: '0'),
                          _DashboardRow(texto: 'Média', valor: '0'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String titulo;
  final List<_DashboardRow> linhas;

  const _DashboardSection({required this.titulo, required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 10),

        const Divider(),

        const SizedBox(height: 5),

        ...linhas,
      ],
    );
  }
}

class _DashboardRow extends StatelessWidget {
  final String texto;
  final String valor;

  const _DashboardRow({required this.texto, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            texto,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),

          Text(
            valor,
            style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class SmoothClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    double larguraCurva = 50;
    double alturaCurva = 50;

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
