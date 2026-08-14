import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({
    super.key,
    this.embedded = false,
    this.canEdit = true,
  });

  final bool embedded;
  final bool canEdit;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _selected;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final doDia = store.compromissosDoDia(_selected);
    final canEdit = widget.canEdit && store.isGestao;

    final body = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            child: Row(
              children: [
                if (!widget.embedded)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    'Agenda',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (canEdit)
                  IconButton(
                    onPressed: () => _form(context, day: _selected),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
          ),
          _MonthHeader(
            month: _visibleMonth,
            onPrev: () => setState(() {
              _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month - 1);
            }),
            onNext: () => setState(() {
              _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month + 1);
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _CalendarGrid(
              month: _visibleMonth,
              selected: _selected,
              markedDays: {
                for (final c in store.compromissos)
                  DateTime(c.inicio.year, c.inicio.month, c.inicio.day),
              },
              onSelect: (d) => setState(() => _selected = d),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_selected),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: doDia.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum compromisso neste dia.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: doDia.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = doDia[i];
                      final hora = DateFormat('HH:mm').format(c.inicio);
                      final fim = c.fim != null
                          ? ' – ${DateFormat('HH:mm').format(c.fim!)}'
                          : '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            hora,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(c.titulo),
                        subtitle: Text(
                          [
                            '$hora$fim',
                            if (c.local != null && c.local!.isNotEmpty) c.local!,
                          ].join(' · '),
                        ),
                        onTap: canEdit ? () => _form(context, existing: c) : null,
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

  Future<void> _form(
    BuildContext context, {
    Compromisso? existing,
    DateTime? day,
  }) async {
    final store = context.read<AppStore>();
    final base = existing?.inicio ??
        DateTime(
          (day ?? _selected).year,
          (day ?? _selected).month,
          (day ?? _selected).day,
          10,
        );
    final titulo = TextEditingController(text: existing?.titulo ?? '');
    final desc = TextEditingController(text: existing?.descricao ?? '');
    final local = TextEditingController(text: existing?.local ?? '');
    var inicio = base;
    var fim = existing?.fim ?? base.add(const Duration(hours: 1));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Novo compromisso' : 'Editar compromisso',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titulo,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ex.: Experimentar o bolo',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: local,
                  decoration: const InputDecoration(labelText: 'Local'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Início'),
                  subtitle: Text(formatDateTime(inicio)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: inicio,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (d == null || !ctx.mounted) return;
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(inicio),
                    );
                    setLocal(() {
                      inicio = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t?.hour ?? inicio.hour,
                        t?.minute ?? inicio.minute,
                      );
                      if (!fim.isAfter(inicio)) {
                        fim = inicio.add(const Duration(hours: 1));
                      }
                    });
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fim'),
                  subtitle: Text(formatDateTime(fim)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fim,
                      firstDate: inicio,
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (d == null || !ctx.mounted) return;
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(fim),
                    );
                    setLocal(() {
                      fim = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t?.hour ?? fim.hour,
                        t?.minute ?? fim.minute,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await store.removerCompromisso(existing.id);
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
    if (titulo.text.trim().isEmpty) return;
    final c = Compromisso(
      id: existing?.id ?? store.novoId(),
      titulo: titulo.text.trim(),
      descricao: desc.text.trim().isEmpty ? null : desc.text.trim(),
      local: local.text.trim().isEmpty ? null : local.text.trim(),
      inicio: inicio,
      fim: fim,
      criadoPor: existing?.criadoPor ?? store.currentUser?.id,
    );
    final err = await store.upsertCompromisso(c);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else if (mounted) {
      setState(() {
        _selected = DateTime(inicio.year, inicio.month, inicio.day);
        _visibleMonth = DateTime(inicio.year, inicio.month);
      });
    }
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy', 'pt_BR').format(month);
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            label[0].toUpperCase() + label.substring(1),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.markedDays,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Set<DateTime> markedDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-based: weekday 1=Mon ... 7=Sun
    final startOffset = first.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          children: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(
            children: List.generate(7, (col) {
              final cell = r * 7 + col;
              final dayNum = cell - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final date = DateTime(month.year, month.month, dayNum);
              final isSelected = date == selected;
              final hasEvent = markedDays.contains(date);
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(date),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.ink,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (hasEvent)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
