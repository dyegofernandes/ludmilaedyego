import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/app_store.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/cerimonialista/cerimonialista_shell.dart';
import 'features/configuracoes/configuracoes_screen.dart';
import 'features/convidado_home/convidado_home_screen.dart';
import 'features/convidados/convidados_screen.dart';
import 'features/despedida/despedida_screen.dart';
import 'features/fotos/fotos_screen.dart';
import 'features/gastos/gastos_screen.dart';
import 'features/home_noivo/noivo_shell.dart';
import 'features/padrinho_home/padrinho_home_screen.dart';
import 'features/padrinhos/padrinhos_screen.dart';
import 'features/presentes/presentes_screen.dart';
import 'features/tarefas/tarefas_screen.dart';
import 'features/tokens/tokens_acesso_screen.dart';

class CasamentoApp extends StatefulWidget {
  const CasamentoApp({super.key});

  @override
  State<CasamentoApp> createState() => _CasamentoAppState();
}

class _CasamentoAppState extends State<CasamentoApp> {
  late final AppStore _store;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _store = AppStore()..init();
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: _store,
      redirect: (context, state) {
        final logged = _store.isLoggedIn;
        final loc = state.matchedLocation;
        final authRoutes = {'/', '/login'};
        if (!_store.ready) return null;
        if (!logged && !authRoutes.contains(loc)) return '/login';
        if (logged && (loc == '/login' || loc == '/')) {
          return _store.homeRouteForRole();
        }
        if (logged && loc.startsWith('/noivo') && !_store.isNoivo) {
          return _store.homeRouteForRole();
        }
        if (logged &&
            loc.startsWith('/cerimonialista') &&
            !_store.isCerimonialista) {
          return _store.homeRouteForRole();
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/noivo', builder: (_, _) => const NoivoShell()),
        GoRoute(
          path: '/cerimonialista',
          builder: (_, _) => const CerimonialistaShell(),
        ),
        GoRoute(
          path: '/convidado',
          builder: (_, _) => const ConvidadoHomeScreen(),
        ),
        GoRoute(
          path: '/padrinho',
          builder: (_, _) => const PadrinhoHomeScreen(),
        ),
        GoRoute(path: '/gastos', builder: (_, _) => const GastosScreen()),
        GoRoute(path: '/tarefas', builder: (_, _) => const TarefasScreen()),
        GoRoute(path: '/agenda', builder: (_, _) => const AgendaScreen()),
        GoRoute(
          path: '/convidados',
          builder: (_, _) => const ConvidadosScreen(),
        ),
        GoRoute(
          path: '/padrinhos',
          builder: (_, _) => const PadrinhosScreen(),
        ),
        GoRoute(
          path: '/presentes',
          builder: (_, _) => const PresentesScreen(),
        ),
        GoRoute(
          path: '/presentes-guest',
          builder: (_, _) => const PresentesScreen(guestMode: true),
        ),
        GoRoute(path: '/fotos', builder: (_, _) => const FotosScreen()),
        GoRoute(
          path: '/fotos-guest',
          builder: (_, _) => const FotosScreen(guestMode: true),
        ),
        GoRoute(
          path: '/configuracoes',
          builder: (_, _) => const ConfiguracoesScreen(),
        ),
        GoRoute(
          path: '/minhas-tarefas',
          builder: (_, _) => const TarefasScreen(padrinhoMode: true),
        ),
        GoRoute(
          path: '/tokens',
          builder: (_, _) => const TokensAcessoScreen(),
        ),
        GoRoute(
          path: '/despedida',
          builder: (_, _) => const DespedidaScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _store,
      child: MaterialApp.router(
        title: 'Ludmila & Dyego',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
