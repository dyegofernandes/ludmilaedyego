import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late final TextEditingController _noivo;
  late final TextEditingController _noiva;
  late final TextEditingController _localCerimonia;
  late final TextEditingController _enderecoCerimonia;
  late final TextEditingController _localFesta;
  late final TextEditingController _enderecoFesta;
  late final TextEditingController _whats;
  late final TextEditingController _msg;
  DateTime? _data;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<AppStore>().config;
    _noivo = TextEditingController(text: c.nomeNoivo);
    _noiva = TextEditingController(text: c.nomeNoiva);
    _localCerimonia = TextEditingController(
      text: c.localCerimonia ?? c.local ?? '',
    );
    _enderecoCerimonia =
        TextEditingController(text: c.enderecoCerimonia ?? '');
    _localFesta = TextEditingController(text: c.localFesta ?? '');
    _enderecoFesta = TextEditingController(text: c.enderecoFesta ?? '');
    _whats = TextEditingController(text: c.whatsapp ?? '');
    _msg = TextEditingController(text: c.mensagemBoasVindas ?? '');
    _data = c.dataCerimonia;
  }

  @override
  void dispose() {
    _noivo.dispose();
    _noiva.dispose();
    _localCerimonia.dispose();
    _enderecoCerimonia.dispose();
    _localFesta.dispose();
    _enderecoFesta.dispose();
    _whats.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _data ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_data ?? d),
    );
    setState(() {
      _data = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? 16,
        t?.minute ?? 0,
      );
    });
  }

  Future<void> _uploadCapa() async {
    final store = context.read<AppStore>();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final err = await store.uploadCapa(bytes, file.name.split('.').last);
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    final store = context.read<AppStore>();
    final next = store.config.copyWith(
      nomeNoivo: _noivo.text.trim(),
      nomeNoiva: _noiva.text.trim(),
      local: _localCerimonia.text.trim(),
      localCerimonia: _localCerimonia.text.trim(),
      enderecoCerimonia: _enderecoCerimonia.text.trim(),
      localFesta: _localFesta.text.trim(),
      enderecoFesta: _enderecoFesta.text.trim(),
      whatsapp: _whats.text.trim(),
      mensagemBoasVindas: _msg.text.trim(),
      dataCerimonia: _data,
    );
    final err = await store.salvarConfig(next);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Configurações salvas.')),
    );
  }

  Future<void> _formCardapio([CardapioItem? existing]) async {
    final store = context.read<AppStore>();
    final titulo = TextEditingController(text: existing?.titulo ?? '');
    final desc = TextEditingController(text: existing?.descricao ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Item do cardápio' : 'Editar item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titulo,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await store.removerCardapio(existing.id);
                if (ctx.mounted) Navigator.pop(ctx, false);
              },
              child: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.upsertCardapio(CardapioItem(
      id: existing?.id ?? store.novoId(),
      titulo: titulo.text.trim(),
      descricao: desc.text.trim().isEmpty ? null : desc.text.trim(),
      ordem: existing?.ordem ?? store.cardapio.length + 1,
    ));
  }

  Future<void> _formAtracao([AtracaoItem? existing]) async {
    final store = context.read<AppStore>();
    final titulo = TextEditingController(text: existing?.titulo ?? '');
    final desc = TextEditingController(text: existing?.descricao ?? '');
    final horario = TextEditingController(text: existing?.horario ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nova atração' : 'Editar atração'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titulo,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: horario,
              decoration: const InputDecoration(labelText: 'Horário'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await store.removerAtracao(existing.id);
                if (ctx.mounted) Navigator.pop(ctx, false);
              },
              child: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.upsertAtracao(AtracaoItem(
      id: existing?.id ?? store.novoId(),
      titulo: titulo.text.trim(),
      descricao: desc.text.trim().isEmpty ? null : desc.text.trim(),
      horario: horario.text.trim().isEmpty ? null : horario.text.trim(),
      ordem: existing?.ordem ?? store.atracoes.length + 1,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Configurações',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ContaSection(isNoivo: store.isNoivo),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: store.config.capaUrl == null
                      ? Container(
                          color: AppColors.surfaceElevated,
                          alignment: Alignment.center,
                          child: const Text('Sem capa'),
                        )
                      : Image.network(
                          store.config.capaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: _uploadCapa,
                child: const Text('Alterar capa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noivo,
                decoration: const InputDecoration(labelText: 'Nome do noivo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noiva,
                decoration: const InputDecoration(labelText: 'Nome da noiva'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data da cerimônia'),
                subtitle: Text(formatDateTime(_data)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              Text(
                'Locais',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _localCerimonia,
                decoration:
                    const InputDecoration(labelText: 'Nome do local — cerimônia'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _enderecoCerimonia,
                decoration: const InputDecoration(
                  labelText: 'Endereço completo — cerimônia (Maps)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _localFesta,
                decoration:
                    const InputDecoration(labelText: 'Nome do local — festa'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _enderecoFesta,
                decoration: const InputDecoration(
                  labelText: 'Endereço completo — festa (Maps)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _whats,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _msg,
                decoration:
                    const InputDecoration(labelText: 'Mensagem de boas-vindas'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _salvar,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar dados do evento'),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cardápio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _formCardapio(),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              ...store.cardapio.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.titulo),
                  subtitle: item.descricao != null ? Text(item.descricao!) : null,
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _formCardapio(item),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Atrações',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _formAtracao(),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              ...store.atracoes.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.titulo),
                  subtitle: Text(
                    [
                      if (item.horario != null) item.horario!,
                      if (item.descricao != null) item.descricao!,
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _formAtracao(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContaSection extends StatefulWidget {
  const _ContaSection({required this.isNoivo});

  final bool isNoivo;

  @override
  State<_ContaSection> createState() => _ContaSectionState();
}

class _ContaSectionState extends State<_ContaSection> {
  List<Profile> _noivos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.isNoivo) {
      setState(() => _loading = false);
      return;
    }
    try {
      final list = await context.read<AppStore>().listNoivos();
      if (mounted) setState(() {
        _noivos = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cadastrarNoiva() async {
    final nome = TextEditingController();
    final email = TextEditingController();
    final senha = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadastrar noiva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ela terá o mesmo acesso total que você e entra na aba Noivos.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome da noiva'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: senha,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha inicial'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await context.read<AppStore>().inviteParceiro(
          nome: nome.text,
          email: email.text,
          password: senha.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Noiva cadastrada com sucesso.')),
    );
    if (err == null) await _load();
  }

  Future<void> _trocarSenha() async {
    final atual = TextEditingController();
    final nova = TextEditingController();
    final confirma = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trocar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: atual,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nova,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirma,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirmar nova senha'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (nova.text != confirma.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas novas não coincidem.')),
      );
      return;
    }
    final err = await context.read<AppStore>().changePassword(
          currentPassword: atual.text,
          newPassword: nova.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Senha alterada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppStore>().currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Conta', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                me?.email.isNotEmpty == true
                    ? 'Logado: ${me!.email}'
                    : 'Logado: ${me?.nome ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                )
              else if (widget.isNoivo) ...[
                const SizedBox(height: 10),
                Text(
                  'Acessos do casal (${_noivos.length}/2)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                ..._noivos.map(
                  (u) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.person_outline),
                    title: Text(u.nome),
                    subtitle: Text(u.email.isEmpty ? 'Sem e-mail' : u.email),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _trocarSenha,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Trocar senha'),
                  ),
                  if (widget.isNoivo && _noivos.length < 2)
                    FilledButton.icon(
                      onPressed: _cadastrarNoiva,
                      icon: const Icon(Icons.favorite_outline),
                      label: const Text('Cadastrar noiva'),
                    ),
                ],
              ),
              if (widget.isNoivo) ...[
                const SizedBox(height: 8),
                Text(
                  'A noiva recebe o mesmo acesso total (role noivo).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
