/** Arte do convite (imagem) enviada no WhatsApp. */
export const CONVITE_CARD_IMAGE = '/welcome/convite-card.jpg';

/** Vídeo do slideshow de boas-vindas. */
export const CONVITE_SLIDE_VIDEO = '/welcome/convite-slide.mp4';

/**
 * Mensagem do WhatsApp: só o link clicável de confirmação.
 * O texto do convite já está na arte enviada junto.
 */
export function buildConviteWhatsAppCaption(input: { link: string }) {
  return input.link.trim();
}

/** Só dígitos; se BR com 10–11 dígitos, prefixa 55. */
export function normalizeWhatsAppPhone(telefone?: string | null): string | null {
  if (!telefone) return null;
  let digits = telefone.replace(/\D/g, '');
  if (!digits) return null;
  if (digits.length === 10 || digits.length === 11) {
    digits = `55${digits}`;
  }
  return digits;
}

/** Desktop: preferir WhatsApp Web no navegador no fallback (só texto). */
export function prefersWhatsAppWeb() {
  if (typeof navigator === 'undefined') return true;
  const ua = navigator.userAgent || '';
  const mobile = /Android|iPhone|iPad|iPod|Mobile/i.test(ua);
  return !mobile;
}

export function whatsappConviteUrl(input: {
  telefone?: string | null;
  mensagem: string;
  /** Força WhatsApp Web (padrão no desktop). */
  web?: boolean;
}) {
  const text = encodeURIComponent(input.mensagem);
  const phone = normalizeWhatsAppPhone(input.telefone);
  const useWeb = input.web ?? prefersWhatsAppWeb();

  if (useWeb && phone) {
    return `https://web.whatsapp.com/send?phone=${phone}&text=${text}`;
  }
  if (phone) return `https://wa.me/${phone}?text=${text}`;
  if (useWeb) {
    return `https://web.whatsapp.com/send?text=${text}`;
  }
  return `https://api.whatsapp.com/send?text=${text}`;
}

function canShareFiles(files: File[]) {
  const nav = navigator as Navigator & {
    canShare?: (data: ShareData) => boolean;
  };
  try {
    return typeof nav.share === 'function' && !!nav.canShare?.({ files });
  } catch {
    return false;
  }
}

function downloadFile(file: File) {
  const url = URL.createObjectURL(file);
  const a = document.createElement('a');
  a.href = url;
  a.download = file.name;
  a.rel = 'noopener';
  document.body.appendChild(a);
  a.click();
  a.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 2000);
}

/**
 * Envia vídeo + arte do convite + link de confirmação.
 * No WhatsApp o URL sozinho vira link clicável.
 */
export async function shareConviteSlideshow(input: {
  caption: string;
  telefone?: string | null;
}): Promise<'shared' | 'whatsapp-web'> {
  const [resCard, resVideo] = await Promise.all([
    fetch(CONVITE_CARD_IMAGE),
    fetch(CONVITE_SLIDE_VIDEO),
  ]);
  if (!resCard.ok) throw new Error('Arte do convite não encontrada');
  if (!resVideo.ok) throw new Error('Vídeo do convite não encontrado');

  const [blobCard, blobVideo] = await Promise.all([
    resCard.blob(),
    resVideo.blob(),
  ]);

  const card = new File([blobCard], 'ludmila-dyego-convite.jpg', {
    type: 'image/jpeg',
  });
  const video = new File([blobVideo], 'ludmila-dyego-convite.mp4', {
    type: 'video/mp4',
  });
  // Ordem desejada na conversa: 1) convite  2) vídeo  3) link.
  // O WhatsApp costuma inverter a lista de arquivos e colocar o texto no fim como legenda.
  const files = [video, card];
  const mensagemFallback = `(Anexe nesta ordem: 1º a imagem do convite, 2º o vídeo)\n\n${input.caption}`;

  if (canShareFiles(files)) {
    try {
      await navigator.share({
        files,
        text: input.caption,
        title: 'Convite Ludmila & Dyego',
      });
      return 'shared';
    } catch (e) {
      if (e instanceof Error && e.name === 'AbortError') throw e;
    }
  }

  if (canShareFiles([card])) {
    try {
      await navigator.share({
        files: [card],
        text: input.caption,
        title: 'Convite Ludmila & Dyego',
      });
      downloadFile(video);
      return 'shared';
    } catch (e) {
      if (e instanceof Error && e.name === 'AbortError') throw e;
    }
  }

  // Fallback: baixa na ordem correta (convite → vídeo) e abre o WhatsApp com o link.
  downloadFile(card);
  downloadFile(video);
  window.open(
    whatsappConviteUrl({
      telefone: input.telefone,
      mensagem: mensagemFallback,
      web: prefersWhatsAppWeb(),
    }),
    '_blank',
    'noopener,noreferrer',
  );
  return 'whatsapp-web';
}
