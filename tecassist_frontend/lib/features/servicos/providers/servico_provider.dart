import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/servico_model.dart';
import '../models/notificacao_model.dart';
import '../services/servico_service.dart';
import '../services/notificacao_service.dart';

class ServicoProvider extends ChangeNotifier {
  final ServicoService _service;
  final NotificacaoService _notificacaoService = NotificacaoService();

  ServicoProvider(this._service);

  List<ServicoModel> _servicos = [];

  bool _isLoading = false;
  bool _jaCarregou = false;
  bool _isSaving = false;

  String? _errorMessage;
  String? _notificacaoError;
  bool _isLoadingNotificacoes = false;
  List<NotificacaoModel> _notificacoes = [];

  List<ServicoModel> get servicos => List.unmodifiable(_servicos);

  bool get isLoading => _isLoading;
  bool get jaCarregou => _jaCarregou;
  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;
  String? get notificacaoError => _notificacaoError;
  bool get isLoadingNotificacoes => _isLoadingNotificacoes;
  List<NotificacaoModel> get notificacoes => List.unmodifiable(_notificacoes);

  Future<void> carregar() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dados = await _service.listar();

      _servicos = dados.map(ServicoModel.fromJson).toList()
        ..sort((a, b) {
          final dataA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          final dataB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

          return dataB.compareTo(dataA);
        });
      _jaCarregou = true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os serviços.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ServicoModel?> buscarPorId(int id) async {
    _errorMessage = null;

    try {
      final dados = await _service.buscarPorId(id);

      return ServicoModel.fromJson(dados);
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
    } catch (_) {
      _errorMessage = 'Não foi possível carregar o serviço.';
    }

    notifyListeners();
    return null;
  }

  Future<bool> criar({
    required int clienteId,
    required String equipamento,
    String? marca,
    String? modelo,
    String? problema,
    String? diagnostico,
    String? solucao,
    double? valor,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.criar(
        clienteId: clienteId,
        equipamento: equipamento,
        marca: marca,
        modelo: modelo,
        problema: problema,
        diagnostico: diagnostico,
        solucao: solucao,
        valor: valor,
      );

      await carregar();
      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Erro ao registrar o serviço.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> atualizar({
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
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.atualizar(
        id: id,
        clienteId: clienteId,
        equipamento: equipamento,
        status: status,
        marca: marca,
        modelo: modelo,
        problema: problema,
        diagnostico: diagnostico,
        solucao: solucao,
        valor: valor,
      );

      await carregar();
      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Erro ao atualizar o serviço.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> adicionarPeca({
    required int servicoId,
    required int estoqueId,
    required int quantidade,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.adicionarPeca(
        servicoId: servicoId,
        estoqueId: estoqueId,
        quantidade: quantidade,
      );

      await carregar();

      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível adicionar a peça ao serviço.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> removerPeca({
    required int servicoId,
    required int servicoPecaId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.removerPeca(
        servicoId: servicoId,
        servicoPecaId: servicoPecaId,
      );

      await carregar();

      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível remover a peça do serviço.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarStatus(ServicoModel servico, String novoStatus) {
    return atualizar(
      id: servico.id,
      clienteId: servico.clienteId,
      equipamento: servico.equipamento,
      marca: servico.marca,
      modelo: servico.modelo,
      problema: servico.problema,
      diagnostico: servico.diagnostico,
      solucao: servico.solucao,
      valor: servico.valor,
      status: novoStatus,
    );
  }

  Future<void> carregarNotificacoes(int servicoId) async {
    _isLoadingNotificacoes = true;
    _notificacaoError = null;
    notifyListeners();

    try {
      _notificacoes = await _notificacaoService.listarPorServico(servicoId);
    } on DioException catch (error) {
      _notificacaoError = _mensagemErro(error);
    } catch (_) {
      _notificacaoError = 'Não foi possível carregar o histórico de mensagens.';
    } finally {
      _isLoadingNotificacoes = false;
      notifyListeners();
    }
  }

  Future<PreparacaoWhatsApp?> prepararWhatsApp({
    required int servicoId,
    required String mensagem,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _notificacaoService.prepararWhatsApp(
        servicoId: servicoId,
        mensagem: mensagem,
      );

      _notificacoes = [
        resultado.notificacao,
        ..._notificacoes.where((item) => item.id != resultado.notificacao.id),
      ];

      return resultado;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return null;
    } catch (error) {
      _errorMessage = error is FormatException
          ? error.message.toString()
          : 'Não foi possível preparar a mensagem.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> marcarNotificacaoComoEnviada(int notificacaoId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizada = await _notificacaoService.marcarComoEnviada(
        notificacaoId,
      );

      _notificacoes = _notificacoes.map((item) {
        return item.id == atualizada.id ? atualizada : item;
      }).toList();

      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar o status da mensagem.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> excluir(int id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.excluir(id);

      _servicos.removeWhere((servico) => servico.id == id);

      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Erro ao excluir o serviço.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _mensagemErro(DioException error) {
    final dados = error.response?.data;

    if (dados is Map && dados['error'] != null) {
      return dados['error'].toString();
    }

    if (dados is Map && dados['message'] != null) {
      return dados['message'].toString();
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Não foi possível conectar ao servidor.';
    }

    return 'Não foi possível realizar a operação.';
  }
}
