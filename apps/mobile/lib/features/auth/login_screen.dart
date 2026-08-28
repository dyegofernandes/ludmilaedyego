import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _codigo = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _email.dispose();
    _password.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final store = context.read<AppStore>();
    final err = await store.login(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    _goAfterLogin(store);
  }

  Future<void> _loginConvite() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final store = context.read<AppStore>();
    final err = await store.loginWithToken(_codigo.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    _goAfterLogin(store);
  }

  void _goAfterLogin(AppStore store) {
    if (store.isConvidado || store.isPadrinho) {
      context.go('/welcome');
    } else {
      context.go(store.homeRouteForRole());
    }
  }

  Widget _errorBox() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
    );
  }

  Widget _loadingBtn(String label, VoidCallback? onPressed) {
    return FilledButton(
      onPressed: _loading ? null : onPressed,
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      body: SoftBackground(
        capaUrl: store.config.capaUrl,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            children: [
              BrandHeader(config: store.config, hero: true),
              const SizedBox(height: 16),
              Text(
                store.config.mensagemBoasVindas ??
                    'Entre para gerenciar ou acompanhar o casamento.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabs,
                      labelColor: AppColors.primaryDark,
                      unselectedLabelColor: AppColors.muted,
                      indicatorColor: AppColors.primary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Noivos'),
                        Tab(text: 'Convidados'),
                      ],
                      onTap: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: 18),
                    AnimatedBuilder(
                      animation: _tabs,
                      builder: (context, _) {
                        if (_tabs.index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration:
                                    const InputDecoration(labelText: 'E-mail'),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _password,
                                obscureText: true,
                                decoration:
                                    const InputDecoration(labelText: 'Senha'),
                              ),
                              _errorBox(),
                              const SizedBox(height: 22),
                              _loadingBtn('Entrar', _loginEmail),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Se já criou cadastro, entre com e-mail e senha. No primeiro acesso, use o código do convite.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.ink),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration:
                                  const InputDecoration(labelText: 'E-mail'),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              decoration:
                                  const InputDecoration(labelText: 'Senha'),
                            ),
                            _errorBox(),
                            const SizedBox(height: 22),
                            _loadingBtn('Entrar', _loginEmail),
                            const SizedBox(height: 22),
                            Text(
                              'Primeiro acesso',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _codigo,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Código do convite',
                                hintText: 'Ex.: CONV-JULI',
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _loading ? null : _loginConvite,
                              child: const Text('Entrar com o convite'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
