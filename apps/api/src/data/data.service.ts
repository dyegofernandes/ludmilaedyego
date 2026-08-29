import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  DestinoTarefa,
  FotoTipo,
  LadoConvidado,
  Prisma,
  Prioridade,
  RsvpStatus,
  TipoDespedida,
  TipoPadrinho,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { randomBytes } from 'crypto';
import { existsSync, unlinkSync } from 'fs';
import { basename, join } from 'path';
import { publicFotoUrl } from './foto-upload';

@Injectable()
export class DataService {
  constructor(private readonly prisma: PrismaService) {}

  private async requireUser(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  private isGestao(role: UserRole) {
    return role === UserRole.noivo || role === UserRole.cerimonialista;
  }

  private async assertGestao(userId: string) {
    const user = await this.requireUser(userId);
    if (!this.isGestao(user.role)) {
      throw new ForbiddenException('Acesso restrito à gestão');
    }
    return user;
  }

  private dec(v: Prisma.Decimal | null | undefined): number | null {
    if (v == null) return null;
    return Number(v);
  }

  private mapConfig(c: any) {
    return {
      id: c.id,
      nomeNoivo: c.nomeNoivo,
      nomeNoiva: c.nomeNoiva,
      dataCerimonia: c.dataCerimonia,
      local: c.local,
      localCerimonia: c.localCerimonia,
      enderecoCerimonia: c.enderecoCerimonia,
      localFesta: c.localFesta,
      enderecoFesta: c.enderecoFesta,
      capaUrl: c.capaUrl,
      whatsapp: c.whatsapp,
      mensagemBoasVindas: c.mensagemBoasVindas,
    };
  }

  private normalizeAcomps(raw: unknown, convidadoId?: string) {
    if (!Array.isArray(raw)) return [];
    return raw
      .filter((a) => a && String(a.nome ?? '').trim())
      .map((a: any, i: number) => ({
        id: String(a.id || (convidadoId ? `ac-${convidadoId}-${i}` : `ac-${i}`)),
        nome: String(a.nome).trim(),
        tipo:
          a.tipo === 'esposa' || a.tipo === 'filho' ? a.tipo : 'amigo',
        rsvp: ['sim', 'nao', 'talvez', 'pendente'].includes(a.rsvp)
          ? a.rsvp
          : 'pendente',
      }));
  }

  private mapConvidado(c: any) {
    return {
      id: c.id,
      nome: c.nome,
      telefone: c.telefone,
      email: c.email,
      lado: c.lado,
      mesa: c.mesa,
      ehCrianca: c.ehCrianca === true,
      acompanhantesLista: this.normalizeAcomps(c.acompanhantes, c.id),
      rsvp: c.rsvp,
      observacoes: c.observacoes,
      token: c.token,
      userId: c.user?.id ?? null,
    };
  }

  async bootstrap(userId: string) {
    const user = await this.requireUser(userId);
    const gestao = this.isGestao(user.role);

    const config =
      (await this.prisma.casamentoConfig.findFirst()) ??
      (await this.prisma.casamentoConfig.create({
        data: { nomeNoivo: 'Dyego', nomeNoiva: 'Ludmila' },
      }));

    const gastos = gestao
      ? await this.prisma.gasto.findMany({ orderBy: { createdAt: 'desc' } })
      : [];
    const tarefas = await this.prisma.tarefa.findMany({
      orderBy: { createdAt: 'desc' },
    });
    const compromissos = await this.prisma.compromisso.findMany({
      orderBy: { inicio: 'asc' },
    });
    const convidados =
      gestao ||
      user.role === UserRole.padrinho ||
      user.role === UserRole.convidado
        ? await this.prisma.convidado.findMany({
            include: { user: { select: { id: true } } },
            orderBy: { nome: 'asc' },
          })
        : [];
    const padrinhos = await this.prisma.padrinho.findMany({
      orderBy: { ordem: 'asc' },
    });
    const presentes = await this.prisma.presente.findMany({
      where: gestao ? undefined : { ativo: true },
      orderBy: { createdAt: 'desc' },
    });
    const fotos = await this.prisma.foto.findMany({
      where: gestao ? undefined : { publico: true },
      orderBy: { createdAt: 'desc' },
    });
    const cardapio = await this.prisma.cardapioItem.findMany({
      orderBy: { ordem: 'asc' },
    });
    const atracoes = await this.prisma.atracaoItem.findMany({
      orderBy: { ordem: 'asc' },
    });
    const convites = gestao
      ? await this.prisma.conviteAcesso.findMany({
          orderBy: { createdAt: 'desc' },
        })
      : [];
    const despedidas = gestao
      ? await this.prisma.despedidaEvento.findMany()
      : [];
    const despedidaParticipantes = gestao
      ? await this.prisma.despedidaParticipante.findMany({
          orderBy: { createdAt: 'desc' },
        })
      : [];

    let tarefasVisiveis = tarefas;
    if (user.role === UserRole.padrinho) {
      const meu = padrinhos.find((p) => {
        const c = convidados.find((x) => x.id === p.convidadoId);
        return c?.user?.id === user.id || user.convidadoId === p.convidadoId;
      });
      tarefasVisiveis = tarefas.filter(
        (t) => t.destino === DestinoTarefa.padrinho && t.padrinhoId === meu?.id,
      );
    } else if (user.role === UserRole.convidado) {
      tarefasVisiveis = [];
    }

    return {
      user: {
        id: user.id,
        nome: user.nome,
        email: user.email ?? '',
        telefone: user.telefone,
        role: user.role,
        convidadoId: user.convidadoId,
        temSenha: Boolean(user.passwordHash),
      },
      config: this.mapConfig(config),
      gastos: gastos.map((g) => ({
        ...g,
        valorPrevisto: this.dec(g.valorPrevisto) ?? 0,
        valorReal: this.dec(g.valorReal),
      })),
      tarefas: tarefasVisiveis,
      compromissos,
      convidados: convidados.map((c) => this.mapConvidado(c)),
      padrinhos,
      presentes: presentes.map((p) => ({
        ...p,
        valorEstimado: this.dec(p.valorEstimado),
      })),
      fotos,
      cardapio,
      atracoes,
      convites,
      despedidas,
      despedidaParticipantes,
    };
  }

  async publicConfig() {
    const config = await this.prisma.casamentoConfig.findFirst();
    if (!config) return null;
    return this.mapConfig(config);
  }

  async salvarConfig(userId: string, body: any) {
    await this.assertGestao(userId);
    const existing = await this.prisma.casamentoConfig.findFirst();
    const data = {
      nomeNoivo: body.nomeNoivo,
      nomeNoiva: body.nomeNoiva,
      dataCerimonia: body.dataCerimonia ? new Date(body.dataCerimonia) : null,
      local: body.local ?? null,
      localCerimonia: body.localCerimonia ?? null,
      enderecoCerimonia: body.enderecoCerimonia ?? null,
      localFesta: body.localFesta ?? null,
      enderecoFesta: body.enderecoFesta ?? null,
      capaUrl: body.capaUrl ?? null,
      whatsapp: body.whatsapp ?? null,
      mensagemBoasVindas: body.mensagemBoasVindas ?? null,
    };
    const c = existing
      ? await this.prisma.casamentoConfig.update({ where: { id: existing.id }, data })
      : await this.prisma.casamentoConfig.create({ data });
    return this.mapConfig(c);
  }

  async upsertGasto(userId: string, body: any) {
    await this.assertGestao(userId);
    const data = {
      descricao: body.descricao,
      categoria: body.categoria,
      valorPrevisto: body.valorPrevisto ?? 0,
      valorReal: body.valorReal ?? null,
      status: body.status ?? 'pendente',
      dataPrevista: body.dataPrevista ? new Date(body.dataPrevista) : null,
      dataPagamento: body.dataPagamento ? new Date(body.dataPagamento) : null,
      observacoes: body.observacoes ?? null,
    };
    const g = body.id
      ? await this.prisma.gasto.update({ where: { id: body.id }, data })
      : await this.prisma.gasto.create({ data });
    return {
      ...g,
      valorPrevisto: this.dec(g.valorPrevisto) ?? 0,
      valorReal: this.dec(g.valorReal),
    };
  }

  async removerGasto(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.gasto.delete({ where: { id } });
    return { ok: true };
  }

  async upsertTarefa(userId: string, body: any) {
    const user = await this.requireUser(userId);
    if (!this.isGestao(user.role) && user.role !== UserRole.padrinho) {
      throw new ForbiddenException();
    }
    const data = {
      titulo: body.titulo,
      descricao: body.descricao ?? null,
      status: body.status ?? 'pendente',
      prioridade: (body.prioridade as Prioridade) ?? Prioridade.media,
      destino: (body.destino as DestinoTarefa) ?? DestinoTarefa.noivos,
      prazo: body.prazo ? new Date(body.prazo) : null,
      padrinhoId: body.padrinhoId ?? null,
      criadoPor: body.criadoPor ?? user.id,
    };
    return body.id
      ? this.prisma.tarefa.update({ where: { id: body.id }, data })
      : this.prisma.tarefa.create({ data });
  }

  async marcarTarefaFeita(userId: string, id: string) {
    await this.requireUser(userId);
    return this.prisma.tarefa.update({
      where: { id },
      data: { status: 'feito' },
    });
  }

  async upsertCompromisso(userId: string, body: any) {
    const user = await this.assertGestao(userId);
    const data = {
      titulo: body.titulo,
      descricao: body.descricao ?? null,
      inicio: new Date(body.inicio),
      fim: body.fim ? new Date(body.fim) : null,
      local: body.local ?? null,
      criadoPor: user.id,
    };
    return body.id
      ? this.prisma.compromisso.update({ where: { id: body.id }, data })
      : this.prisma.compromisso.create({ data });
  }

  async removerCompromisso(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.compromisso.delete({ where: { id } });
    return { ok: true };
  }

  async upsertConvidado(userId: string, body: any) {
    await this.assertGestao(userId);
    const data: any = {
      nome: body.nome,
      telefone: body.telefone ?? null,
      email: body.email ?? null,
      lado: (body.lado as LadoConvidado) ?? LadoConvidado.ambos,
      mesa: body.mesa ?? null,
      ehCrianca: body.ehCrianca === true,
      acompanhantes: this.normalizeAcomps(
        body.acompanhantesLista ?? body.acompanhantes ?? [],
        body.id,
      ),
      rsvp: (body.rsvp as RsvpStatus) ?? RsvpStatus.pendente,
      observacoes: body.observacoes ?? null,
    };
    if (typeof body.token === 'string' && body.token.trim()) {
      data.token = body.token.trim().toUpperCase();
    }
    const c = body.id
      ? await this.prisma.convidado.update({
          where: { id: body.id },
          data,
          include: { user: { select: { id: true } } },
        })
      : await this.prisma.convidado.create({
          data,
          include: { user: { select: { id: true } } },
        });
    await this.ensureConviteConvidado(c.id);
    const fresh = await this.prisma.convidado.findUnique({
      where: { id: c.id },
      include: { user: { select: { id: true } } },
    });
    return this.mapConvidado(fresh!);
  }

  async removerConvidado(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.convidado.delete({ where: { id } });
    return { ok: true };
  }

  async removerTarefa(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.tarefa.delete({ where: { id } });
    return { ok: true };
  }

  async removerPresente(userId: string, id: string) {
    await this.assertGestao(userId);
    const existing = await this.prisma.presente.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Presente não encontrado');
    await this.prisma.presente.delete({ where: { id } });
    this.unlinkUpload(existing.imagemUrl);
    return { ok: true };
  }

  async atualizarRsvp(
    userId: string,
    status: RsvpStatus,
    acompanhanteId?: string,
  ) {
    const user = await this.requireUser(userId);
    if (!user.convidadoId) {
      throw new ForbiddenException('Sem convidado vinculado');
    }
    const atual = await this.prisma.convidado.findUnique({
      where: { id: user.convidadoId },
      include: { user: { select: { id: true } } },
    });
    if (!atual) throw new NotFoundException('Convidado não encontrado');

    const lista = this.normalizeAcomps(atual.acompanhantes, atual.id);

    if (!acompanhanteId) {
      const c = await this.prisma.convidado.update({
        where: { id: atual.id },
        data: { rsvp: status, acompanhantes: lista },
        include: { user: { select: { id: true } } },
      });
      return this.mapConvidado(c);
    }

    const idx = lista.findIndex((a) => a.id === acompanhanteId);
    if (idx < 0) throw new NotFoundException('Acompanhante não encontrado');
    lista[idx] = { ...lista[idx], rsvp: status };
    const c = await this.prisma.convidado.update({
      where: { id: atual.id },
      data: { acompanhantes: lista },
      include: { user: { select: { id: true } } },
    });
    return this.mapConvidado(c);
  }

  async vincularPadrinho(userId: string, body: any) {
    await this.assertGestao(userId);
    return this.prisma.padrinho.create({
      data: {
        convidadoId: body.convidadoId,
        tipo: (body.tipo as TipoPadrinho) ?? TipoPadrinho.padrinho,
        papel: body.papel ?? null,
        ordem: body.ordem ?? 0,
      },
    });
  }

  async removerPadrinho(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.padrinho.delete({ where: { id } });
    return { ok: true };
  }

  async upsertPresente(userId: string, body: any) {
    await this.assertGestao(userId);
    const data: {
      nome: string;
      descricao: string | null;
      link: string | null;
      valorEstimado: number | null;
      ativo: boolean;
      imagemUrl?: string | null;
    } = {
      nome: body.nome,
      descricao: body.descricao ?? null,
      link: body.link ?? null,
      valorEstimado: body.valorEstimado ?? null,
      ativo: body.ativo ?? true,
    };
    let oldImagemUrl: string | null = null;
    if ('imagemUrl' in body) {
      data.imagemUrl = body.imagemUrl ?? null;
      if (body.id) {
        const existing = await this.prisma.presente.findUnique({
          where: { id: body.id },
        });
        if (existing?.imagemUrl && existing.imagemUrl !== data.imagemUrl) {
          oldImagemUrl = existing.imagemUrl;
        }
      }
    }
    const p = body.id
      ? await this.prisma.presente.update({ where: { id: body.id }, data })
      : await this.prisma.presente.create({ data });
    if (oldImagemUrl) this.unlinkUpload(oldImagemUrl);
    return { ...p, valorEstimado: this.dec(p.valorEstimado) };
  }

  async uploadPresenteImagem(
    userId: string,
    file?: { filename: string },
  ) {
    await this.assertGestao(userId);
    if (!file?.filename) {
      throw new BadRequestException('Selecione uma imagem');
    }
    return { url: publicFotoUrl(file.filename) };
  }

  async reservarPresente(userId: string, presenteId: string) {
    const user = await this.requireUser(userId);
    if (!user.convidadoId) throw new ForbiddenException('Sem convidado vinculado');
    const p = await this.prisma.presente.update({
      where: { id: presenteId },
      data: {
        reservadoPorConvidadoId: user.convidadoId,
        reservadoEm: new Date(),
      },
    });
    return { ...p, valorEstimado: this.dec(p.valorEstimado) };
  }

  async cancelarReservaPresente(userId: string, presenteId: string) {
    const user = await this.requireUser(userId);
    const existing = await this.prisma.presente.findUnique({ where: { id: presenteId } });
    if (!existing) throw new NotFoundException();
    if (
      !this.isGestao(user.role) &&
      existing.reservadoPorConvidadoId !== user.convidadoId
    ) {
      throw new ForbiddenException();
    }
    const p = await this.prisma.presente.update({
      where: { id: presenteId },
      data: { reservadoPorConvidadoId: null, reservadoEm: null },
    });
    return { ...p, valorEstimado: this.dec(p.valorEstimado) };
  }

  private parsePublico(v: unknown) {
    if (v === true || v === 'true' || v === '1' || v === 1) return true;
    return false;
  }

  private unlinkUpload(url?: string | null) {
    if (!url || !url.startsWith('/uploads/')) return;
    const name = basename(url);
    if (!name || name.includes('..')) return;
    const dir = process.env.UPLOAD_DIR || './uploads';
    const path = join(dir, name);
    if (existsSync(path)) {
      try {
        unlinkSync(path);
      } catch {
        /* ignore */
      }
    }
  }

  async adicionarFotos(
    userId: string,
    files: { filename: string }[],
    body: any,
  ) {
    await this.assertGestao(userId);
    if (!files.length) {
      throw new BadRequestException('Selecione ao menos uma foto');
    }
    const tipo = (body?.tipo as FotoTipo) || FotoTipo.evento;
    const legenda =
      typeof body?.legenda === 'string' && body.legenda.trim()
        ? body.legenda.trim()
        : null;
    const publico = this.parsePublico(body?.publico);
    return this.prisma.$transaction(
      files.map((f) =>
        this.prisma.foto.create({
          data: {
            tipo,
            url: publicFotoUrl(f.filename),
            legenda,
            publico,
          },
        }),
      ),
    );
  }

  async atualizarFoto(userId: string, body: any) {
    await this.assertGestao(userId);
    return this.prisma.foto.update({
      where: { id: body.id },
      data: {
        tipo: body.tipo,
        legenda: body.legenda ?? null,
        publico: this.parsePublico(body.publico),
      },
    });
  }

  async removerFoto(userId: string, id: string) {
    await this.assertGestao(userId);
    const foto = await this.prisma.foto.findUnique({ where: { id } });
    if (!foto) throw new NotFoundException('Foto não encontrada');
    await this.prisma.foto.delete({ where: { id } });
    this.unlinkUpload(foto.url);
    return { ok: true };
  }

  async upsertCardapio(userId: string, body: any) {
    await this.assertGestao(userId);
    const data = {
      titulo: body.titulo,
      descricao: body.descricao ?? null,
      ordem: body.ordem ?? 0,
    };
    return body.id
      ? this.prisma.cardapioItem.update({ where: { id: body.id }, data })
      : this.prisma.cardapioItem.create({ data });
  }

  async removerCardapio(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.cardapioItem.delete({ where: { id } });
    return { ok: true };
  }

  async upsertAtracao(userId: string, body: any) {
    await this.assertGestao(userId);
    const data = {
      titulo: body.titulo,
      descricao: body.descricao ?? null,
      horario: body.horario ?? null,
      ordem: body.ordem ?? 0,
    };
    return body.id
      ? this.prisma.atracaoItem.update({ where: { id: body.id }, data })
      : this.prisma.atracaoItem.create({ data });
  }

  async removerAtracao(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.atracaoItem.delete({ where: { id } });
    return { ok: true };
  }

  gerarToken(prefix = 'LD') {
    const raw = randomBytes(3).toString('hex').toUpperCase();
    return `${prefix}-${raw}`;
  }

  async criarConviteCerimonialista(userId: string, nome: string) {
    await this.assertGestao(userId);
    const token = this.gerarToken('CERIM');
    return this.prisma.conviteAcesso.create({
      data: {
        token,
        role: UserRole.cerimonialista,
        nome: nome || 'Cerimonialista',
        ativo: true,
      },
    });
  }

  private async ensureConviteConvidado(
    convidadoId: string,
    regenerar = false,
  ) {
    const convidado = await this.prisma.convidado.findUnique({
      where: { id: convidadoId },
      include: { padrinho: true },
    });
    if (!convidado) throw new NotFoundException('Convidado não encontrado');
    const role = convidado.padrinho ? UserRole.padrinho : UserRole.convidado;
    const prefix = role === UserRole.padrinho ? 'PAD' : 'CONV';
    let token = convidado.token;
    if (!token || regenerar) {
      token = this.gerarToken(prefix);
      await this.prisma.convidado.update({
        where: { id: convidadoId },
        data: { token },
      });
    }
    const existing = await this.prisma.conviteAcesso.findFirst({
      where: { convidadoId },
    });
    const data = {
      token,
      role,
      nome: convidado.nome,
      ativo: true,
      convidadoId,
    };
    if (existing) {
      return this.prisma.conviteAcesso.update({
        where: { id: existing.id },
        data,
      });
    }
    return this.prisma.conviteAcesso.create({ data });
  }

  async regenerarTokenConvidado(userId: string, convidadoId: string) {
    await this.assertGestao(userId);
    return this.ensureConviteConvidado(convidadoId, true);
  }

  async salvarDespedidaEvento(userId: string, body: any) {
    await this.assertGestao(userId);
    return this.prisma.despedidaEvento.upsert({
      where: { tipo: body.tipo as TipoDespedida },
      create: {
        tipo: body.tipo,
        data: body.data ? new Date(body.data) : null,
        local: body.local ?? null,
        endereco: body.endereco ?? null,
        observacoes: body.observacoes ?? null,
      },
      update: {
        data: body.data ? new Date(body.data) : null,
        local: body.local ?? null,
        endereco: body.endereco ?? null,
        observacoes: body.observacoes ?? null,
      },
    });
  }

  async upsertDespedidaParticipante(userId: string, body: any) {
    await this.assertGestao(userId);
    if (!body.convidadoId) {
      throw new BadRequestException('Selecione um convidado');
    }
    const conv = await this.prisma.convidado.findUnique({
      where: { id: body.convidadoId },
    });
    if (!conv) throw new NotFoundException('Convidado não encontrado');

    const data = {
      nome: conv.nome,
      tipo: body.tipo as TipoDespedida,
      telefone: body.telefone ?? conv.telefone ?? null,
      confirmado: body.confirmado ?? false,
      observacoes: body.observacoes ?? null,
      convidadoId: conv.id,
    };
    return body.id
      ? this.prisma.despedidaParticipante.update({ where: { id: body.id }, data })
      : this.prisma.despedidaParticipante.create({ data });
  }

  async removerDespedidaParticipante(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.despedidaParticipante.delete({ where: { id } });
    return { ok: true };
  }
}
