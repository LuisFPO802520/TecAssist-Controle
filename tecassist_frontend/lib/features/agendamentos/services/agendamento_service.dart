import '../../../core/network/api_client.dart';
import '../models/agendamento_model.dart';

class AgendamentoService {
  Future<List<AgendamentoModel>> findAll() async {
    final response = await ApiClient.dio.get('/agendamentos');

    final data = response.data as List;

    return data
        .map((item) => AgendamentoModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AgendamentoModel> findById(int id) async {
    final response = await ApiClient.dio.get('/agendamentos/$id');

    return AgendamentoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AgendamentoModel> create({
    required String descricao,
    required DateTime data,
    required int clienteId,
    String status = 'AGENDADO',
  }) async {
    final response = await ApiClient.dio.post(
      '/agendamentos',
      data: {
        'descricao': descricao,
        'data': data.toIso8601String(),
        'clienteId': clienteId,
        'status': status,
      },
    );

    return AgendamentoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> converterEmServico({
    required int agendamentoId,
    required String equipamento,
    String? marca,
    String? modelo,
    String? problema,
  }) async {
    await ApiClient.dio.post(
      '/agendamentos/$agendamentoId/converter',

      data: {
        'equipamento': equipamento.trim(),

        'marca': marca?.trim().isNotEmpty == true ? marca!.trim() : null,

        'modelo': modelo?.trim().isNotEmpty == true ? modelo!.trim() : null,

        'problema': problema?.trim().isNotEmpty == true
            ? problema!.trim()
            : null,
      },
    );
  }

  Future<AgendamentoModel> update({
    required int id,
    required String descricao,
    required DateTime data,
    required int clienteId,
    required String status,
  }) async {
    final response = await ApiClient.dio.put(
      '/agendamentos/$id',
      data: {
        'descricao': descricao,
        'data': data.toIso8601String(),
        'clienteId': clienteId,
        'status': status,
      },
    );

    return AgendamentoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await ApiClient.dio.delete('/agendamentos/$id');
  }
}
