class ClienteModel {
  final int id;
  final String nome;
  final String telefone;
  final String? email;
  final String? endereco;
  final String? cpf;
  final String? observacoes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int? quantidadeServicos;

  ClienteModel({
    required this.id,
    required this.nome,
    required this.telefone,
    this.email,
    this.endereco,
    this.cpf,
    this.observacoes,
    this.createdAt,
    this.updatedAt,
    this.quantidadeServicos,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    int? quantidadeServicos;

    if (json['_count'] != null &&
        json['_count'] is Map &&
        json['_count']['servicos'] != null) {
      quantidadeServicos = json['_count']['servicos'];
    }

    if (json['servicos'] is List) {
      quantidadeServicos = (json['servicos'] as List).length;
    }

    return ClienteModel(
      id: json['id'],
      nome: json['nome'] ?? '',
      telefone: json['telefone'] ?? '',
      email: json['email'],
      endereco: json['endereco'],
      cpf: json['cpf'],
      observacoes: json['observacoes'],

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,

      quantidadeServicos: quantidadeServicos,
    );
  }
}
