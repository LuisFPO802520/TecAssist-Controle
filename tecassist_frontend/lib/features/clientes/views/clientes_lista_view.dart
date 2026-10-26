import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/cliente_model.dart';

class ClientesListaView extends StatelessWidget {
  final List<ClienteModel> clientes;

  final bool podeExcluir;

  final void Function(ClienteModel cliente) onAbrir;

  final void Function(ClienteModel cliente) onEditar;

  final void Function(ClienteModel cliente) onExcluir;

  const ClientesListaView({
    super.key,
    required this.clientes,
    required this.podeExcluir,
    required this.onAbrir,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      itemCount: clientes.length,

      separatorBuilder: (context, index) {
        return const SizedBox(height: 8);
      },

      itemBuilder: (context, index) {
        final cliente = clientes[index];

        return Material(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(10),

          child: InkWell(
            borderRadius: BorderRadius.circular(10),

            onTap: () {
              onAbrir(cliente);
            },

            child: Container(
              constraints: const BoxConstraints(minHeight: 70),

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 27,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cliente.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        if (cliente.telefone.isNotEmpty) ...[
                          const SizedBox(height: 3),

                          Text(
                            cliente.telefone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () {
                      onEditar(cliente);
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                  ),

                  if (podeExcluir)
                    IconButton(
                      tooltip: 'Excluir',
                      onPressed: () {
                        onExcluir(cliente);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
