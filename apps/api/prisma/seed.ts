import { PrismaClient, UserRole, TipoPadrinho, LadoConvidado, RsvpStatus, TipoDespedida } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('123456', 10);

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
      nomeNoivo: 'Dyego',
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
      email: 'dyego.fernandes.vieira@gmail.com',
      passwordHash,
      role: UserRole.noivo,
      nome: 'Dyego',
    },
  });

  const carlos = await prisma.convidado.create({
    data: {
      nome: 'Carlos Silva',
      telefone: '11999990001',
      email: 'carlos@email.com',
      lado: LadoConvidado.noivo,
      token: 'PAD-CARLOS',
      rsvp: RsvpStatus.sim,
      acompanhantes: [
        { id: 'ac1', nome: 'Marina Silva', tipo: 'esposa' },
      ],
    },
  });

  const julia = await prisma.convidado.create({
    data: {
      nome: 'Julia Santos',
      telefone: '11999990002',
      email: 'julia@email.com',
      lado: LadoConvidado.noiva,
      token: 'CONV-JULI',
      rsvp: RsvpStatus.pendente,
      acompanhantes: [],
    },
  });

  await prisma.convidado.create({
    data: {
      nome: 'Pedro Oliveira',
      lado: LadoConvidado.ambos,
      rsvp: RsvpStatus.talvez,
      acompanhantes: [
        { id: 'ac2', nome: 'Lucas Oliveira', tipo: 'filho' },
      ],
    },
  });

  const padrinhoCarlos = await prisma.padrinho.create({
    data: {
      convidadoId: carlos.id,
      tipo: TipoPadrinho.padrinho,
      papel: 'Padrinho do noivo',
      ordem: 1,
    },
  });

  await prisma.user.create({
    data: {
      role: UserRole.padrinho,
      nome: carlos.nome,
      convidadoId: carlos.id,
    },
  });

  await prisma.user.create({
    data: {
      role: UserRole.convidado,
      nome: julia.nome,
      convidadoId: julia.id,
    },
  });

  await prisma.conviteAcesso.createMany({
    data: [
      {
        token: 'CERIM-LD26',
        role: UserRole.cerimonialista,
        nome: 'Cerimonialista',
        ativo: true,
      },
      {
        token: 'PAD-CARLOS',
        role: UserRole.padrinho,
        nome: carlos.nome,
        convidadoId: carlos.id,
        ativo: true,
      },
      {
        token: 'CONV-JULI',
        role: UserRole.convidado,
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
        tipo: TipoDespedida.solteiro,
        data: new Date('2026-10-20T20:00:00-03:00'),
        local: 'Churrascaria do Zé',
        endereco: 'Rua das Flores, 100',
      },
      {
        tipo: TipoDespedida.solteira,
        data: new Date('2026-10-25T15:00:00-03:00'),
        local: 'Spa Relax',
        endereco: 'Av. Bem-estar, 50',
      },
    ],
  });

  console.log('Seed OK');
  console.log({ configId: config.id, noivo: noivo.email });
  console.log('Login: dyego.fernandes.vieira@gmail.com / 123456');
  console.log('Tokens: CERIM-LD26 | PAD-CARLOS | CONV-JULI');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
