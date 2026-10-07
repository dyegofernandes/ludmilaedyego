export type LadoMesa = 'noiva' | 'noivo' | 'ambos';

export type FamiliaMesa = {
  lado: LadoMesa;
  pessoas: { chave: string }[];
};

export type AlocacaoMesa = {
  chave: string;
  mesa: number;
  cadeira: number;
};

type Assento = { mesa: number; cadeira: number };

function contar(familias: FamiliaMesa[], lado: LadoMesa) {
  return familias
    .filter((f) => f.lado === lado)
    .reduce((n, f) => n + f.pessoas.length, 0);
}

function livres(
  ocupado: (string | null)[][],
  mesasAlvo: number[],
): Assento[] {
  const out: Assento[] = [];
  for (const mesa of mesasAlvo) {
    const row = ocupado[mesa - 1];
    if (!row) continue;
    for (let c = 0; c < row.length; c++) {
      if (row[c] == null) out.push({ mesa, cadeira: c + 1 });
    }
  }
  return out;
}

function ocupar(ocupado: (string | null)[][], assento: Assento, chave: string) {
  ocupado[assento.mesa - 1][assento.cadeira - 1] = chave;
}

/** Sentam juntas na mesma mesa quando cabe. O que não couber volta na lista. */
function colocarFamilias(
  familias: FamiliaMesa[],
  ocupado: (string | null)[][],
  mesasAlvo: number[],
): { chave: string }[] {
  const resto: { chave: string }[] = [];
  const ordenadas = [...familias].sort(
    (a, b) => b.pessoas.length - a.pessoas.length,
  );
  for (const fam of ordenadas) {
    if (fam.pessoas.length === 0 || mesasAlvo.length === 0) {
      resto.push(...fam.pessoas);
      continue;
    }
    const seats = livres(ocupado, mesasAlvo);
    let juntas = false;
    for (const mesa of mesasAlvo) {
      const naMesa = seats.filter((s) => s.mesa === mesa);
      if (naMesa.length >= fam.pessoas.length) {
        fam.pessoas.forEach((p, i) => ocupar(ocupado, naMesa[i], p.chave));
        juntas = true;
        break;
      }
    }
    if (juntas) continue;
    const todas = livres(ocupado, mesasAlvo);
    fam.pessoas.forEach((p, i) => {
      if (i < todas.length) ocupar(ocupado, todas[i], p.chave);
      else resto.push(p);
    });
  }
  return resto;
}

function colocarPessoas(
  pessoas: { chave: string }[],
  ocupado: (string | null)[][],
  mesasAlvo: number[],
) {
  const seats = livres(ocupado, mesasAlvo);
  pessoas.forEach((p, i) => {
    if (i < seats.length) ocupar(ocupado, seats[i], p.chave);
  });
}

export function distribuirFamilias(
  familias: FamiliaMesa[],
  quantidadeMesas: number,
  cadeirasPorMesa: number,
): { alocacoes: AlocacaoMesa[]; ladoMesas: LadoMesa[] } {
  const mesas = Math.floor(quantidadeMesas);
  const cadeiras = Math.floor(cadeirasPorMesa);
  if (mesas < 1 || cadeiras < 1) {
    return { alocacoes: [], ladoMesas: [] };
  }

  const nNoiva = contar(familias, 'noiva');
  const nNoivo = contar(familias, 'noivo');
  let mesasNoiva = 0;
  const ladoMesas: LadoMesa[] = [];

  if (nNoiva > 0 && nNoivo > 0) {
    mesasNoiva = Math.round((mesas * nNoiva) / (nNoiva + nNoivo));
    if (mesasNoiva < 1) mesasNoiva = 1;
    if (mesasNoiva > mesas - 1) mesasNoiva = mesas - 1;
    for (let i = 1; i <= mesas; i++) {
      ladoMesas.push(i <= mesasNoiva ? 'noiva' : 'noivo');
    }
  } else if (nNoiva > 0) {
    mesasNoiva = mesas;
    for (let i = 0; i < mesas; i++) ladoMesas.push('noiva');
  } else if (nNoivo > 0) {
    mesasNoiva = 0;
    for (let i = 0; i < mesas; i++) ladoMesas.push('noivo');
  } else {
    for (let i = 0; i < mesas; i++) ladoMesas.push('ambos');
  }

  const ocupado: (string | null)[][] = Array.from({ length: mesas }, () =>
    Array.from({ length: cadeiras }, () => null),
  );
  const todas = Array.from({ length: mesas }, (_, i) => i + 1);
  const daNoiva = todas.filter((_, i) => ladoMesas[i] === 'noiva');
  const doNoivo = todas.filter((_, i) => ladoMesas[i] === 'noivo');

  const noiva = familias.filter((f) => f.lado === 'noiva');
  const noivo = familias.filter((f) => f.lado === 'noivo');
  const ambos = familias.filter((f) => f.lado === 'ambos');

  const restoNoiva = colocarFamilias(noiva, ocupado, daNoiva);
  const restoNoivo = colocarFamilias(noivo, ocupado, doNoivo);
  colocarPessoas([...restoNoiva, ...restoNoivo], ocupado, todas);
  colocarFamilias(ambos, ocupado, todas);

  const alocacoes: AlocacaoMesa[] = [];
  for (let m = 0; m < mesas; m++) {
    for (let c = 0; c < cadeiras; c++) {
      const chave = ocupado[m][c];
      if (chave) alocacoes.push({ chave, mesa: m + 1, cadeira: c + 1 });
    }
  }
  return { alocacoes, ladoMesas };
}
