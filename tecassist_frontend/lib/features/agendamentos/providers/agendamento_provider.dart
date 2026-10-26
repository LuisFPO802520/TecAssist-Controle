import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/agendamento_model.dart';
import '../services/agendamento_service.dart';

enum AgendamentoVisualizacao { lista, calendario }

class AgendamentoProvider extends ChangeNotifier {
  final AgendamentoService _service;

  AgendamentoProvider(this._service);

  final List<AgendamentoModel> _agendamentos = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _busca = '';
  DateTime _dataSelecionada = DateTime.now();

  AgendamentoVisualizacao _visualizacao = AgendamentoVisualizacao.lista;

  List<AgendamentoModel> get agendamentos => List.unmodifiable(_agendamentos);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String get busca => _busca;
  DateTime get dataSelecionada => _dataSelecionada;
  AgendamentoVisualizacao get visualizacao => _visualizacao;

  Future<void> carregar() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final lista = await _service.findAll();

      _agendamentos
        ..clear()
        ..addAll(lista);
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'].toString();
      } else {
        _errorMessage = 'Não foi possível carregar os agendamentos.';
      }
    } catch (_) {
      _errorMessage = 'Erro inesperado ao carregar os agendamentos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setBusca(String value) {
    _busca = value;
    notifyListeners();
  }

  void setVisualizacao(AgendamentoVisualizacao value) {
    _visualizacao = value;
    notifyListeners();
  }

  void setDataSelecionada(DateTime data) {
    _dataSelecionada = DateTime(data.year, data.month, data.day);
    notifyListeners();
  }

  void semanaAnterior() {
    _dataSelecionada = _dataSelecionada.subtract(const Duration(days: 7));

    notifyListeners();
  }

  void proximaSemana() {
    _dataSelecionada = _dataSelecionada.add(const Duration(days: 7));

    notifyListeners();
  }

  List<DateTime> get diasDaSemana {
    final atual = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
    );

    final inicio = atual.subtract(Duration(days: atual.weekday - 1));

    return List.generate(7, (index) => inicio.add(Duration(days: index)));
  }

  List<AgendamentoModel> get agendamentosFiltrados {
    final termo = _busca.trim().toLowerCase();

    final lista = [..._agendamentos]..sort((a, b) => a.data.compareTo(b.data));

    if (termo.isEmpty) {
      return lista;
    }

    return lista.where((agendamento) {
      return agendamento.descricao.toLowerCase().contains(termo) ||
          agendamento.clienteNome.toLowerCase().contains(termo) ||
          agendamento.status.toLowerCase().contains(termo);
    }).toList();
  }

  List<AgendamentoModel> get agendamentosDoDia {
    final dia = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
    );

    return agendamentosFiltrados.where((agendamento) {
      return _mesmoDia(agendamento.data, dia);
    }).toList()..sort((a, b) => a.data.compareTo(b.data));
  }

  int totalNoDia(DateTime dia) {
    return agendamentos.where((item) => _mesmoDia(item.data, dia)).length;
  }

  Future<bool> remover(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.delete(id);

      _agendamentos.removeWhere((item) => item.id == id);

      return true;
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'].toString();
      } else {
        _errorMessage = 'Não foi possível excluir o agendamento.';
      }

      return false;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao excluir o agendamento.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AgendamentoModel?> buscarPorId(int id) async {
    _errorMessage = null;

    try {
      return await _service.findById(id);
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'].toString();
      } else {
        _errorMessage = 'Não foi possível carregar o agendamento.';
      }

      notifyListeners();

      return null;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao carregar o agendamento.';

      notifyListeners();

      return null;
    }
  }

  Future<bool> criar({
    required String descricao,
    required DateTime data,
    required int clienteId,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.create(
        descricao: descricao,
        data: data,
        clienteId: clienteId,
        status: 'AGENDADO',
      );

      await carregar();

      return true;
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'].toString();
      } else {
        _errorMessage = 'Não foi possível criar o agendamento.';
      }

      return false;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao criar o agendamento.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> atualizar({
    required int id,
    required String descricao,
    required DateTime data,
    required int clienteId,
    required String status,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.update(
        id: id,
        descricao: descricao,
        data: data,
        clienteId: clienteId,
        status: status,
      );

      await carregar();

      return true;
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'].toString();
      } else {
        _errorMessage = 'Não foi possível atualizar o agendamento.';
      }

      return false;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao atualizar o agendamento.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> converterEmServico({
    required int agendamentoId,
    required String equipamento,
    String? marca,
    String? modelo,
    String? problema,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.converterEmServico(
        agendamentoId: agendamentoId,
        equipamento: equipamento,
        marca: marca,
        modelo: modelo,
        problema: problema,
      );

      await carregar();

      return true;
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'].toString();
      } else {
        _errorMessage = 'Não foi possível converter o agendamento.';
      }

      return false;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao converter o agendamento.';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
