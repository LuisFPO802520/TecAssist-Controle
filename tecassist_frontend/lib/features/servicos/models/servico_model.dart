const servicoStatusDisponiveis = <String>[
  'ABERTO',
  'EM_ANDAMENTO',
  'AGUARDANDO_PECA',
  'CONCLUIDO',
  'ENTREGUE',
  'CANCELADO',
];

String servicoStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'ABERTO':
      return 'Aberto';
    case 'EM_ANDAMENTO':
      return 'Em andamento';
    case 'AGUARDANDO_PECA':
      return 'Aguardando peça';
    case 'CONCLUIDO':
      return 'Concluído';
    case 'ENTREGUE':
      return 'Entregue';
    case 'CANCELADO':
      return 'Cancelado';
    default:
      return status.replaceAll('_', ' ');
  }
}

Map<String, dynamic>? _mapa(dynamic valor) {
  if (valor is Map) {
    return Map<String, dynamic>.from(valor);
  }

  return null;
}

DateTime? _dataServico(dynamic valor) {
  if (valor == null) {
    return null;
  }

  return DateTime.tryParse(valor.toString());
}

double? _valorServico(dynamic valor) {
  if (valor is num) {
    return valor.toDouble();
  }

  if (valor is String) {
    return double.tryParse(valor.replaceAll(',', '.'));
  }

  return null;
}

class ServicoModel {
  final int id;
  final String? codigo;

  final String equipamento;
  final String? marca;
  final String? modelo;

  final String? problema;
  final String? diagnostico;
  final String? solucao;

  final String status;
  final double? valor;

  final DateTime? createdAt;
  final DateTime? finishedAt;

  final int clienteId;
  final String clienteNome;
  final String? clienteTelefone;

  final int usuarioId;
  final String usuarioNome;

  final int? agendamentoId;
  final int quantidadePecas;

  const ServicoModel({
    required this.id,
    this.codigo,
    required this.equipamento,
    this.marca,
    this.modelo,
    this.problema,
    this.diagnostico,
    this.solucao,
    required this.status,
    this.valor,
    this.createdAt,
    this.finishedAt,
    required this.clienteId,
    required this.clienteNome,
    this.clienteTelefone,
    required this.usuarioId,
    required this.usuarioNome,
    this.agendamentoId,
    this.quantidadePecas = 0,
  });

  factory ServicoModel.fromJson(Map<String, dynamic> json) {
    final cliente = _mapa(json['cliente']);
    final usuario = _mapa(json['usuario']);

    final id = (json['id'] as num?)?.toInt() ?? 0;

    final clienteId =
        (json['clienteId'] as num?)?.toInt() ??
        (cliente?['id'] as num?)?.toInt() ??
        0;

    final usuarioId =
        (json['usuarioId'] as num?)?.toInt() ??
        (usuario?['id'] as num?)?.toInt() ??
        0;

    final pecas = json['pecas'];

    return ServicoModel(
      id: id,
      codigo: json['codigo']?.toString(),

      equipamento: json['equipamento']?.toString() ?? '',

      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),

      problema: json['problema']?.toString(),
      diagnostico: json['diagnostico']?.toString(),
      solucao: json['solucao']?.toString(),

      status: json['status']?.toString() ?? 'ABERTO',

      valor: _valorServico(json['valor']),

      createdAt: _dataServico(json['createdAt']),
      finishedAt: _dataServico(json['finishedAt']),

      clienteId: clienteId,

      clienteNome: cliente?['nome']?.toString() ?? 'Cliente não informado',

      clienteTelefone: cliente?['telefone']?.toString(),

      usuarioId: usuarioId,

      usuarioNome: usuario?['nome']?.toString() ?? 'Responsável não informado',

      agendamentoId: (json['agendamentoId'] as num?)?.toInt(),

      quantidadePecas: pecas is List ? pecas.length : 0,
    );
  }
}
