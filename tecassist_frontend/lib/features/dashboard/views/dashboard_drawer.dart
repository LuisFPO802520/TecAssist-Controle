import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    await auth.logout();

    if (context.mounted) {
      context.go('/');
    }
  }

  void _navegar(BuildContext context, String rota) {
    Navigator.pop(context);

    context.go(rota);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final usuario = auth.usuario;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.76,

      backgroundColor: Colors.white,

      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 260,
              color: AppColors.drawerHeader,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(
                      Icons.person_outline,
                      size: 65,
                      color: Color(0xFF999999),
                    ),
                  ),

                  const SizedBox(width: 25),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario?.nome ?? 'Usuário',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          usuario?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          'Editar informações',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 22,
                ),
                child: Column(
                  children: [
                    if (auth.isAdmin)
                      _DrawerItem(
                        icone: Icons.manage_accounts_outlined,
                        titulo: 'Gerenciar usuários',
                        onTap: () {
                          _navegar(context, '/usuarios');
                        },
                      ),

                    if (auth.isAdmin)
                      _DrawerItem(
                        icone: Icons.lock_clock,
                        titulo: 'Código de cadastro',
                        onTap: () {
                          _navegar(context, '/codigo-cadastro');
                        },
                      ),

                    _DrawerItem(
                      icone: Icons.people_outline,
                      titulo: 'Clientes',
                      onTap: () {
                        _navegar(context, '/app/clientes');
                      },
                    ),

                    _DrawerItem(
                      icone: Icons.calendar_month_outlined,
                      titulo: 'Agenda',
                      onTap: () {
                        _navegar(context, '/app/agendamentos');
                      },
                    ),

                    _DrawerItem(
                      icone: Icons.construction_outlined,
                      titulo: 'Serviços',
                      onTap: () {
                        _navegar(context, '/app/servicos');
                      },
                    ),

                    _DrawerItem(
                      icone: Icons.inventory_2_outlined,
                      titulo: 'Estoque',
                      onTap: () {
                        _navegar(context, '/app/estoque');
                      },
                    ),

                    _DrawerItem(
                      icone: Icons.settings_outlined,
                      titulo: 'Configurações',
                      onTap: () {
                        _navegar(context, '/configuracoes');
                      },
                    ),

                    _DrawerItem(
                      icone: Icons.headset_mic_outlined,
                      titulo: 'SAC',
                      onTap: () {
                        _navegar(context, '/sac');
                      },
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _logout(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.black),
                  label: const Text(
                    'Sair',
                    style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E8E8E),
                    foregroundColor: Colors.white,
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

class _DrawerItem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icone,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: Icon(icone, color: AppColors.primary, size: 31),
          title: Text(
            titulo,
            style: const TextStyle(color: AppColors.primary, fontSize: 19),
          ),
          onTap: onTap,
        ),

        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
