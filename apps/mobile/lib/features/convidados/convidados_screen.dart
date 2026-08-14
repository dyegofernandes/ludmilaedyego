import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class ConvidadosScreen extends StatefulWidget {
  const ConvidadosScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ConvidadosScreen> createState() => _ConvidadosScreenState();
}

class _ConvidadosScreenState extends State<ConvidadosScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.convidados.where((c) {
      if (_q.isEmpty) return true;
      final s = _q.toLowerCase();
      return c.nome.toLowerCase().contains(s) ||
          (c.email?.toLowerCase().contains(s) ?? false) ||
          (c.telefone?.contains(s) ?? false) ||
          (c.token?.toLowerCase().contains(s) ?? false);
    }).toList();

    final body = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                if (!widget.embedded)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    'Convidados',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _form(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total ${store.totalConvidadosPessoas} · '
                  'Adultos ${store.totalAdultos} · '
                  'Crianças ${store.totalCriancas}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confirmados: ${store.totalConfirmadosPessoas} '
                  '(${store.totalConfirmadosAdultos} adultos / '
                  '${store.totalConfirmadosCriancas} crianças)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  'RSVP · Sim ${store.countRsvp(RsvpStatus.sim)} · '
                  'Não ${store.countRsvp(RsvpStatus.nao)} · '
                  'Talvez ${store.countRsvp(RsvpStatus.talvez)} · '
                  'Pendente ${store.countRsvp(RsvpStatus.pendente)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.nome),
                  subtitle: Text(
                    [
                      c.lado.label,
                      if (c.ehCrianca) 'Criança',
                      '${c.totalPessoas} pessoa(s)',
                      if (c.acompanhantes > 0)
                        c.acompanhantesLista
                            .map((a) => '${a.nome} (${a.rsvp.label})')
                            .join(', '),
                      c.rsvp.label,
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    tooltip: 'Copiar link',
                    icon: const Icon(Icons.link),
                    onPressed: () => _copiarLink(context, c),
                  ),
                  onTap: () => _form(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(body: SoftBackground(child: body));
  }

  Future<void> _form(BuildContext context, [Convidado? existing]) async {
    final store = context.read<AppStore>();
    final nome = TextEditingController(text: existing?.nome ?? '');
    final tel = TextEditingController(text: existing?.telefone ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final mesa = TextEditingController(text: existing?.mesa ?? '');
    var lado = existing?.lado ?? LadoConvidado.ambos;
    var rsvp = existing?.rsvp ?? RsvpStatus.pendente;
    var ehCrianca = existing?.ehCrianca ?? false;
    final acompanham = [
      for (final a in existing?.acompanhantesLista ?? <Acompanhante>[])
        Acompanhante(id: a.id, nome: a.nome, tipo: a.tipo, rsvp: a.rsvp),
    ];
    var token = existing?.token;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title:
              Text(existing == null ? 'Novo convidado' : 'Editar convidado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nome,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tel,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mesa,
                  decoration: const InputDecoration(labelText: 'Mesa'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<LadoConvidado>(
                  initialValue: lado,
                  decoration: const InputDecoration(labelText: 'Lado'),
                  items: LadoConvidado.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => lado = v!),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('É criança'),
                  value: ehCrianca,
                  onChanged: (v) => setLocal(() => ehCrianca = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<RsvpStatus>(
                  initialValue: rsvp,
                  decoration: const InputDecoration(labelText: 'RSVP'),
                  items: RsvpStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => rsvp = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Acompanhantes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setLocal(() {
                        acompanham.add(Acompanhante(
                          id: store.novoId(),
                          nome: '',
                          tipo: TipoAcompanhante.amigo,
                        ));
                      }),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                if (acompanham.isEmpty)
                  Text(
                    'Nenhum acompanhante. Toque em Adicionar para liberar os campos.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                for (var i = 0; i < acompanham.length; i++) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Acompanhante ${i + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  setLocal(() => acompanham.removeAt(i)),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        TextFormField(
                          initialValue: acompanham[i].nome,
                          decoration:
                              const InputDecoration(labelText: 'Nome'),
                          onChanged: (v) => acompanham[i].nome = v,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TipoAcompanhante>(
                          initialValue: acompanham[i].tipo,
                          decoration: const InputDecoration(
                            labelText: 'Tipo (filho = criança)',
                          ),
                          items: TipoAcompanhante.values
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => acompanham[i].tipo = v!),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<RsvpStatus>(
                          initialValue: acompanham[i].rsvp,
                          decoration: const InputDecoration(
                            labelText: 'RSVP desta pessoa',
                          ),
                          items: RsvpStatus.values
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => acompanham[i].rsvp = v!),
                        ),
                      ],
                    ),
                  ),
                ],
                if (token != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Link de acesso'),
                    subtitle: Text(
                      AppConstants.conviteUrl(token!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: AppConstants.conviteUrl(token!),
                          ),
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Link copiado')),
                          );
                        }
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await store.regenerarTokenConvidado(existing!.id);
                      setLocal(() => token = store.convidadoById(existing.id)?.token);
                    },
                    child: const Text('Gerar novo link'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await store.removerConvidado(existing.id);
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
    final limpos = acompanham
        .where((a) => a.nome.trim().isNotEmpty)
        .map(
          (a) => Acompanhante(
            id: a.id,
            nome: a.nome.trim(),
            tipo: a.tipo,
            rsvp: a.rsvp,
          ),
        )
        .toList();
    final c = Convidado(
      id: existing?.id ?? store.novoId(),
      nome: nome.text.trim(),
      telefone: tel.text.trim().isEmpty ? null : tel.text.trim(),
      email: email.text.trim().isEmpty ? null : email.text.trim(),
      mesa: mesa.text.trim().isEmpty ? null : mesa.text.trim(),
      lado: lado,
      ehCrianca: ehCrianca,
      rsvp: rsvp,
      acompanhantesLista: limpos,
      userId: existing?.userId,
      observacoes: existing?.observacoes,
      token: token ?? store.gerarToken(prefix: 'CONV'),
    );
    final err = await store.upsertConvidado(c);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else if (context.mounted) {
      final match = store.convidados.where((x) => x.nome == c.nome);
      final code = (match.isNotEmpty ? match.first.token : null) ?? c.token;
      final link = code == null ? null : AppConstants.conviteUrl(code);
      if (link != null) {
        await Clipboard.setData(ClipboardData(text: link));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            link == null ? 'Convidado salvo' : 'Link copiado: $link',
          ),
        ),
      );
    }
  }

  Future<void> _copiarLink(BuildContext context, Convidado c) async {
    final store = context.read<AppStore>();
    var code = c.token;
    if (code == null || code.isEmpty) {
      await store.regenerarTokenConvidado(c.id);
      code = store.convidadoById(c.id)?.token;
    }
    if (code == null || !context.mounted) return;
    final link = AppConstants.conviteUrl(code);
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link copiado')),
      );
    }
  }
}
