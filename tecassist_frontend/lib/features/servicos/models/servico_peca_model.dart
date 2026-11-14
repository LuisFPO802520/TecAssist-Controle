class ServicoPecaModel {
  final int id;
  final int servicoId;
  final int estoqueId;
  final int quantidade;
  final DateTime? createdAt;
  final String? estoqueNome;
  final double? valorUnitario;

  const ServicoPecaModel({
    required this.id,
    required this.servicoId,
    required this.estoqueId,
    required this.quantidade,
    this.createdAt,
    this.estoqueNome,
    this.valorUnitario,
  });

  factory ServicoPecaModel.fromJson(Map<String, dynamic> json) {
    final estoqueRaw = json['estoque'];

    final Map<String, dynamic>? estoque = estoqueRaw is Map
        ? Map<String, dynamic>.from(estoqueRaw)
        : null;

    final valor = estoque?['valor'];

    return ServicoPecaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      servicoId: (json['servicoId'] as num?)?.toInt() ?? 0,
      estoqueId:
          (json['estoqueId'] as num?)?.toInt() ??
          (estoque?['id'] as num?)?.toInt() ??
          0,
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      estoqueNome: estoque?['nome']?.toString(),
      valorUnitario: valor is num
          ? valor.toDouble()
          : double.tryParse(valor?.toString() ?? ''),
    );
  }
}
