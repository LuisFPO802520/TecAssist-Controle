import '../../../core/network/api_client.dart';
import '../models/cliente_model.dart';

class ClienteService {
  Future<List<ClienteModel>> listarClientes() async {
    final response = await ApiClient.dio.get('/clientes');

    final List<dynamic> dados = response.data;

    return dados.map((json) => ClienteModel.fromJson(json)).toList();
  }

  Future<ClienteModel> buscarCliente(int id) async {
    final response = await ApiClient.dio.get('/clientes/$id');

    return ClienteModel.fromJson(response.data);
  }

  Future<ClienteModel> criarCliente({
    required String nome,
    required String telefone,
    String? email,
    String? endereco,
    String? cpf,
    String? observacoes,
  }) async {
    final response = await ApiClient.dio.post(
      '/clientes',
      data: {
        'nome': nome,
        'telefone': telefone,

        'email': email?.trim().isNotEmpty == true ? email!.trim() : null,

        'endereco': endereco?.trim().isNotEmpty == true
            ? endereco!.trim()
            : null,

        'cpf': cpf?.trim().isNotEmpty == true ? cpf!.trim() : null,

        'observacoes': observacoes?.trim().isNotEmpty == true
            ? observacoes!.trim()
            : null,
      },
    );

    return ClienteModel.fromJson(response.data);
  }

  Future<ClienteModel> atualizarCliente({
    required int id,
    required String nome,
    required String telefone,
    String? email,
    String? endereco,
    String? cpf,
    String? observacoes,
  }) async {
    final response = await ApiClient.dio.put(
      '/clientes/$id',
      data: {
        'nome': nome,
        'telefone': telefone,

        'email': email?.trim().isNotEmpty == true ? email!.trim() : null,

        'endereco': endereco?.trim().isNotEmpty == true
            ? endereco!.trim()
            : null,

        'cpf': cpf?.trim().isNotEmpty == true ? cpf!.trim() : null,

        'observacoes': observacoes?.trim().isNotEmpty == true
            ? observacoes!.trim()
            : null,
      },
    );

    return ClienteModel.fromJson(response.data);
  }

  Future<void> excluirCliente(int id) async {
    await ApiClient.dio.delete('/clientes/$id');
  }
}
