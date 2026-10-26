import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/cliente_model.dart';

class ClientesCardsView extends StatelessWidget {
  final List<ClienteModel> clientes;

  final bool podeExcluir;

  final void Function(ClienteModel cliente) onAbrir;

  final void Function(ClienteModel cliente) onEditar;

  final void Function(ClienteModel cliente) onExcluir;

  const ClientesCardsView({
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
        return const SizedBox(height: 12);
      },

      itemBuilder: (context, index) {
        final cliente = clientes[index];

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),

          child: InkWell(
            borderRadius: BorderRadius.circular(12),

            onTap: () {
              onAbrir(cliente);
            },

            child: Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE7EDF7),
                        child: Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente.nome,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              cliente.observacoes?.trim().isNotEmpty == true
                                  ? cliente.observacoes!
                                  : 'Sem observações',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
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

                  const SizedBox(height: 16),

                  const Divider(height: 1),

                  const SizedBox(height: 14),

                  _ClienteInformacao(
                    icone: Icons.phone_outlined,
                    valor: cliente.telefone,
                  ),

                  if (cliente.email != null && cliente.email!.isNotEmpty)
                    _ClienteInformacao(
                      icone: Icons.email_outlined,
                      valor: cliente.email!,
                    ),

                  if (cliente.endereco != null && cliente.endereco!.isNotEmpty)
                    _ClienteInformacao(
                      icone: Icons.location_on_outlined,
                      valor: cliente.endereco!,
                    ),

                  if (cliente.quantidadeServicos != null)
                    _ClienteInformacao(
                      icone: Icons.construction_outlined,
                      valor: 'Serviços: ${cliente.quantidadeServicos}',
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

class _ClienteInformacao extends StatelessWidget {
  final IconData icone;
  final String valor;

  const _ClienteInformacao({required this.icone, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icone, size: 21, color: AppColors.textSecondary),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
