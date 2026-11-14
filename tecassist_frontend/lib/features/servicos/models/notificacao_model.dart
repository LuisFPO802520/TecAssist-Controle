class NotificacaoModel {
  final int id;
  final String mensagem;
  final String status;
  final String tipo;
  final int clienteId;
  final int? servicoId;
  final DateTime? createdAt;

  const NotificacaoModel({
    required this.id,
    required this.mensagem,
    required this.status,
    required this.tipo,
    required this.clienteId,
    this.servicoId,
    this.createdAt,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mensagem: json['mensagem']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PREPARADA',
      tipo: json['tipo']?.toString() ?? 'WHATSAPP',
      clienteId: (json['clienteId'] as num?)?.toInt() ?? 0,
      servicoId: (json['servicoId'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get foiEnviada => status.toUpperCase() == 'ENVIADA';
  bool get estaPreparada => status.toUpperCase() == 'PREPARADA';
}

class PreparacaoWhatsApp {
  final NotificacaoModel notificacao;
  final String telefone;
  final String nomeCliente;

  const PreparacaoWhatsApp({
    required this.notificacao,
    required this.telefone,
    required this.nomeCliente,
  });
}
