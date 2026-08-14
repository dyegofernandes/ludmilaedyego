import { useEffect, useRef, useState } from 'react';

type Props = {
  src: string;
  alt?: string;
  onClose: () => void;
};

const MIN = 1;
const MAX = 5;

type Transform = { scale: number; x: number; y: number };

export function FotoLightbox({ src, alt = 'Foto', onClose }: Props) {
  const stageRef = useRef<HTMLDivElement>(null);
  const t = useRef<Transform>({ scale: 1, x: 0, y: 0 });
  const [view, setView] = useState<Transform>(t.current);
  const drag = useRef<{
    pointerId: number;
    startX: number;
    startY: number;
    origX: number;
    origY: number;
  } | null>(null);
  const pinch = useRef<{ dist: number; scale: number } | null>(null);
  const pointers = useRef(new Map<number, { x: number; y: number }>());

  function commit(next: Transform) {
    t.current = next;
    setView(next);
  }

  function clampPan(scale: number, nx: number, ny: number) {
    if (scale <= 1) return { x: 0, y: 0 };
    const el = stageRef.current;
    if (!el) return { x: nx, y: ny };
    const maxX = (el.clientWidth * (scale - 1)) / 2;
    const maxY = (el.clientHeight * (scale - 1)) / 2;
    return {
      x: Math.max(-maxX, Math.min(maxX, nx)),
      y: Math.max(-maxY, Math.min(maxY, ny)),
    };
  }

  function applyScale(nextScaleRaw: number, cx?: number, cy?: number) {
    const prev = t.current;
    const nextScale = Math.min(MAX, Math.max(MIN, nextScaleRaw));
    const el = stageRef.current;
    if (el && cx != null && cy != null && nextScale !== prev.scale) {
      const rect = el.getBoundingClientRect();
      const ox = cx - rect.left - rect.width / 2;
      const oy = cy - rect.top - rect.height / 2;
      const ratio = nextScale / prev.scale;
      const pan = clampPan(
        nextScale,
        ox - (ox - prev.x) * ratio,
        oy - (oy - prev.y) * ratio,
      );
      commit({ scale: nextScale, ...pan });
      return;
    }
    if (nextScale <= 1) {
      commit({ scale: 1, x: 0, y: 0 });
      return;
    }
    commit({ ...clampPan(nextScale, prev.x, prev.y), scale: nextScale });
  }

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    window.addEventListener('keydown', onKey);
    const el = stageRef.current;
    function onNativeWheel(e: WheelEvent) {
      e.preventDefault();
      const delta = e.deltaY > 0 ? -0.18 : 0.18;
      applyScale(t.current.scale + delta, e.clientX, e.clientY);
    }
    el?.addEventListener('wheel', onNativeWheel, { passive: false });
    return () => {
      window.removeEventListener('keydown', onKey);
      el?.removeEventListener('wheel', onNativeWheel);
    };
  }, [onClose]);

  function onDoubleClick(e: React.MouseEvent) {
    e.stopPropagation();
    if (t.current.scale > 1.1) commit({ scale: 1, x: 0, y: 0 });
    else applyScale(2.4, e.clientX, e.clientY);
  }

  function onPointerDown(e: React.PointerEvent) {
    e.stopPropagation();
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.current.size === 2) {
      const pts = [...pointers.current.values()];
      pinch.current = {
        dist: Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y),
        scale: t.current.scale,
      };
      drag.current = null;
      return;
    }
    if (t.current.scale > 1) {
      drag.current = {
        pointerId: e.pointerId,
        startX: e.clientX,
        startY: e.clientY,
        origX: t.current.x,
        origY: t.current.y,
      };
    }
  }

  function onPointerMove(e: React.PointerEvent) {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.current.size === 2 && pinch.current) {
      const pts = [...pointers.current.values()];
      const dist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
      applyScale((pinch.current.scale * dist) / pinch.current.dist);
      return;
    }
    const d = drag.current;
    if (!d || d.pointerId !== e.pointerId) return;
    commit({
      scale: t.current.scale,
      ...clampPan(
        t.current.scale,
        d.origX + (e.clientX - d.startX),
        d.origY + (e.clientY - d.startY),
      ),
    });
  }

  function onPointerUp(e: React.PointerEvent) {
    pointers.current.delete(e.pointerId);
    if (drag.current?.pointerId === e.pointerId) drag.current = null;
    if (pointers.current.size < 2) pinch.current = null;
  }

  return (
    <div className="foto-lightbox" role="dialog" aria-modal="true">
      <button
        type="button"
        className="foto-lightbox__backdrop"
        aria-label="Fechar"
        onClick={onClose}
      />
      <button
        type="button"
        className="foto-lightbox__close"
        onClick={onClose}
        aria-label="Fechar"
      >
        ×
      </button>
      <div
        ref={stageRef}
        className={`foto-lightbox__stage${view.scale > 1 ? ' is-zoomed' : ''}`}
        onDoubleClick={onDoubleClick}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
      >
        <img
          src={src}
          alt={alt}
          draggable={false}
          style={{
            transform: `translate(${view.x}px, ${view.y}px) scale(${view.scale})`,
          }}
        />
      </div>
      <p className="foto-lightbox__hint">
        Role ou dê pinça para zoom · arraste para mover · clique duas vezes · Esc
        fecha
      </p>
    </div>
  );
}
