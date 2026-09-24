import 'package:go_router/go_router.dart';

import '../features/agendamentos/views/agendamentos_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/views/login_page.dart';
import '../features/clientes/views/clientes_page.dart';
import '../features/dashboard/views/dashboard_page.dart';
import '../features/estoque/views/estoque_page.dart';
import '../features/servicos/views/servicos_page.dart';
import '../features/usuarios/views/usuario_form_page.dart';
import '../features/usuarios/views/usuarios_page.dart';

class AppRouter {
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: authProvider.isAuthenticated ? '/dashboard' : '/login',

      refreshListenable: authProvider,

      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;

        final location = state.matchedLocation;

        final isLogin = location == '/login';

        if (!isAuthenticated && !isLogin) {
          return '/login';
        }

        if (isAuthenticated && isLogin) {
          return '/dashboard';
        }

        /*
         * Todas as rotas iniciadas em
         * /usuarios são exclusivas
         * para ADMIN.
         */
        if (location.startsWith('/usuarios') && !authProvider.isAdmin) {
          return '/dashboard';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) {
            return const LoginPage();
          },
        ),

        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            return const DashboardPage();
          },
        ),

        GoRoute(
          path: '/clientes',
          builder: (context, state) {
            return const ClientesPage();
          },
        ),

        GoRoute(
          path: '/agendamentos',
          builder: (context, state) {
            return const AgendamentosPage();
          },
        ),

        GoRoute(
          path: '/servicos',
          builder: (context, state) {
            return const ServicosPage();
          },
        ),

        GoRoute(
          path: '/estoque',
          builder: (context, state) {
            return const EstoquePage();
          },
        ),

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
      ],
    );
  }
}
