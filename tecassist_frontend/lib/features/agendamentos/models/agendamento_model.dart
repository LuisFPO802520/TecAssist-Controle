class AgendamentoModel {
  final int id;
  final String descricao;
  final DateTime data;
  final String status;
  final DateTime? createdAt;

  final int clienteId;
  final String clienteNome;
  final String? clienteTelefone;

  const AgendamentoModel({
    required this.id,
    required this.descricao,
    required this.data,
    required this.status,
    required this.clienteId,
    required this.clienteNome,
    this.clienteTelefone,
    this.createdAt,
  });

  bool get isConvertido => status.toUpperCase() == 'CONVERTIDO';

  bool get isCancelado => status.toUpperCase() == 'CANCELADO';

  factory AgendamentoModel.fromJson(Map<String, dynamic> json) {
    final cliente = json['cliente'] as Map<String, dynamic>?;

    return AgendamentoModel(
      id: json['id'] as int,
      descricao: (json['descricao'] ?? '').toString(),
      data: DateTime.parse(json['data'].toString()),
      status: (json['status'] ?? 'AGENDADO').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      clienteId: cliente != null
          ? (cliente['id'] as int)
          : (json['clienteId'] as int),
      clienteNome: cliente != null
          ? (cliente['nome'] ?? 'Cliente').toString()
          : 'Cliente',
      clienteTelefone: cliente != null ? cliente['telefone']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'data': data.toIso8601String(),
      'status': status,
      'clienteId': clienteId,
    };
  }

  AgendamentoModel copyWith({
    int? id,
    String? descricao,
    DateTime? data,
    String? status,
    int? clienteId,
    String? clienteNome,
    String? clienteTelefone,
    DateTime? createdAt,
  }) {
    return AgendamentoModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      data: data ?? this.data,
      status: status ?? this.status,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteTelefone: clienteTelefone ?? this.clienteTelefone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
