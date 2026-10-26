import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class DashboardHeader extends StatelessWidget {
  final String nome;
  final VoidCallback onPerfil;
  final VoidCallback onSac;
  final VoidCallback onConfiguracoes;

  const DashboardHeader({
    super.key,
    required this.nome,
    required this.onPerfil,
    required this.onSac,
    required this.onConfiguracoes,
  });

  @override
  Widget build(BuildContext context) {
    return BluePatternBackground(
      showTopCircles: true,
      showBottomCircles: false,
      compactTopCircles: true,

      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 45, 28, 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onPerfil,
                  borderRadius: BorderRadius.circular(45),
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE0E0E0),
                      border: Border.all(
                        color: const Color(0xFF999999),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 60,
                      color: Color(0xFF9B9B9B),
                    ),
                  ),
                ),

                const SizedBox(width: 22),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bem vindo,',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                _HeaderButton(icone: Icons.headset_mic_outlined, onTap: onSac),

                const SizedBox(width: 10),

                _HeaderButton(
                  icone: Icons.settings_outlined,
                  onTap: onConfiguracoes,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;

  const _HeaderButton({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkButton,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icone, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
