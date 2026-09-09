import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Convite via WhatsApp: arte + link clicável de presença.
class InviteMessage {
  static const conviteCardAsset = 'assets/welcome/convite-card.jpg';

  /// Só o link — no WhatsApp fica clicável e abre a confirmação.
  static String caption({required String link}) => link.trim();

  /// Só dígitos; se BR com 10–11 dígitos, prefixa 55.
  static String? normalizePhone(String? telefone) {
    if (telefone == null) return null;
    var digits = telefone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length == 10 || digits.length == 11) {
      digits = '55$digits';
    }
    return digits;
  }

  static Uri whatsAppUri({
    required String telefone,
    required String mensagem,
  }) {
    final phone = normalizePhone(telefone);
    if (phone == null) {
      throw ArgumentError('Cadastre o telefone do convidado');
    }
    return Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(mensagem)}',
    );
  }

  static Future<void> shareConvite({
    required String caption,
    required String telefone,
  }) async {
    final dir = await getTemporaryDirectory();

    final cardData = await rootBundle.load(conviteCardAsset);
    final cardPath = '${dir.path}/ludmila-dyego-convite.jpg';
    await File(cardPath).writeAsBytes(
      cardData.buffer.asUint8List(),
      flush: true,
    );

    // 1º a foto (sem o link, para não virar legenda)
    await Share.shareXFiles(
      [XFile(cardPath, mimeType: 'image/jpeg')],
      subject: 'Convite Ludmila & Dyego',
    );

    // 2º o link na conversa do telefone cadastrado
    await launchUrl(
      whatsAppUri(telefone: telefone, mensagem: caption),
      mode: LaunchMode.externalApplication,
    );
  }
}
