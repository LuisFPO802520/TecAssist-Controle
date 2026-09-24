class UsuarioModel {
  final int id;
  final String nome;
  final String email;
  final String tipo;
  final String? telefone;
  final bool? ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.telefone,
    this.ativo,
    this.createdAt,
    this.updatedAt,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      tipo: json['tipo'] ?? '',
      telefone: json['telefone'],
      ativo: json['ativo'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'telefone': telefone,
      'ativo': ativo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isAdmin => tipo == 'ADMIN';

  bool get isFuncionario => tipo == 'FUNCIONARIO';
}
