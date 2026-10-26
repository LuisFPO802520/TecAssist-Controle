import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/agendamento_provider.dart';

class AgendamentosCalendarioView extends StatelessWidget {
  final AgendamentoProvider provider;
  final void Function(int agendamentoId)? onExcluir;
  final void Function(int agendamentoId)? onEditar;

  final void Function(int agendamentoId)? onConverter;

  const AgendamentosCalendarioView({
    super.key,
    required this.provider,
    this.onEditar,
    this.onConverter,
    this.onExcluir,
  });

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AGENDADO':
        return Colors.blue;
      case 'CONVERTIDO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      case 'CONCLUIDO':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dias = provider.diasDaSemana;
    final selecionada = provider.dataSelecionada;
    final agendamentosDoDia = provider.agendamentosDoDia;

    final mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(selecionada);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mesAno,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: provider.semanaAnterior,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: provider.proximaSemana,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: dias.map((dia) {
                  final selecionado =
                      dia.year == selecionada.year &&
                      dia.month == selecionada.month &&
                      dia.day == selecionada.day;

                  final quantidade = provider.totalNoDia(dia);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        provider.setDataSelecionada(dia);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selecionado
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE', 'pt_BR').format(dia),
                              style: TextStyle(
                                color: selecionado
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: selecionado
                                  ? Colors.white
                                  : Colors.transparent,
                              child: Text(
                                '${dia.day}',
                                style: TextStyle(
                                  color: selecionado
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$quantidade',
                              style: TextStyle(
                                color: selecionado
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (agendamentosDoDia.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 46,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 12),
                Text(
                  'Nenhum agendamento para a data selecionada.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: agendamentosDoDia.map((agendamento) {
              final cor = _statusColor(agendamento.status);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 74,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 10,
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('HH:mm').format(agendamento.data),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                agendamento.status,
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(
                            right: 12,
                            top: 12,
                            bottom: 12,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cor.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      agendamento.clienteNome,
                                      style: TextStyle(
                                        color: cor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'editar':
                                          onEditar?.call(agendamento.id);
                                          break;

                                        case 'converter':
                                          onConverter?.call(agendamento.id);
                                          break;

                                        case 'excluir':
                                          onExcluir?.call(agendamento.id);
                                          break;
                                      }
                                    },

                                    itemBuilder: (context) {
                                      return [
                                        const PopupMenuItem(
                                          value: 'editar',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined),
                                              SizedBox(width: 10),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),

                                        if (agendamento.status.toUpperCase() ==
                                            'AGENDADO')
                                          const PopupMenuItem(
                                            value: 'converter',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.construction_outlined,
                                                ),
                                                SizedBox(width: 10),
                                                Text('Converter em serviço'),
                                              ],
                                            ),
                                          ),

                                        const PopupMenuDivider(),

                                        const PopupMenuItem(
                                          value: 'excluir',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Excluir',
                                                style: TextStyle(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                agendamento.descricao,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (agendamento.clienteTelefone != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      agendamento.clienteTelefone!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
