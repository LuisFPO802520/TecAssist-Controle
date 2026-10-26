import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ConfiguracaoCodigoCard extends StatelessWidget {
  final int limiteUsos;
  final bool gerando;

  final VoidCallback onDiminuir;
  final VoidCallback onAumentar;
  final VoidCallback onGerar;

  const ConfiguracaoCodigoCard({
    super.key,
    required this.limiteUsos,
    required this.gerando,
    required this.onDiminuir,
    required this.onAumentar,
    required this.onGerar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 600;

          final quantidade = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quantidade de usos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Escolha quantos funcionários poderão utilizar o código.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuantidadeButton(icon: Icons.remove, onPressed: onDiminuir),

                  Container(
                    width: 70,
                    height: 45,
                    alignment: Alignment.center,
                    child: Text(
                      '$limiteUsos',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  _QuantidadeButton(icon: Icons.add, onPressed: onAumentar),
                ],
              ),
            ],
          );

          final botao = SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: gerando ? null : onGerar,
              icon: gerando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.password_outlined),
              label: Text(gerando ? 'Gerando...' : 'Gerar código'),
            ),
          );

          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [quantidade, const SizedBox(height: 20), botao],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: quantidade),

              const SizedBox(width: 30),

              botao,
            ],
          );
        },
      ),
    );
  }
}

class _QuantidadeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantidadeButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class CodigoAtualCard extends StatelessWidget {
  final String codigo;

  final int limiteUsos;
  final int usos;
  final int usosRestantes;
  final int segundosRestantes;

  final VoidCallback onAtualizar;

  const CodigoAtualCard({
    super.key,
    required this.codigo,
    required this.limiteUsos,
    required this.usos,
    required this.usosRestantes,
    required this.segundosRestantes,
    required this.onAtualizar,
  });

  @override
  Widget build(BuildContext context) {
    final codigoFormatado = codigo.length == 6
        ? '${codigo.substring(0, 3)} ${codigo.substring(3)}'
        : codigo;

    final progressoUsos = limiteUsos > 0
        ? (usos / limiteUsos).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final progressoTempo = (segundosRestantes / 60).clamp(0.0, 1.0).toDouble();

    final limiteAtingido = usosRestantes <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'Código ativo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Atualizar',
                onPressed: onAtualizar,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
              ),
            ],
          ),

          const SizedBox(height: 28),

          SelectableText(
            codigoFormatado,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: 7,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 10),

          if (limiteAtingido)
            const Text(
              'Limite de usos atingido',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'Expira em $segundosRestantes segundos',
              style: const TextStyle(color: AppColors.textSecondary),
            ),

          const SizedBox(height: 22),

          LinearProgressIndicator(
            value: progressoTempo,
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
          ),

          const SizedBox(height: 28),

          const Divider(color: AppColors.border),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _InfoCodigo(
                  titulo: 'Usos',
                  valor: '$usos de $limiteUsos',
                ),
              ),

              Expanded(
                child: _InfoCodigo(
                  titulo: 'Restantes',
                  valor: '$usosRestantes',
                ),
              ),

              Expanded(
                child: _InfoCodigo(
                  titulo: 'Validade',
                  valor: '${segundosRestantes}s',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LinearProgressIndicator(
            value: progressoUsos,
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }
}

class _InfoCodigo extends StatelessWidget {
  final String titulo;
  final String valor;

  const _InfoCodigo({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class SemCodigoCard extends StatelessWidget {
  const SemCodigoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.password_outlined,
            size: 55,
            color: AppColors.textSecondary,
          ),

          SizedBox(height: 12),

          Text(
            'Nenhum código ativo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Escolha a quantidade de usos e gere um novo código.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
