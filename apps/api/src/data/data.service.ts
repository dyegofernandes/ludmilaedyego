import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AudienciaPresente,
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
import {
  AlocacaoMesa,
  FamiliaMesa,
  LadoMesa,
  distribuirFamilias,
} from './mesas';

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

  /** Data sem fuso (ex.: datetime-local) vale como horário de Brasília. */
  private parseDateTime(v: unknown): Date | null {
    if (v == null || v === '') return null;
    const s = String(v).trim();
    if (!s) return null;
    if (/[zZ]|[+-]\d{2}:?\d{2}$/.test(s)) {
      const d = new Date(s);
      return Number.isNaN(d.getTime()) ? null : d;
    }
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) {
      const d = new Date(`${s}T00:00:00-03:00`);
      return Number.isNaN(d.getTime()) ? null : d;
    }
    const normalized = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(s)
      ? `${s}:00`
      : s;
    const d = new Date(`${normalized}-03:00`);
    return Number.isNaN(d.getTime()) ? null : d;
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
      urlPublica: this.normalizeUrlPublica(c.urlPublica) ?? c.urlPublica,
    };
  }

  private normalizeUrlPublica(v: unknown): string | null {
    let s = String(v ?? '').trim();
    if (!s) return null;
    if (!/^https?:\/\//i.test(s)) s = `https://${s}`;
    s = s.replace(/\/+$/, '');
    try {
      const u = new URL(s);
      if (u.hostname === 'ludmilaedyego.ddns.net') {
        u.protocol = 'https:';
        if (!u.port) u.port = '8087';
        return u.origin;
      }
    } catch {
      /* mantém o valor já normalizado */
    }
    return s;
  }

  private normalizeAcomps(raw: unknown, convidadoId?: string) {
    if (!Array.isArray(raw)) return [];
    const tiposOk = new Set([
      'esposa',
      'esposo',
      'namorada',
      'namorado',
      'amigo',
      'filho',
      'filho_adulto',
    ]);
    return raw
      .filter((a) => a && String(a.nome ?? '').trim())
      .map((a: any, i: number) => ({
        id: String(a.id || (convidadoId ? `ac-${convidadoId}-${i}` : `ac-${i}`)),
        nome: String(a.nome).trim(),
        tipo: tiposOk.has(a.tipo) ? a.tipo : 'amigo',
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

    const gastos =
      user.role === UserRole.noivo
        ? await this.prisma.gasto.findMany({ orderBy: { createdAt: 'desc' } })
        : [];
    const fornecedores = gestao
      ? await this.prisma.fornecedor.findMany({ orderBy: { nome: 'asc' } })
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
    const presentesWhere = gestao
      ? undefined
      : {
          ativo: true,
          audiencia:
            user.role === UserRole.padrinho
              ? AudienciaPresente.padrinhos
              : AudienciaPresente.convidados,
        };
    const presentes = await this.prisma.presente.findMany({
      where: presentesWhere,
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
    const planoMesas = gestao
      ? this.mapPlano(await this.prisma.planoMesas.findFirst())
      : null;
    const anotacoes = gestao
      ? (
          await this.prisma.anotacao.findMany({
            orderBy: [{ data: 'desc' }, { createdAt: 'desc' }],
          })
        ).map((a) => this.mapAnotacao(a))
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
      fornecedores,
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
      planoMesas,
      anotacoes,
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
      dataCerimonia: this.parseDateTime(body.dataCerimonia),
      local: body.local ?? null,
      localCerimonia: body.localCerimonia ?? null,
      enderecoCerimonia: body.enderecoCerimonia ?? null,
      localFesta: body.localFesta ?? null,
      enderecoFesta: body.enderecoFesta ?? null,
      capaUrl: body.capaUrl ?? null,
      whatsapp: body.whatsapp ?? null,
      mensagemBoasVindas: body.mensagemBoasVindas ?? null,
      ...('urlPublica' in body
        ? { urlPublica: this.normalizeUrlPublica(body.urlPublica) }
        : {}),
    };
    const c = existing
      ? await this.prisma.casamentoConfig.update({ where: { id: existing.id }, data })
      : await this.prisma.casamentoConfig.create({ data });
    return this.mapConfig(c);
  }

  async upsertGasto(userId: string, body: any) {
    const user = await this.requireUser(userId);
    if (user.role !== UserRole.noivo) throw new ForbiddenException();
    const data = {
      descricao: body.descricao,
      categoria: body.categoria,
      valorPrevisto: body.valorPrevisto ?? 0,
      valorReal: body.valorReal ?? null,
      status: body.status ?? 'pendente',
      dataPrevista: this.parseDateTime(body.dataPrevista),
      dataPagamento: this.parseDateTime(body.dataPagamento),
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
    const user = await this.requireUser(userId);
    if (user.role !== UserRole.noivo) throw new ForbiddenException();
    await this.prisma.gasto.delete({ where: { id } });
    return { ok: true };
  }

  async upsertFornecedor(userId: string, body: any) {
    await this.assertGestao(userId);
    const data = {
      nome: String(body.nome ?? '').trim(),
      funcao: String(body.funcao ?? '').trim(),
      telefone: String(body.telefone ?? '').trim(),
      descricao: body.descricao?.toString()?.trim() || null,
    };
    if (!data.nome) throw new BadRequestException('Nome obrigatório');
    return body.id
      ? this.prisma.fornecedor.update({ where: { id: body.id }, data })
      : this.prisma.fornecedor.create({ data });
  }

  async removerFornecedor(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.fornecedor.delete({ where: { id } });
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
      prazo: this.parseDateTime(body.prazo),
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
      inicio: this.parseDateTime(body.inicio) ?? new Date(body.inicio),
      fim: this.parseDateTime(body.fim),
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
    this.unlinkUpload(existing.pixQrCodeUrl);
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

  private parseAudienciaPresente(v: unknown): AudienciaPresente {
    return v === 'padrinhos' || v === AudienciaPresente.padrinhos
      ? AudienciaPresente.padrinhos
      : AudienciaPresente.convidados;
  }

  async upsertPresente(userId: string, body: any) {
    await this.assertGestao(userId);
    const data: {
      nome: string;
      descricao: string | null;
      link: string | null;
      valorEstimado: number | null;
      ativo: boolean;
      audiencia: AudienciaPresente;
      pixChave: string | null;
      imagemUrl?: string | null;
      pixQrCodeUrl?: string | null;
    } = {
      nome: body.nome,
      descricao: body.descricao ?? null,
      link: body.link ?? null,
      valorEstimado: body.valorEstimado ?? null,
      ativo: body.ativo ?? true,
      audiencia: this.parseAudienciaPresente(body.audiencia),
      pixChave: String(body.pixChave ?? '').trim() || null,
    };
    let oldImagemUrl: string | null = null;
    let oldPixQr: string | null = null;
    const existing = body.id
      ? await this.prisma.presente.findUnique({ where: { id: body.id } })
      : null;
    if ('imagemUrl' in body) {
      data.imagemUrl = body.imagemUrl ?? null;
      if (existing?.imagemUrl && existing.imagemUrl !== data.imagemUrl) {
        oldImagemUrl = existing.imagemUrl;
      }
    }
    if ('pixQrCodeUrl' in body) {
      data.pixQrCodeUrl = body.pixQrCodeUrl ?? null;
      if (existing?.pixQrCodeUrl && existing.pixQrCodeUrl !== data.pixQrCodeUrl) {
        oldPixQr = existing.pixQrCodeUrl;
      }
    }
    const p = body.id
      ? await this.prisma.presente.update({ where: { id: body.id }, data })
      : await this.prisma.presente.create({ data });
    if (oldImagemUrl) this.unlinkUpload(oldImagemUrl);
    if (oldPixQr) this.unlinkUpload(oldPixQr);
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
    const existing = await this.prisma.presente.findUnique({
      where: { id: presenteId },
    });
    if (!existing || !existing.ativo) {
      throw new NotFoundException('Presente não encontrado');
    }
    const audienciaEsperada =
      user.role === UserRole.padrinho
        ? AudienciaPresente.padrinhos
        : AudienciaPresente.convidados;
    if (existing.audiencia !== audienciaEsperada) {
      throw new ForbiddenException('Este presente não está na sua lista');
    }
    if (
      existing.reservadoPorConvidadoId &&
      existing.reservadoPorConvidadoId !== user.convidadoId
    ) {
      throw new ForbiddenException('Presente já reservado');
    }
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
        data: this.parseDateTime(body.data),
        local: body.local ?? null,
        endereco: body.endereco ?? null,
        observacoes: body.observacoes ?? null,
      },
      update: {
        data: this.parseDateTime(body.data),
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

  async upsertAnotacao(userId: string, body: any) {
    await this.assertGestao(userId);
    const titulo = String(body.titulo ?? '').trim();
    const descricao = String(body.descricao ?? '').trim();
    const data = this.parseDateOnly(body.data);
    if (!titulo) throw new BadRequestException('Informe o título');
    if (!descricao) throw new BadRequestException('Informe a descrição');
    if (!data) throw new BadRequestException('Informe a data');
    const payload = { titulo, descricao, data };
    const saved = body.id
      ? await this.prisma.anotacao.update({
          where: { id: String(body.id) },
          data: payload,
        })
      : await this.prisma.anotacao.create({ data: payload });
    return this.mapAnotacao(saved);
  }

  async removerAnotacao(userId: string, id: string) {
    await this.assertGestao(userId);
    await this.prisma.anotacao.delete({ where: { id } });
    return { ok: true };
  }

  async salvarPlanoMesas(userId: string, body: any) {
    await this.assertGestao(userId);
    const mesas = this.limiteInteiro(body.mesas, 100);
    const cadeirasPorMesa = this.limiteInteiro(body.cadeirasPorMesa, 40);
    const convidados = await this.prisma.convidado.findMany();
    const validas = this.chavesConfirmadas(convidados);
    const alocacoes =
      mesas < 1 || cadeirasPorMesa < 1
        ? []
        : this.sanitizeAlocacoes(
            body.alocacoes,
            mesas,
            cadeirasPorMesa,
            validas,
          );
    const atual = await this.prisma.planoMesas.findFirst();
    const ladoMesas = this.sanitizeLadoMesas(
      body.ladoMesas ?? atual?.ladoMesas,
      mesas,
    );
    return this.gravarPlano(mesas, cadeirasPorMesa, alocacoes, ladoMesas);
  }

  async distribuirPlanoMesas(userId: string, body: any) {
    await this.assertGestao(userId);
    const mesas = this.limiteInteiro(body.mesas, 100);
    const cadeirasPorMesa = this.limiteInteiro(body.cadeirasPorMesa, 40);
    const convidados = await this.prisma.convidado.findMany();
    const plano = distribuirFamilias(
      this.familiasConfirmadas(convidados),
      mesas,
      cadeirasPorMesa,
    );
    return this.gravarPlano(
      mesas,
      cadeirasPorMesa,
      plano.alocacoes,
      plano.ladoMesas,
    );
  }

  private limiteInteiro(v: unknown, max: number) {
    const n = Math.floor(Number(v));
    if (!Number.isFinite(n) || n < 0) return 0;
    return Math.min(n, max);
  }

  private familiasConfirmadas(convidados: any[]): FamiliaMesa[] {
    const familias: FamiliaMesa[] = [];
    for (const c of convidados) {
      const lado = this.ladoMesa(c.lado);
      const pessoas: { chave: string }[] = [];
      if (c.rsvp === RsvpStatus.sim) pessoas.push({ chave: `c:${c.id}` });
      for (const a of this.normalizeAcomps(c.acompanhantes, c.id)) {
        if (a.rsvp === 'sim') pessoas.push({ chave: `a:${c.id}:${a.id}` });
      }
      if (pessoas.length) familias.push({ lado, pessoas });
    }
    return familias;
  }

  private chavesConfirmadas(convidados: any[]) {
    const set = new Set<string>();
    for (const fam of this.familiasConfirmadas(convidados)) {
      for (const p of fam.pessoas) set.add(p.chave);
    }
    return set;
  }

  private ladoMesa(v: unknown): LadoMesa {
    if (v === 'noiva' || v === 'noivo' || v === 'ambos') return v;
    return 'ambos';
  }

  private sanitizeAlocacoes(
    raw: unknown,
    mesas: number,
    cadeiras: number,
    validas: Set<string>,
  ): AlocacaoMesa[] {
    if (!Array.isArray(raw)) return [];
    const seenChave = new Set<string>();
    const seenSeat = new Set<string>();
    const out: AlocacaoMesa[] = [];
    for (const item of raw) {
      const chave = String(item?.chave ?? '');
      const mesa = Math.floor(Number(item?.mesa));
      const cadeira = Math.floor(Number(item?.cadeira));
      if (!validas.has(chave)) continue;
      if (!Number.isFinite(mesa) || mesa < 1 || mesa > mesas) continue;
      if (!Number.isFinite(cadeira) || cadeira < 1 || cadeira > cadeiras) {
        continue;
      }
      const seat = `${mesa}:${cadeira}`;
      if (seenChave.has(chave) || seenSeat.has(seat)) continue;
      seenChave.add(chave);
      seenSeat.add(seat);
      out.push({ chave, mesa, cadeira });
    }
    return out;
  }

  private sanitizeLadoMesas(raw: unknown, mesas: number): LadoMesa[] {
    const src = Array.isArray(raw) ? raw : [];
    const out: LadoMesa[] = [];
    for (let i = 0; i < mesas; i++) out.push(this.ladoMesa(src[i]));
    return out;
  }

  private parseDateOnly(v: unknown): Date | null {
    const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(v ?? '').trim());
    if (!match) return null;
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const date = new Date(Date.UTC(year, month - 1, day));
    if (
      date.getUTCFullYear() !== year ||
      date.getUTCMonth() !== month - 1 ||
      date.getUTCDate() !== day
    ) {
      return null;
    }
    return date;
  }

  private formatDateOnly(d: Date) {
    const y = d.getUTCFullYear();
    const m = String(d.getUTCMonth() + 1).padStart(2, '0');
    const day = String(d.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  private mapAnotacao(a: {
    id: string;
    data: Date;
    titulo: string;
    descricao: string;
    createdAt: Date;
  }) {
    return {
      id: a.id,
      data: this.formatDateOnly(a.data),
      titulo: a.titulo,
      descricao: a.descricao,
      createdAt: a.createdAt,
    };
  }

  private mapPlano(p: {
    id: string;
    mesas: number;
    cadeirasPorMesa: number;
    alocacoes: unknown;
    ladoMesas: unknown;
  } | null) {
    if (!p) {
      return {
        id: null as string | null,
        mesas: 0,
        cadeirasPorMesa: 0,
        alocacoes: [] as AlocacaoMesa[],
        ladoMesas: [] as LadoMesa[],
      };
    }
    return {
      id: p.id,
      mesas: p.mesas,
      cadeirasPorMesa: p.cadeirasPorMesa,
      alocacoes: Array.isArray(p.alocacoes) ? p.alocacoes : [],
      ladoMesas: this.sanitizeLadoMesas(p.ladoMesas, p.mesas),
    };
  }

  private async gravarPlano(
    mesas: number,
    cadeirasPorMesa: number,
    alocacoes: AlocacaoMesa[],
    ladoMesas: LadoMesa[],
  ) {
    const data = {
      mesas,
      cadeirasPorMesa,
      alocacoes: alocacoes as unknown as Prisma.InputJsonValue,
      ladoMesas: ladoMesas as unknown as Prisma.InputJsonValue,
    };
    const existing = await this.prisma.planoMesas.findFirst();
    const saved = existing
      ? await this.prisma.planoMesas.update({
          where: { id: existing.id },
          data,
        })
      : await this.prisma.planoMesas.create({ data });
    await this.sincronizarMesaTitular(alocacoes);
    return this.mapPlano(saved);
  }

  private async sincronizarMesaTitular(alocacoes: AlocacaoMesa[]) {
    const porId = new Map<string, string>();
    for (const a of alocacoes) {
      if (a.chave.startsWith('c:')) porId.set(a.chave.slice(2), String(a.mesa));
    }
    const todos = await this.prisma.convidado.findMany({
      select: { id: true, mesa: true },
    });
    for (const c of todos) {
      const nova = porId.get(c.id) ?? null;
      if ((c.mesa ?? null) !== nova) {
        await this.prisma.convidado.update({
          where: { id: c.id },
          data: { mesa: nova },
        });
      }
    }
  }
}
