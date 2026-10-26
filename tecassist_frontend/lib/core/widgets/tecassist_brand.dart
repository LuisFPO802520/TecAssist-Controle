import 'package:flutter/material.dart';

class TecAssistBrand extends StatelessWidget {
  const TecAssistBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,

          child: Image.asset(
            'assets/images/tecassist_logo.png',

            fit: BoxFit.contain,

            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.build_circle,
                color: Colors.white,
                size: 58,
              );
            },
          ),
        ),

        const SizedBox(width: 12),

        const Text(
          'TecAssist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
