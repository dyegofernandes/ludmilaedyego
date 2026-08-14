export function BrandLogo({
  size = 120,
  className = '',
}: {
  size?: number;
  className?: string;
}) {
  return (
    <img
      src="/logo_ludmila_dyego.png"
      alt="Ludmila & Dyego"
      className={`brand-logo ${className}`.trim()}
      width={size}
      height={size}
      style={{ width: size, height: size, objectFit: 'contain' }}
    />
  );
}

/** Header com a logo completa (já inclui LUDMILA & DYEGO). */
export function BrandHeader({
  subtitle,
  large = false,
  compact = false,
}: {
  subtitle?: string;
  large?: boolean;
  /** Barra compacta: logo menor à esquerda */
  compact?: boolean;
}) {
  if (compact) {
    return (
      <div className="brand-header brand-header--compact">
        <BrandLogo size={64} />
        {subtitle ? <div className="brand-header__sub">{subtitle}</div> : null}
      </div>
    );
  }
  return (
    <div className={`brand-header${large ? ' brand-header--large' : ''}`}>
      <BrandLogo size={large ? 168 : 96} />
      {subtitle ? <div className="brand-header__sub">{subtitle}</div> : null}
    </div>
  );
}
