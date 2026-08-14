import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../formatters.dart';
import '../maps.dart';
import '../theme.dart';
import '../../data/app_store.dart';

/// Data, locais (card estilo mapa → Google Maps), cardápio e atrações.
class EventoInfoSection extends StatelessWidget {
  const EventoInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = store.config;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('O grande dia', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (c.dataCerimonia != null)
          _InfoRow(
            icon: Icons.calendar_month_outlined,
            title: 'Data e horário',
            subtitle: formatDateTime(c.dataCerimonia),
          ),
        if (c.cerimoniaTitulo.isNotEmpty ||
            c.cerimoniaEnderecoMaps.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Cerimônia', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          MapPlaceCard(
            titulo: c.cerimoniaTitulo.isNotEmpty
                ? c.cerimoniaTitulo
                : 'Local da cerimônia',
            endereco: c.cerimoniaEnderecoMaps,
          ),
        ],
        if (c.festaTitulo.isNotEmpty ||
            c.festaEnderecoMaps.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Festa', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          MapPlaceCard(
            titulo:
                c.festaTitulo.isNotEmpty ? c.festaTitulo : 'Local da festa',
            endereco: c.festaEnderecoMaps,
          ),
        ],
        if (store.cardapio.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Cardápio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...store.cardapio.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.restaurant_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.descricao?.isNotEmpty == true)
                          Text(
                            item.descricao!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (store.atracoes.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Atrações', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...store.atracoes.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.horario?.isNotEmpty == true)
                          Text(
                            item.horario!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        if (item.descricao?.isNotEmpty == true)
                          Text(
                            item.descricao!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card visual estilo mapa (sem token). Toque abre o Google Maps.
class MapPlaceCard extends StatelessWidget {
  const MapPlaceCard({
    super.key,
    required this.titulo,
    required this.endereco,
  });

  final String titulo;
  final String endereco;

  @override
  Widget build(BuildContext context) {
    final query = endereco.isNotEmpty ? endereco : titulo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: query.isEmpty ? null : () => abrirGoogleMaps(query),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: CustomPaint(
                    painter: _FauxMapPainter(),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 40,
                            color: AppColors.primaryDark.withValues(alpha: 0.95),
                          ),
                          Text(
                            'Toque para abrir no Maps',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (endereco.isNotEmpty && endereco != titulo) ...[
                      const SizedBox(height: 4),
                      Text(
                        endereco,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Abrir no Google Maps',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
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

class _FauxMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEFE8DC);
    canvas.drawRect(Offset.zero & size, bg);

    final road = Paint()
      ..color = const Color(0xFFD9CFBE)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadThin = Paint()
      ..color = const Color(0xFFE4DCCC)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Ruas diagonais / grade suave (visual de mapa, sem API).
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.55), road);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.45), roadThin);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.4, size.height), roadThin);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.55, size.height), road);

    final park = Paint()..color = const Color(0xFFD5E0C8).withValues(alpha: 0.7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.2, size.height * 0.25),
        width: 70,
        height: 40,
      ),
      park,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.82, size.height * 0.75),
        width: 60,
        height: 36,
      ),
      park,
    );

    final ring = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 6),
      28,
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
