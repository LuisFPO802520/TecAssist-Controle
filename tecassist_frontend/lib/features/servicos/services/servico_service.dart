import '../../../core/network/api_client.dart';

class ServicoService {
  List<dynamic> _extrairLista(dynamic dados) {
    if (dados is List) {
      return dados;
    }

    if (dados is Map) {
      if (dados['servicos'] is List) {
        return dados['servicos'] as List;
      }

      if (dados['data'] is List) {
        return dados['data'] as List;
      }
    }

    throw const FormatException(
      'A API retornou uma lista de serviços inválida.',
    );
  }

  Map<String, dynamic> _extrairObjeto(dynamic dados) {
    if (dados is Map) {
      if (dados['servico'] is Map) {
        return Map<String, dynamic>.from(dados['servico'] as Map);
      }

      if (dados['data'] is Map) {
        return Map<String, dynamic>.from(dados['data'] as Map);
      }

      return Map<String, dynamic>.from(dados);
    }

    throw const FormatException('A API retornou um serviço inválido.');
  }

  Future<List<Map<String, dynamic>>> listar() async {
    final response = await ApiClient.dio.get('/servicos');

    return _extrairLista(response.data).map((item) {
      if (item is! Map) {
        throw const FormatException('Registro de serviço inválido.');
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>> buscarPorId(int id) async {
    final response = await ApiClient.dio.get('/servicos/$id');

    return _extrairObjeto(response.data);
  }

  Future<void> criar({
    required int clienteId,
    required String equipamento,
    String? marca,
    String? modelo,
    String? problema,
    String? diagnostico,
    String? solucao,
    double? valor,
  }) async {
    await ApiClient.dio.post(
      '/servicos',
      data: {
        'clienteId': clienteId,
        'equipamento': equipamento.trim(),
        'marca': _textoOpcional(marca),
        'modelo': _textoOpcional(modelo),
        'problema': _textoOpcional(problema),
        'diagnostico': _textoOpcional(diagnostico),
        'solucao': _textoOpcional(solucao),
        'valor': valor,
      },
    );
  }

  Future<void> atualizar({
    required int id,
    required int clienteId,
    required String equipamento,
    required String status,
    String? marca,
    String? modelo,
    String? problema,
    String? diagnostico,
    String? solucao,
    double? valor,
  }) async {
    await ApiClient.dio.put(
      '/servicos/$id',
      data: {
        'clienteId': clienteId,
        'equipamento': equipamento.trim(),
        'marca': _textoOpcional(marca),
        'modelo': _textoOpcional(modelo),
        'problema': _textoOpcional(problema),
        'diagnostico': _textoOpcional(diagnostico),
        'solucao': _textoOpcional(solucao),
        'status': status,
        'valor': valor,
      },
    );
  }

  Future<void> excluir(int id) async {
    await ApiClient.dio.delete('/servicos/$id');
  }

  String? _textoOpcional(String? texto) {
    final valor = texto?.trim();

    if (valor == null || valor.isEmpty) {
      return null;
    }

    return valor;
  }
}
