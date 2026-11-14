class MovimentacaoEstoqueModel {
  final int id;
  final String tipo;
  final int quantidade;
  final DateTime? createdAt;
  final int estoqueId;
  final String? estoqueNome;

  const MovimentacaoEstoqueModel({
    required this.id,
    required this.tipo,
    required this.quantidade,
    required this.estoqueId,
    this.createdAt,
    this.estoqueNome,
  });

  factory MovimentacaoEstoqueModel.fromJson(Map<String, dynamic> json) {
    final estoque = json['estoque'];

    return MovimentacaoEstoqueModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipo: json['tipo']?.toString() ?? 'OUTRO',
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      estoqueId:
          (json['estoqueId'] as num?)?.toInt() ??
          (estoque is Map ? (estoque['id'] as num?)?.toInt() ?? 0 : 0),
      estoqueNome: estoque is Map ? estoque['nome']?.toString() : null,
    );
  }

  String get tipoLabel {
    switch (tipo.toUpperCase()) {
      case 'ENTRADA':
        return 'Entrada';
      case 'SAIDA':
      case 'SAÍDA':
        return 'Saída';
      default:
        return tipo.replaceAll('_', ' ');
    }
  }

  bool get ehEntrada => tipo.toUpperCase() == 'ENTRADA';
}
