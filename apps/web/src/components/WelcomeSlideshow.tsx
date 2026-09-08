import { useCallback, useEffect, useRef, useState } from 'react';

export const WELCOME_PENDING_KEY = 'welcome_pending';

/** Data do casamento — exibida no slide e no vídeo do convite. */
export const WEDDING_DATE_LABEL = '17 de outubro de 2026';
export const WEDDING_DATE_SHORT = '17/10/2026';

/** Trilha do slideshow (substitua o MP3 por Perfect acústico licenciado). */
export const WELCOME_MUSIC = '/welcome/bg-music.mp3';

let sharedAudio: HTMLAudioElement | null = null;

export function getWelcomeAudio() {
  if (typeof Audio === 'undefined') return null;
  if (!sharedAudio) {
    sharedAudio = new Audio(WELCOME_MUSIC);
    sharedAudio.loop = true;
    sharedAudio.volume = 0.55;
    sharedAudio.preload = 'auto';
  }
  return sharedAudio;
}

export function unlockWelcomeAudio() {
  const a = getWelcomeAudio();
  if (!a) return Promise.resolve();
  return a.play().catch(() => undefined);
}

export function stopWelcomeAudio() {
  if (!sharedAudio) return;
  sharedAudio.pause();
  sharedAudio.currentTime = 0;
}

export const welcomeSlides = [
  {
    src: '/welcome/01.jpg',
    phrase: 'Bem-vindos ao nosso casamento',
    eyebrow: 'Ludmila & Dyego',
  },
  { src: '/welcome/02.jpg', phrase: 'Ludmila & Dyego' },
  {
    src: '/welcome/03.jpg',
    phrase: 'Com alegria, convidamos vocês a celebrar conosco',
  },
  {
    src: '/welcome/04.jpg',
    phrase: 'Um dia para lembrar — e compartilhar o amor',
  },
  {
    src: '/welcome/05.jpg',
    phrase: 'Sua presença é o nosso maior presente',
  },
  {
    src: '/welcome/06.jpg',
    phrase: 'Que este momento fique no coração de todos',
  },
  {
    src: '/welcome/07.jpg',
    phrase: 'Celebremos juntos o início da nossa história',
  },
  {
    src: '/welcome/08.jpg',
    phrase: 'Obrigado por fazer parte deste sonho',
  },
] as const;

type Props = {
  onDone: () => void;
  /** Se false, no último slide espera o botão (não avança sozinho). Default true. */
  autoFinish?: boolean;
  skipLabel?: string;
  continueLabel?: string;
};

export function WelcomeSlideshow({
  onDone,
  autoFinish = true,
  skipLabel = 'Pular',
  continueLabel = 'Continuar',
}: Props) {
  const [index, setIndex] = useState(0);
  const [musicOn, setMusicOn] = useState(true);
  const musicOnRef = useRef(true);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const last = index >= welcomeSlides.length - 1;
  const slide = welcomeSlides[index];
  musicOnRef.current = musicOn;

  const stopMusic = useCallback(() => {
    stopWelcomeAudio();
  }, []);

  const finish = useCallback(() => {
    stopMusic();
    onDone();
  }, [onDone, stopMusic]);

  const goNext = useCallback(() => {
    setIndex((i) => Math.min(i + 1, welcomeSlides.length - 1));
  }, []);

  useEffect(() => {
    const audio = getWelcomeAudio();
    audioRef.current = audio;
    if (!audio) return;
    const tryPlay = () => {
      if (!musicOnRef.current) return;
      void audio.play().then(() => setMusicOn(true));
    };
    tryPlay();
    window.addEventListener('pointerdown', tryPlay, true);
    window.addEventListener('keydown', tryPlay, true);
    return () => {
      window.removeEventListener('pointerdown', tryPlay, true);
      window.removeEventListener('keydown', tryPlay, true);
      audioRef.current = null;
    };
  }, []);

  useEffect(() => {
    const a = audioRef.current ?? getWelcomeAudio();
    if (!a) return;
    if (musicOn) {
      void a.play().then(() => setMusicOn(true));
    } else {
      a.pause();
    }
  }, [musicOn]);

  useEffect(() => {
    const id = window.setTimeout(() => {
      if (index >= welcomeSlides.length - 1) {
        if (autoFinish) finish();
        return;
      }
      setIndex((i) => i + 1);
    }, 4500);
    return () => window.clearTimeout(id);
  }, [index, finish, autoFinish]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') finish();
      if (e.key === 'ArrowRight') {
        if (last) finish();
        else goNext();
      }
      if (e.key === 'ArrowLeft') setIndex((i) => Math.max(0, i - 1));
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [goNext, last, finish]);

  return (
    <div className="welcome-slideshow" role="dialog" aria-modal="true">
      {welcomeSlides.map((s, i) => (
        <img
          key={s.src}
          src={s.src}
          alt=""
          className={`welcome-slideshow__img${i === index ? ' is-active' : ''}`}
          draggable={false}
        />
      ))}
      <div className="welcome-slideshow__shade" />
      <button
        type="button"
        className="welcome-slideshow__music"
        onClick={() => setMusicOn((v) => !v)}
        aria-label={musicOn ? 'Pausar música' : 'Tocar música'}
      >
        {musicOn ? '♪' : '♬'}
      </button>
      <button
        type="button"
        className="welcome-slideshow__skip"
        onClick={finish}
      >
        {skipLabel}
      </button>
      <div className="welcome-slideshow__copy">
        {'eyebrow' in slide && slide.eyebrow ? (
          <p className="welcome-slideshow__eyebrow">{slide.eyebrow}</p>
        ) : null}
        <h2 className={index === 1 ? 'is-names' : undefined}>{slide.phrase}</h2>
        <span className="welcome-slideshow__rule" />
        <p className="welcome-slideshow__date">{WEDDING_DATE_LABEL}</p>
      </div>
      <div className="welcome-slideshow__footer">
        <div className="welcome-slideshow__dots" aria-hidden="true">
          {welcomeSlides.map((s, i) => (
            <button
              key={s.src}
              type="button"
              className={i === index ? 'is-active' : ''}
              onClick={() => setIndex(i)}
              aria-label={`Slide ${i + 1}`}
            />
          ))}
        </div>
        {last ? (
          <button
            type="button"
            className="welcome-slideshow__continue"
            onClick={finish}
          >
            {continueLabel}
          </button>
        ) : (
          <button
            type="button"
            className="welcome-slideshow__next"
            onClick={goNext}
            aria-label="Próximo"
          >
            ›
          </button>
        )}
      </div>
      <button
        type="button"
        className="welcome-slideshow__hit"
        aria-label="Próximo slide"
        onClick={() => {
          if (last) finish();
          else goNext();
        }}
      />
    </div>
  );
}

export function markWelcomePending() {
  sessionStorage.setItem(WELCOME_PENDING_KEY, '1');
}

export function clearWelcomePending() {
  sessionStorage.removeItem(WELCOME_PENDING_KEY);
}

export function isWelcomePending() {
  return sessionStorage.getItem(WELCOME_PENDING_KEY) === '1';
}
