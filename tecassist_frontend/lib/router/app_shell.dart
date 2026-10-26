import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_bottom_navigation.dart';

import '../features/agendamentos/views/agendamentos_page.dart';
import '../features/clientes/views/clientes_page.dart';
import '../features/dashboard/views/dashboard_drawer.dart';
import '../features/dashboard/views/dashboard_page.dart';
import '../features/estoque/views/estoque_page.dart';
import '../features/servicos/views/servicos_page.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final PageController _pageController;

  late int _currentIndex;

  DateTime? _ultimoVoltar;

  final List<Widget> _pages = const [
    ClientesPage(),
    AgendamentosPage(),
    ServicosPage(),
    EstoquePage(),
  ];

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(widget.initialIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  void _abrirDrawer() {
    if (_currentIndex != 0) {
      return;
    }

    _scaffoldKey.currentState?.openDrawer();
  }

  void _mudarPagina(int index) {
    if (_currentIndex == index) {
      return;
    }

    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    _ultimoVoltar = null;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _paginaAlterada(int index) {
    setState(() {
      _currentIndex = index;
    });

    _ultimoVoltar = null;
  }

  Future<void> _botaoVoltar() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();

      _ultimoVoltar = null;

      return;
    }

    if (_currentIndex != 0) {
      _ultimoVoltar = null;

      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );

      return;
    }
    final agora = DateTime.now();

    if (_ultimoVoltar == null ||
        agora.difference(_ultimoVoltar!) > const Duration(seconds: 2)) {
      _ultimoVoltar = agora;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pressione voltar novamente para sair.'),
            duration: Duration(seconds: 2),
          ),
        );

      return;
    }

    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    /*
     * Aumenta a área de abertura do Drawer.
     *
     * Em um celular de aproximadamente
     * 400px de largura teremos cerca de
     * 110px disponíveis para iniciar o gesto.
     *
     * Isso permite começar o movimento
     * um pouco mais para dentro da tela,
     * evitando disputar diretamente com
     * o gesto de voltar do Android.
     */
    final larguraTela = MediaQuery.sizeOf(context).width;

    final larguraGestoDrawer = (larguraTela * 0.28)
        .clamp(175.0, 200.0)
        .toDouble();

    return PopScope(
      canPop: false,

      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }

        _botaoVoltar();
      },

      child: Scaffold(
        key: _scaffoldKey,

        backgroundColor: AppColors.background,

        drawer: _currentIndex == 0 ? const DashboardDrawer() : null,

        drawerEnableOpenDragGesture: _currentIndex == 0,

        /*
         * Antes estava em 45.
         *
         * Agora fica entre 90 e 130,
         * dependendo da largura da tela.
         */
        drawerEdgeDragWidth: larguraGestoDrawer,

        body: ColoredBox(
          color: AppColors.background,

          child: PageView(
            controller: _pageController,

            physics: const ClampingScrollPhysics(),

            pageSnapping: true,

            onPageChanged: _paginaAlterada,

            children: [
              DashboardPage(onOpenDrawer: _abrirDrawer),

              ..._pages,
            ],
          ),
        ),

        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _currentIndex,

          onTap: _mudarPagina,
        ),
      ),
    );
  }
}
