import { useCallback, useEffect, useState } from 'react';

export const WELCOME_PENDING_KEY = 'welcome_pending';

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
};

export function WelcomeSlideshow({ onDone }: Props) {
  const [index, setIndex] = useState(0);
  const last = index >= welcomeSlides.length - 1;
  const slide = welcomeSlides[index];

  const goNext = useCallback(() => {
    setIndex((i) => Math.min(i + 1, welcomeSlides.length - 1));
  }, []);

  useEffect(() => {
    const id = window.setTimeout(() => {
      if (index >= welcomeSlides.length - 1) onDone();
      else setIndex((i) => i + 1);
    }, 4500);
    return () => window.clearTimeout(id);
  }, [index, onDone]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onDone();
      if (e.key === 'ArrowRight') {
        if (last) onDone();
        else goNext();
      }
      if (e.key === 'ArrowLeft') setIndex((i) => Math.max(0, i - 1));
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [goNext, last, onDone]);

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
        className="welcome-slideshow__skip"
        onClick={onDone}
      >
        Pular
      </button>
      <div className="welcome-slideshow__copy">
        {'eyebrow' in slide && slide.eyebrow ? (
          <p className="welcome-slideshow__eyebrow">{slide.eyebrow}</p>
        ) : null}
        <h2 className={index === 1 ? 'is-names' : undefined}>{slide.phrase}</h2>
        <span className="welcome-slideshow__rule" />
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
            onClick={onDone}
          >
            Continuar
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
          if (last) onDone();
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
