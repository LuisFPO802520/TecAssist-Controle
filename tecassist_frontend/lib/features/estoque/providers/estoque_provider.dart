import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/estoque_model.dart';
import '../models/movimentacao_estoque_model.dart';
import '../services/estoque_service.dart';

class EstoqueProvider extends ChangeNotifier {
  final EstoqueService _service;

  EstoqueProvider(this._service);

  List<EstoqueModel> _itens = [];

  final Map<int, List<MovimentacaoEstoqueModel>> _historicos = {};

  bool _isLoading = false;
  bool _jaCarregou = false;
  bool _isSaving = false;

  String? _errorMessage;
  String? _historicoError;

  List<EstoqueModel> get itens => List.unmodifiable(_itens);

  bool get isLoading => _isLoading;
  bool get jaCarregou => _jaCarregou;
  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;
  String? get historicoError => _historicoError;

  int get totalItens => _itens.length;

  int get totalSemEstoque => _itens.where((item) => item.semEstoque).length;

  int get totalEstoqueBaixo => _itens.where((item) => item.estoqueBaixo).length;

  List<MovimentacaoEstoqueModel> historicoDoItem(int estoqueId) {
    return List.unmodifiable(_historicos[estoqueId] ?? []);
  }

  Future<void> carregar() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dados = await _service.listar();

      _itens = dados.map(EstoqueModel.fromJson).toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      _jaCarregou = true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
    } catch (_) {
      _errorMessage = 'Não foi possível carregar o estoque.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EstoqueModel?> buscarPorId(int id) async {
    _errorMessage = null;

    try {
      final dados = await _service.buscarPorId(id);
      return EstoqueModel.fromJson(dados);
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
    } catch (_) {
      _errorMessage = 'Não foi possível carregar a peça.';
    }

    notifyListeners();
    return null;
  }

  Future<void> carregarHistorico(int estoqueId) async {
    _historicoError = null;

    try {
      final dados = await _service.listarMovimentacoes();

      final movimentacoes =
          dados
              .map(MovimentacaoEstoqueModel.fromJson)
              .where((item) => item.estoqueId == estoqueId)
              .toList()
            ..sort((a, b) {
              final dataA =
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              final dataB =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

              return dataB.compareTo(dataA);
            });

      _historicos[estoqueId] = movimentacoes;
    } on DioException catch (error) {
      _historicoError = _mensagemErro(error);
    } catch (_) {
      _historicoError = 'Não foi possível carregar o histórico.';
    }

    notifyListeners();
  }

  Future<bool> criar({
    required String nome,
    required String descricao,
    required int quantidade,
    required double valor,
    String? fornecedor,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.criar(
        nome: nome,
        descricao: descricao,
        quantidade: quantidade,
        valor: valor,
        fornecedor: fornecedor,
      );

      await carregar();
      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível cadastrar a peça.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> atualizar({
    required int id,
    required String nome,
    required String descricao,
    required double valor,
    String? fornecedor,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.atualizar(
        id: id,
        nome: nome,
        descricao: descricao,
        valor: valor,
        fornecedor: fornecedor,
      );

      await carregar();
      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar a peça.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> registrarEntrada({
    required int estoqueId,
    required int quantidade,
  }) {
    return _registrarMovimentacao(
      estoqueId: estoqueId,
      quantidade: quantidade,
      entrada: true,
    );
  }

  Future<bool> registrarSaida({
    required int estoqueId,
    required int quantidade,
  }) {
    return _registrarMovimentacao(
      estoqueId: estoqueId,
      quantidade: quantidade,
      entrada: false,
    );
  }

  Future<bool> _registrarMovimentacao({
    required int estoqueId,
    required int quantidade,
    required bool entrada,
  }) async {
    if (quantidade <= 0) {
      _errorMessage = 'A quantidade precisa ser maior que zero.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (entrada) {
        await _service.registrarEntrada(
          estoqueId: estoqueId,
          quantidade: quantidade,
        );
      } else {
        await _service.registrarSaida(
          estoqueId: estoqueId,
          quantidade: quantidade,
        );
      }

      await carregar();
      await carregarHistorico(estoqueId);

      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível registrar a movimentação.';
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

      _itens.removeWhere((item) => item.id == id);
      _historicos.remove(id);

      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível excluir a peça.';
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

    if (error.response?.statusCode == 403) {
      return 'Você não possui permissão para esta operação.';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Não foi possível conectar ao servidor.';
    }

    return 'Não foi possível realizar a operação.';
  }
}
