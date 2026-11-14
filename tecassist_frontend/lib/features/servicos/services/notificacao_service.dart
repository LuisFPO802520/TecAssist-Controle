import '../../../core/network/api_client.dart';
import '../models/notificacao_model.dart';

class NotificacaoService {
  Future<List<NotificacaoModel>> listarPorServico(int servicoId) async {
    final response = await ApiClient.dio.get(
      '/notificacoes/servico/$servicoId',
    );

    final dados = response.data;
    if (dados is! List) {
      throw const FormatException(
        'A API retornou um histórico de notificações inválido.',
      );
    }

    return dados
        .whereType<Map>()
        .map(
          (item) => NotificacaoModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<PreparacaoWhatsApp> prepararWhatsApp({
    required int servicoId,
    required String mensagem,
  }) async {
    final response = await ApiClient.dio.post(
      '/notificacoes/servico/$servicoId/whatsapp',
      data: {'mensagem': mensagem},
    );

    final dados = response.data;
    if (dados is! Map ||
        dados['notificacao'] is! Map ||
        dados['destinatario'] is! Map) {
      throw const FormatException(
        'A API não retornou os dados da mensagem preparada.',
      );
    }

    final notificacao = NotificacaoModel.fromJson(
      Map<String, dynamic>.from(dados['notificacao'] as Map),
    );

    final destinatario = Map<String, dynamic>.from(
      dados['destinatario'] as Map,
    );

    final telefone = destinatario['telefone']?.toString() ?? '';
    final nome = destinatario['nome']?.toString() ?? 'Cliente';

    if (telefone.trim().isEmpty) {
      throw const FormatException('O cliente não possui telefone cadastrado.');
    }

    return PreparacaoWhatsApp(
      notificacao: notificacao,
      telefone: telefone,
      nomeCliente: nome,
    );
  }

  Future<NotificacaoModel> marcarComoEnviada(int notificacaoId) async {
    final response = await ApiClient.dio.patch(
      '/notificacoes/$notificacaoId/status',
      data: {'status': 'ENVIADA'},
    );

    final dados = response.data;
    if (dados is! Map || dados['notificacao'] is! Map) {
      throw const FormatException(
        'A API não retornou a notificação atualizada.',
      );
    }

    return NotificacaoModel.fromJson(
      Map<String, dynamic>.from(dados['notificacao'] as Map),
    );
  }
}
