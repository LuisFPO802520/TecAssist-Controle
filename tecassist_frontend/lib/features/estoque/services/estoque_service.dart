import '../../../core/network/api_client.dart';

class EstoqueService {
  List<dynamic> _extrairLista(dynamic dados, {String? chave}) {
    if (dados is List) {
      return dados;
    }

    if (dados is Map) {
      if (chave != null && dados[chave] is List) {
        return dados[chave] as List;
      }

      if (dados['data'] is List) {
        return dados['data'] as List;
      }

      if (dados['itens'] is List) {
        return dados['itens'] as List;
      }
    }

    throw const FormatException('A API retornou uma lista inválida.');
  }

  Map<String, dynamic> _extrairObjeto(dynamic dados, {String? chave}) {
    if (dados is Map) {
      if (chave != null && dados[chave] is Map) {
        return Map<String, dynamic>.from(dados[chave] as Map);
      }

      if (dados['data'] is Map) {
        return Map<String, dynamic>.from(dados['data'] as Map);
      }

      return Map<String, dynamic>.from(dados);
    }

    throw const FormatException('A API retornou um registro inválido.');
  }

  Future<List<Map<String, dynamic>>> listar() async {
    final response = await ApiClient.dio.get('/estoque');

    return _extrairLista(response.data, chave: 'estoque').map((item) {
      if (item is! Map) {
        throw const FormatException('Peça inválida retornada pela API.');
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>> buscarPorId(int id) async {
    final response = await ApiClient.dio.get('/estoque/$id');

    return _extrairObjeto(response.data, chave: 'estoque');
  }

  Future<void> criar({
    required String nome,
    required String descricao,
    required int quantidade,
    required double valor,
    String? fornecedor,
  }) async {
    await ApiClient.dio.post(
      '/estoque',
      data: {
        'nome': nome.trim(),
        'descricao': descricao.trim(),
        'quantidade': quantidade,
        'valor': valor,
        'fornecedor': _opcional(fornecedor),
      },
    );
  }

  Future<void> atualizar({
    required int id,
    required String nome,
    required String descricao,
    required double valor,
    String? fornecedor,
  }) async {
    await ApiClient.dio.put(
      '/estoque/$id',
      data: {
        'nome': nome.trim(),
        'descricao': descricao.trim(),
        'valor': valor,
        'fornecedor': _opcional(fornecedor),
      },
    );
  }

  Future<void> excluir(int id) async {
    await ApiClient.dio.delete('/estoque/$id');
  }

  Future<void> registrarEntrada({
    required int estoqueId,
    required int quantidade,
  }) async {
    await ApiClient.dio.post(
      '/movimentacoes/entrada/$estoqueId',
      data: {'quantidade': quantidade},
    );
  }

  Future<void> registrarSaida({
    required int estoqueId,
    required int quantidade,
  }) async {
    await ApiClient.dio.post(
      '/movimentacoes/saida/$estoqueId',
      data: {'quantidade': quantidade},
    );
  }

  Future<List<Map<String, dynamic>>> listarMovimentacoes() async {
    final response = await ApiClient.dio.get('/movimentacoes/historico');

    return _extrairLista(response.data, chave: 'movimentacoes').map((item) {
      if (item is! Map) {
        throw const FormatException(
          'Movimentação inválida retornada pela API.',
        );
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  String? _opcional(String? valor) {
    final texto = valor?.trim();

    if (texto == null || texto.isEmpty) {
      return null;
    }

    return texto;
  }
}
