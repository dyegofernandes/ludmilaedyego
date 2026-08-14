import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class DespedidaScreen extends StatefulWidget {
  const DespedidaScreen({super.key});

  @override
  State<DespedidaScreen> createState() => _DespedidaScreenState();
}

class _DespedidaScreenState extends State<DespedidaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        'Despedida de solteiro',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Do noivo'),
                  Tab(text: 'Da noiva'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: const [
                    _DespedidaTab(tipo: TipoDespedida.solteiro),
                    _DespedidaTab(tipo: TipoDespedida.solteira),
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

class _DespedidaTab extends StatelessWidget {
  const _DespedidaTab({required this.tipo});

  final TipoDespedida tipo;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final evento = store.eventoDespedida(tipo);
    final lista = store.participantesDespedida(tipo);
    final confirmados = lista.where((p) => p.confirmado).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tipo.label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => _editarEvento(context, evento),
              child: const Text('Editar evento'),
            ),
          ],
        ),
        if (evento?.data != null)
          Text(
            formatDateTime(evento!.data),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
        if (evento?.local?.isNotEmpty == true)
          Text(
            evento!.local!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),
        if (evento?.endereco?.isNotEmpty == true)
          Text(
            evento!.endereco!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.muted),
          ),
        if (evento?.observacoes?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(evento!.observacoes!),
        ],
        const SizedBox(height: 16),
        Text(
          'Participantes: ${lista.length} · Confirmados: $confirmados',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _adicionarDaLista(context),
          icon: const Icon(Icons.people_outline),
          label: const Text('Adicionar da lista de convidados'),
        ),
        const SizedBox(height: 12),
        if (lista.isEmpty)
          Text(
            'Ninguém cadastrado ainda. Selecione convidados da lista.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          )
        else
          ...lista.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                store.convidadoById(p.convidadoId ?? '')?.nome ?? p.nome,
              ),
              subtitle: Text(
                [
                  store.convidadoById(p.convidadoId ?? '')?.telefone ??
                      p.telefone,
                  p.confirmado ? 'Confirmado' : 'Pendente',
                ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
              ),
              trailing: StatusChip(
                label: p.confirmado ? 'Sim' : 'Não',
                color: p.confirmado ? AppColors.success : AppColors.warning,
              ),
              onTap: () => _formParticipante(context, p),
            ),
          ),
      ],
    );
  }

  Future<void> _editarEvento(
    BuildContext context,
    DespedidaEvento? existing,
  ) async {
    final store = context.read<AppStore>();
    final local = TextEditingController(text: existing?.local ?? '');
    final endereco = TextEditingController(text: existing?.endereco ?? '');
    final obs = TextEditingController(text: existing?.observacoes ?? '');
    var data = existing?.data;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(tipo.label),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data'),
                  subtitle: Text(formatDateTime(data)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: data ?? now.add(const Duration(days: 30)),
                      firstDate: now.subtract(const Duration(days: 30)),
                      lastDate: now.add(const Duration(days: 365 * 2)),
                    );
                    if (d == null || !ctx.mounted) return;
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(data ?? d),
                    );
                    setLocal(() {
                      data = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t?.hour ?? 15,
                        t?.minute ?? 0,
                      );
                    });
                  },
                ),
                TextField(
                  controller: local,
                  decoration: const InputDecoration(labelText: 'Local'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: endereco,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: obs,
                  decoration: const InputDecoration(labelText: 'Observações'),
                  maxLines: 2,
                ),
              ],
            ),
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
      ),
    );
    if (ok != true) return;
    await store.salvarDespedidaEvento(DespedidaEvento(
      tipo: tipo,
      data: data,
      local: local.text.trim().isEmpty ? null : local.text.trim(),
      endereco: endereco.text.trim().isEmpty ? null : endereco.text.trim(),
      observacoes: obs.text.trim().isEmpty ? null : obs.text.trim(),
    ));
  }

  Future<void> _formParticipante(
    BuildContext context,
    DespedidaParticipante existing,
  ) async {
    final store = context.read<AppStore>();
    final conv = store.convidadoById(existing.convidadoId ?? '');
    final obs = TextEditingController(text: existing.observacoes ?? '');
    var confirmado = existing.confirmado;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar participante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv?.nome ?? existing.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if ((conv?.telefone ?? existing.telefone)?.isNotEmpty == true)
                  Text(
                    conv?.telefone ?? existing.telefone!,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: obs,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Confirmado'),
                  value: confirmado,
                  onChanged: (v) => setLocal(() => confirmado = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await store.removerDespedidaParticipante(existing.id);
                if (ctx.mounted) Navigator.pop(ctx, false);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: AppColors.danger),
              ),
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
      ),
    );
    if (ok != true) return;
    final nome = conv?.nome ?? existing.nome;
    final tel = conv?.telefone ?? existing.telefone;
    await store.upsertDespedidaParticipante(DespedidaParticipante(
      id: existing.id,
      nome: nome,
      telefone: tel,
      observacoes: obs.text.trim().isEmpty ? null : obs.text.trim(),
      confirmado: confirmado,
      tipo: tipo,
      convidadoId: existing.convidadoId ?? conv?.id,
    ));
  }

  Future<void> _adicionarDaLista(BuildContext context) async {
    final store = context.read<AppStore>();
    final ja = store
        .participantesDespedida(tipo)
        .map((p) => p.convidadoId)
        .whereType<String>()
        .toSet();
    final disponiveis =
        store.convidados.where((c) => !ja.contains(c.id)).toList();
    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum convidado disponível.')),
      );
      return;
    }

    String? selected = disponiveis.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Selecionar convidado'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            items: disponiveis
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                .toList(),
            onChanged: (v) => setLocal(() => selected = v),
            decoration: const InputDecoration(labelText: 'Convidado'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == null) return;
    final c = store.convidadoById(selected!);
    if (c == null) return;
    await store.upsertDespedidaParticipante(DespedidaParticipante(
      id: store.novoId(),
      nome: c.nome,
      telefone: c.telefone,
      tipo: tipo,
      confirmado: false,
      convidadoId: c.id,
    ));
  }
}
