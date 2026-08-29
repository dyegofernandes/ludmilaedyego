class WelcomeSlide {
  const WelcomeSlide({required this.asset, required this.phrase});

  final String asset;
  final String phrase;
}

/// Data do casamento — slide de abertura e vídeo do convite.
const weddingDateLabel = '17 de outubro de 2026';
const weddingDateShort = '17/10/2026';

const welcomeSlides = [
  WelcomeSlide(
    asset: 'assets/welcome/01.jpg',
    phrase: 'Bem-vindos ao nosso casamento',
  ),
  WelcomeSlide(
    asset: 'assets/welcome/02.jpg',
    phrase: 'Ludmila & Dyego',
  ),
  WelcomeSlide(
    asset: 'assets/welcome/03.jpg',
    phrase: 'Com alegria, convidamos vocês a celebrar conosco',
  ),
  WelcomeSlide(
    asset: 'assets/welcome/04.jpg',
    phrase: 'Um dia para lembrar — e compartilhar o amor',
  ),
  WelcomeSlide(
    asset: 'assets/welcome/05.jpg',
    phrase: 'Sua presença é o nosso maior presente',
  ),
  WelcomeSlide(
    asset: 'assets/welcome/06.jpg',
    phrase: 'Que este momento fique no coração de todos',
  ),
  WelcomeSlide(
    asset: 'assets/welcome/07.jpg',
    phrase: 'Celebremos juntos o início da nossa história',
  ),
  WelcomeSlide(
    asset: 'assets/welcome/08.jpg',
    phrase: 'Obrigado por fazer parte deste sonho',
  ),
];
