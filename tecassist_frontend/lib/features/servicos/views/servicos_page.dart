import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/blue_pattern_background.dart';

class ServicosPage extends StatelessWidget {
  const ServicosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 85,
        automaticallyImplyLeading: false,

        surfaceTintColor: Colors.transparent,
        elevation: 0,

        flexibleSpace: BluePatternBackground(
          showTopCircles: true,
          showBottomCircles: false,

          compactTopCircles: true,

          child: const SizedBox.expand(),
        ),

        title: const SizedBox(
          height: 60,
          width: double.infinity,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              'Serviços',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Módulo de Serviços',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
