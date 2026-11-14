class EstoqueModel {
  final int id;
  final String nome;
  final String descricao;
  final int quantidade;
  final double valor;
  final String? fornecedor;
  final DateTime? dataCadastro;

  const EstoqueModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.quantidade,
    required this.valor,
    this.fornecedor,
    this.dataCadastro,
  });

  bool get semEstoque => quantidade <= 0;

  bool get estoqueBaixo => quantidade > 0 && quantidade <= 5;

  factory EstoqueModel.fromJson(Map<String, dynamic> json) {
    return EstoqueModel(
      id: (json['id'] as num).toInt(),
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
      valor: double.tryParse(json['valor']?.toString() ?? '') ?? 0.0,
      fornecedor: json['fornecedor']?.toString(),
      dataCadastro: DateTime.tryParse(
        (json['dataCadastro'] ?? json['createdAt'] ?? '').toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'quantidade': quantidade,
      'valor': valor,
      'fornecedor': fornecedor,
      'dataCadastro': dataCadastro?.toIso8601String(),
    };
  }
}
