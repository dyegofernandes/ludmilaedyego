import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Convite via WhatsApp: vídeo + arte + link clicável de presença.
class InviteMessage {
  static const conviteCardAsset = 'assets/welcome/convite-card.jpg';
  static const welcomeVideoAsset = 'assets/welcome/convite-slide.mp4';

  /// Só o link — no WhatsApp fica clicável e abre a confirmação.
  static String caption({required String link}) => link.trim();

  static Future<ShareResult> shareSlideshowAlbum({
    required String caption,
  }) async {
    final dir = await getTemporaryDirectory();

    final cardData = await rootBundle.load(conviteCardAsset);
    final cardPath = '${dir.path}/ludmila-dyego-convite.jpg';
    await File(cardPath).writeAsBytes(cardData.buffer.asUint8List(), flush: true);

    final videoData = await rootBundle.load(welcomeVideoAsset);
    final videoPath = '${dir.path}/ludmila-dyego-convite.mp4';
    await File(videoPath).writeAsBytes(videoData.buffer.asUint8List(), flush: true);

    // Ordem desejada na conversa: 1) convite  2) vídeo  3) link (legenda).
    // O WhatsApp costuma inverter a lista de arquivos — por isso vídeo vem antes no array.
    return Share.shareXFiles(
      [
        XFile(videoPath, mimeType: 'video/mp4'),
        XFile(cardPath, mimeType: 'image/jpeg'),
      ],
      text: caption,
      subject: 'Convite Ludmila & Dyego',
    );
  }
}
