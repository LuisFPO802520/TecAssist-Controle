import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_bottom_navigation.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/views/login_page.dart';
import '../features/auth/views/welcome_page.dart';
import '../features/usuarios/views/usuario_form_page.dart';
import '../features/usuarios/views/usuarios_page.dart';
import '../features/clientes/views/cliente_detalhes_page.dart';
import '../features/clientes/views/cliente_form_page.dart';
import '../features/usuarios/views/codigo_cadastro_page.dart';
import '../features/auth/views/cadastro_page.dart';
import '../features/agendamentos/views/agendamentos_form_page.dart';
import '../features/agendamentos/views/converter_agendamento_page.dart';
import 'app_shell.dart';

class AppRouter {
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: authProvider.isAuthenticated ? '/app/home' : '/',

      refreshListenable: authProvider,

      redirect: (context, state) {
        final autenticado = authProvider.isAuthenticated;

        final location = state.matchedLocation;

        final rotaPublica =
            location == '/' || location == '/login' || location == '/cadastro';

        if (!autenticado && !rotaPublica) {
          return '/';
        }

        if (autenticado && rotaPublica) {
          return '/app/home';
        }

        if (location.startsWith('/usuarios') && !authProvider.isAdmin) {
          return '/app/home';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const WelcomePage();
          },
        ),

        GoRoute(
          path: '/login',
          builder: (context, state) {
            return const LoginPage();
          },
        ),

        GoRoute(
          path: '/cadastro',
          builder: (context, state) {
            return const CadastroPage();
          },
        ),

        GoRoute(
          path: '/app/:section',

          pageBuilder: (context, state) {
            final section = state.pathParameters['section'] ?? 'home';

            final index = _sectionToIndex(section);

            return NoTransitionPage(child: AppShell(initialIndex: index));
          },
        ),

        GoRoute(path: '/dashboard', redirect: (context, state) => '/app/home'),

        GoRoute(
          path: '/clientes',
          redirect: (context, state) => '/app/clientes',
        ),

        GoRoute(
          path: '/agendamentos',
          redirect: (context, state) => '/app/agenda',
        ),

        GoRoute(
          path: '/agendamentos/novo',
          builder: (context, state) {
            return const AgendamentoFormPage();
          },
        ),

        GoRoute(
          path: '/agendamentos/:id/editar',

          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const AppShell(initialIndex: 2);
            }

            return AgendamentoFormPage(agendamentoId: id);
          },
        ),

        GoRoute(
          path: '/agendamentos/:id/converter',

          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const AppShell(initialIndex: 2);
            }

            return ConverterAgendamentoPage(agendamentoId: id);
          },
        ),

        GoRoute(
          path: '/servicos',
          redirect: (context, state) => '/app/servicos',
        ),

        GoRoute(path: '/estoque', redirect: (context, state) => '/app/estoque'),

        GoRoute(
          path: '/usuarios',
          builder: (context, state) {
            return const UsuariosPage();
          },
        ),

        GoRoute(
          path: '/usuarios/novo',
          builder: (context, state) {
            return const UsuarioFormPage();
          },
        ),

        GoRoute(
          path: '/usuarios/:id/editar',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const UsuariosPage();
            }

            return UsuarioFormPage(usuarioId: id);
          },
        ),

        GoRoute(
          path: '/clientes/novo',
          builder: (context, state) {
            return const ClienteFormPage();
          },
        ),

        GoRoute(
          path: '/clientes/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const AppShell(initialIndex: 1);
            }

            return ClienteDetalhesPage(clienteId: id);
          },
        ),

        GoRoute(
          path: '/clientes/:id/editar',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const AppShell(initialIndex: 1);
            }

            return ClienteFormPage(clienteId: id);
          },
        ),

        GoRoute(
          path: '/configuracoes',
          builder: (context, state) {
            return const _PlaceholderPage(titulo: 'Configurações');
          },
        ),

        GoRoute(
          path: '/sac',
          builder: (context, state) {
            return const _PlaceholderPage(titulo: 'SAC');
          },
        ),

        GoRoute(
          path: '/codigo-cadastro',
          builder: (context, state) {
            return const CodigoCadastroPage();
          },
        ),
      ],
    );
  }

  static int _sectionToIndex(String section) {
    switch (section) {
      case 'clientes':
        return 1;

      case 'agenda':
        return 2;

      case 'servicos':
        return 3;

      case 'estoque':
        return 4;

      case 'home':
      default:
        return 0;
    }
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String titulo;

  const _PlaceholderPage({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),

        leading: IconButton(
          onPressed: () {
            context.go('/app/home');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),

      bottomNavigationBar: const AppBottomNavigation(),

      body: Center(child: Text('$titulo será implementado posteriormente.')),
    );
  }
}
