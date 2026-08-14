/**
 * Seed completo (APAGA dados). Usado só com RUN_SEED=true.
 */
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash(
    process.env.BOOTSTRAP_NOIVO_PASSWORD || '123456',
    10,
  );
  const email =
    process.env.BOOTSTRAP_NOIVO_EMAIL || 'dyego.fernandes.vieira@gmail.com';
  const nome = process.env.BOOTSTRAP_NOIVO_NOME || 'Dyego';

  await prisma.despedidaParticipante.deleteMany();
  await prisma.despedidaEvento.deleteMany();
  await prisma.presente.deleteMany();
  await prisma.foto.deleteMany();
  await prisma.conviteAcesso.deleteMany();
  await prisma.atracaoItem.deleteMany();
  await prisma.cardapioItem.deleteMany();
  await prisma.compromisso.deleteMany();
  await prisma.tarefa.deleteMany();
  await prisma.padrinho.deleteMany();
  await prisma.user.deleteMany();
  await prisma.convidado.deleteMany();
  await prisma.gasto.deleteMany();
  await prisma.casamentoConfig.deleteMany();

  const config = await prisma.casamentoConfig.create({
    data: {
      nomeNoivo: nome,
      nomeNoiva: 'Ludmila',
      dataCerimonia: new Date('2026-11-14T16:00:00-03:00'),
      local: 'Igreja Nossa Senhora',
      localCerimonia: 'Igreja Nossa Senhora',
      enderecoCerimonia: 'Praça da Matriz, Centro',
      localFesta: 'Espaço Jardim das Flores',
      enderecoFesta: 'Av. das Palmeiras, 1200',
      mensagemBoasVindas: 'Bem-vindos ao nosso casamento!',
      whatsapp: '',
    },
  });

  const noivo = await prisma.user.create({
    data: {
      email,
      passwordHash,
      role: 'noivo',
      nome,
    },
  });

  const carlos = await prisma.convidado.create({
    data: {
      nome: 'Carlos Silva',
      telefone: '11999990001',
      email: 'carlos@email.com',
      lado: 'noivo',
      token: 'PAD-CARLOS',
      rsvp: 'sim',
      acompanhantes: [{ id: 'ac1', nome: 'Marina Silva', tipo: 'esposa' }],
    },
  });

  const julia = await prisma.convidado.create({
    data: {
      nome: 'Julia Santos',
      telefone: '11999990002',
      email: 'julia@email.com',
      lado: 'noiva',
      token: 'CONV-JULI',
      rsvp: 'pendente',
      acompanhantes: [],
    },
  });

  await prisma.convidado.create({
    data: {
      nome: 'Pedro Oliveira',
      lado: 'ambos',
      rsvp: 'talvez',
      acompanhantes: [{ id: 'ac2', nome: 'Lucas Oliveira', tipo: 'filho' }],
    },
  });

  const padrinhoCarlos = await prisma.padrinho.create({
    data: {
      convidadoId: carlos.id,
      tipo: 'padrinho',
      papel: 'Padrinho do noivo',
      ordem: 1,
    },
  });

  await prisma.user.create({
    data: {
      role: 'padrinho',
      nome: carlos.nome,
      convidadoId: carlos.id,
    },
  });

  await prisma.user.create({
    data: {
      role: 'convidado',
      nome: julia.nome,
      convidadoId: julia.id,
    },
  });

  await prisma.conviteAcesso.createMany({
    data: [
      {
        token: 'CERIM-LD26',
        role: 'cerimonialista',
        nome: 'Cerimonialista',
        ativo: true,
      },
      {
        token: 'PAD-CARLOS',
        role: 'padrinho',
        nome: carlos.nome,
        convidadoId: carlos.id,
        ativo: true,
      },
      {
        token: 'CONV-JULI',
        role: 'convidado',
        nome: julia.nome,
        convidadoId: julia.id,
        ativo: true,
      },
    ],
  });

  await prisma.gasto.createMany({
    data: [
      {
        descricao: 'Buffet',
        categoria: 'Alimentação',
        valorPrevisto: 18000,
        valorReal: 5000,
        status: 'pago',
      },
      {
        descricao: 'Decoração floral',
        categoria: 'Decoração',
        valorPrevisto: 4500,
        status: 'pendente',
      },
      {
        descricao: 'Fotografia',
        categoria: 'Mídia',
        valorPrevisto: 3200,
        status: 'pendente',
      },
    ],
  });

  await prisma.tarefa.createMany({
    data: [
      {
        titulo: 'Experimentar o bolo',
        descricao: 'Agendar degustação com a confeitaria',
        status: 'pendente',
        prioridade: 'alta',
        destino: 'noivos',
        criadoPor: noivo.id,
      },
      {
        titulo: 'Confirmar trajes',
        status: 'aprovado',
        prioridade: 'media',
        destino: 'padrinho',
        padrinhoId: padrinhoCarlos.id,
      },
    ],
  });

  await prisma.compromisso.create({
    data: {
      titulo: 'Prova do vestido',
      inicio: new Date('2026-09-10T14:00:00-03:00'),
      local: 'Atelier',
      criadoPor: noivo.id,
    },
  });

  await prisma.cardapioItem.createMany({
    data: [
      { titulo: 'Entrada', descricao: 'Canapés variados', ordem: 1 },
      { titulo: 'Prato principal', descricao: 'Filé ao molho madeira', ordem: 2 },
      { titulo: 'Sobremesa', descricao: 'Bolo de casamento', ordem: 3 },
    ],
  });

  await prisma.atracaoItem.createMany({
    data: [
      { titulo: 'Cerimônia', horario: '16:00', ordem: 1 },
      { titulo: 'Coquetel', horario: '17:30', ordem: 2 },
      { titulo: 'Festa e DJ', horario: '19:00', ordem: 3 },
    ],
  });

  await prisma.presente.createMany({
    data: [
      { nome: 'Jogo de panelas', valorEstimado: 450, ativo: true },
      { nome: 'Air fryer', valorEstimado: 600, ativo: true },
      { nome: 'Lua de mel — jantar', valorEstimado: 300, ativo: true },
    ],
  });

  await prisma.despedidaEvento.createMany({
    data: [
      {
        tipo: 'solteiro',
        data: new Date('2026-10-20T20:00:00-03:00'),
        local: 'Churrascaria do Zé',
        endereco: 'Rua das Flores, 100',
      },
      {
        tipo: 'solteira',
        data: new Date('2026-10-25T15:00:00-03:00'),
        local: 'Spa Relax',
        endereco: 'Av. Bem-estar, 50',
      },
    ],
  });

  console.log('[seed] OK', { configId: config.id, noivo: noivo.email });
  console.log(`[seed] Login: ${email} / (senha BOOTSTRAP_NOIVO_PASSWORD)`);
  console.log('[seed] Tokens: CERIM-LD26 | PAD-CARLOS | CONV-JULI');
}

main()
  .catch((e) => {
    console.error('[seed]', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
