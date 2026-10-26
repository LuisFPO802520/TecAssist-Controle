import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNavigation({super.key, this.currentIndex = -1, this.onTap});

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    switch (index) {
      case 0:
        context.go('/app/home');
        break;

      case 1:
        context.go('/app/clientes');
        break;

      case 2:
        context.go('/app/agenda');
        break;

      case 3:
        context.go('/app/servicos');
        break;

      case 4:
        context.go('/app/estoque');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const itens = [
      Icons.home_rounded,

      Icons.people_outline,

      Icons.calendar_month_outlined,

      Icons.construction_outlined,

      Icons.inventory_2_outlined,
    ];

    return Container(
      height: 72,
      color: AppColors.navigationBackground,
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(itens.length, (index) {
            final selecionado = currentIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () {
                  _handleTap(context, index);
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      itens[index],
                      size: selecionado ? 32 : 29,
                      color: selecionado
                          ? AppColors.primary
                          : const Color(0xFF858585),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
