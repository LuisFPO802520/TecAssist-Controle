import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../../core/widgets/blue_pattern_background.dart';

import '../../auth/services/codigo_cadastro_service.dart';

import 'codigo_cadastro_widgets.dart';

class CodigoCadastroPage extends StatefulWidget {
  const CodigoCadastroPage({super.key});

  @override
  State<CodigoCadastroPage> createState() => _CodigoCadastroPageState();
}

class _CodigoCadastroPageState extends State<CodigoCadastroPage> {
  int _limiteUsos = 1;

  String? _codigo;

  int _limiteCodigoAtual = 0;
  int _usos = 0;
  int _usosRestantes = 0;
  int _segundosRestantes = 0;

  bool _carregando = false;
  bool _gerando = false;

  bool _sincronizando = false;

  Timer? _timer;

  int _ticks = 0;

  @override
  void initState() {
    super.initState();

    _consultarCodigoAtual(mostrarLoading: true);
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  Future<void> _consultarCodigoAtual({bool mostrarLoading = false}) async {
    if (mostrarLoading && mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final resultado = await CodigoCadastroService.consultarCodigo();

      if (!mounted) {
        return;
      }

      if (resultado == null) {
        _limparCodigo();

        return;
      }

      _aplicarDadosCodigo(resultado, iniciarMonitoramento: true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao consultar código: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted && mostrarLoading) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _sincronizarCodigoAtual() async {
    if (_sincronizando || _codigo == null) {
      return;
    }

    _sincronizando = true;

    try {
      final resultado = await CodigoCadastroService.consultarCodigo();

      if (!mounted) {
        return;
      }

      if (resultado == null) {
        _limparCodigo();

        return;
      }

      _aplicarDadosCodigo(resultado, iniciarMonitoramento: false);
    } catch (_) {
    } finally {
      _sincronizando = false;
    }
  }

  Future<void> _gerarCodigo() async {
    setState(() {
      _gerando = true;
    });

    try {
      final resultado = await CodigoCadastroService.gerarCodigo(
        limiteUsos: _limiteUsos,
      );

      if (!mounted) {
        return;
      }

      _aplicarDadosCodigo(resultado, iniciarMonitoramento: true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de cadastro gerado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar código: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gerando = false;
        });
      }
    }
  }

  void _aplicarDadosCodigo(
    Map<String, dynamic> dados, {
    required bool iniciarMonitoramento,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _codigo = dados['codigo']?.toString();

      _limiteCodigoAtual = (dados['limiteUsos'] as num?)?.toInt() ?? 0;

      _usos = (dados['usos'] as num?)?.toInt() ?? 0;

      _usosRestantes = (dados['usosRestantes'] as num?)?.toInt() ?? 0;

      _segundosRestantes = (dados['expiresInSeconds'] as num?)?.toInt() ?? 0;
    });

    if (iniciarMonitoramento) {
      _iniciarMonitoramento();
    }
  }

  void _iniciarMonitoramento() {
    _timer?.cancel();

    _ticks = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_codigo == null) {
        timer.cancel();
        return;
      }

      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });
      }

      if (_segundosRestantes <= 0) {
        timer.cancel();

        _limparCodigo();

        return;
      }

      _ticks++;

      if (_ticks % 2 == 0) {
        await _sincronizarCodigoAtual();
      }
    });
  }

  void _limparCodigo() {
    _timer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _codigo = null;

      _limiteCodigoAtual = 0;
      _usos = 0;
      _usosRestantes = 0;
      _segundosRestantes = 0;
    });
  }

  void _diminuirLimite() {
    if (_limiteUsos <= 1) {
      return;
    }

    setState(() {
      _limiteUsos--;
    });
  }

  void _aumentarLimite() {
    if (_limiteUsos >= 50) {
      return;
    }

    setState(() {
      _limiteUsos++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          toolbarHeight: 85,
          automaticallyImplyLeading: false,

          surfaceTintColor: Colors.transparent,

          elevation: 0,

          centerTitle: true,

          flexibleSpace: BluePatternBackground(
            showTopCircles: true,
            showBottomCircles: false,
            compactTopCircles: true,
            child: const SizedBox.expand(),
          ),

          leading: Transform.translate(
            offset: const Offset(0, 18),
            child: IconButton(
              onPressed: () {
                context.go('/app/home');
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          title: Transform.translate(
            offset: const Offset(0, 18),
            child: const Text(
              'Código de cadastro',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        body: RefreshIndicator(
          onRefresh: _sincronizarCodigoAtual,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.all(20),

            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Código para novos funcionários',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Gere um código temporário para permitir o cadastro de novos funcionários.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 28),

                    ConfiguracaoCodigoCard(
                      limiteUsos: _limiteUsos,

                      gerando: _gerando,

                      onDiminuir: _diminuirLimite,

                      onAumentar: _aumentarLimite,

                      onGerar: _gerarCodigo,
                    ),

                    const SizedBox(height: 22),

                    if (_carregando)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_codigo == null)
                      const SemCodigoCard()
                    else
                      CodigoAtualCard(
                        codigo: _codigo!,

                        limiteUsos: _limiteCodigoAtual,

                        usos: _usos,

                        usosRestantes: _usosRestantes,

                        segundosRestantes: _segundosRestantes,

                        onAtualizar: () {
                          _sincronizarCodigoAtual();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        bottomNavigationBar: const AppBottomNavigation(),
      ),
    );
  }
}
