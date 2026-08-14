import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../../data/app_store.dart';

/// Convidado/padrinho cria e-mail e senha depois de entrar pelo link.
class CadastroConvidadoBlock extends StatefulWidget {
  const CadastroConvidadoBlock({super.key});

  @override
  State<CadastroConvidadoBlock> createState() => _CadastroConvidadoBlockState();
}

class _CadastroConvidadoBlockState extends State<CadastroConvidadoBlock> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  bool _open = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_senha.text != _confirma.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.')),
      );
      return;
    }
    setState(() => _busy = true);
    final store = context.read<AppStore>();
    final err = await store.completarCadastroConvidado(
      email: _email.text,
      password: _senha.text,
      nome: store.currentUser?.nome,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ??
              'Cadastro criado. Da próxima vez entre em Convidados com e-mail e senha.',
        ),
      ),
    );
    if (err == null) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppStore>().currentUser;
    final precisa = user != null &&
        !user.temSenha &&
        (user.isConvidado || user.isPadrinho);
    if (!precisa) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crie seu cadastro',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Assim você entra sempre com e-mail e senha, só na área de convidado.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
        ),
        const SizedBox(height: 12),
        if (!_open)
          FilledButton(
            onPressed: () => setState(() => _open = true),
            child: const Text('Cadastrar e-mail e senha'),
          )
        else ...[
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _senha,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirma,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _salvar,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Criar cadastro'),
          ),
        ],
      ],
    );
  }
}
