import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/agendamento_model.dart';

class AgendamentosListaView extends StatelessWidget {
  final List<AgendamentoModel> agendamentos;
  final void Function(int agendamentoId)? onExcluir;
  final void Function(int agendamentoId)? onEditar;
  final void Function(int agendamentoId)? onConverter;

  const AgendamentosListaView({
    super.key,
    required this.agendamentos,
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
    if (agendamentos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 46,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text('Nenhum agendamento encontrado.', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: agendamentos.map((agendamento) {
        final statusColor = _statusColor(agendamento.status);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                agendamento.clienteNome,
                                style: const TextStyle(
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
                                          Icon(Icons.construction_outlined),
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
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          children: [
                            _InfoText(
                              icon: Icons.calendar_today,
                              text: DateFormat(
                                'dd/MM/yyyy',
                              ).format(agendamento.data),
                            ),
                            _InfoText(
                              icon: Icons.access_time,
                              text: DateFormat(
                                'HH:mm',
                              ).format(agendamento.data),
                            ),
                            if (agendamento.clienteTelefone != null)
                              _InfoText(
                                icon: Icons.phone_outlined,
                                text: agendamento.clienteTelefone!,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            agendamento.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
