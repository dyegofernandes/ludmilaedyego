import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  private async sign(userId: string) {
    return this.jwt.signAsync(
      { sub: userId },
      {
        secret: this.config.getOrThrow('JWT_SECRET'),
        expiresIn: this.config.get('JWT_EXPIRES_IN') || '30d',
      },
    );
  }

  sanitize(user: {
    id: string;
    nome: string;
    email: string | null;
    telefone: string;
    role: UserRole;
    convidadoId: string | null;
    passwordHash?: string | null;
  }) {
    return {
      id: user.id,
      nome: user.nome,
      email: user.email ?? '',
      telefone: user.telefone,
      role: user.role,
      convidadoId: user.convidadoId,
      temSenha: Boolean(user.passwordHash),
    };
  }

  /** Até 2 contas noivo (casal). */
  async canRegisterNoivo() {
    const count = await this.prisma.user.count({
      where: { role: UserRole.noivo },
    });
    return { allowed: count < 2, count, max: 2 };
  }

  async listNoivos() {
    const users = await this.prisma.user.findMany({
      where: { role: UserRole.noivo },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        nome: true,
        email: true,
        telefone: true,
        role: true,
        convidadoId: true,
      },
    });
    return users.map((u) => this.sanitize(u));
  }

  /** Noivo logado cadastra a noiva (mesmo acesso total — role noivo). */
  async inviteParceiro(
    requesterId: string,
    input: {
      nome: string;
      email: string;
      password: string;
      telefone?: string;
    },
  ) {
    const requester = await this.prisma.user.findUnique({
      where: { id: requesterId },
    });
    if (!requester || requester.role !== UserRole.noivo) {
      throw new UnauthorizedException('Só noivos podem cadastrar o parceiro');
    }

    const status = await this.canRegisterNoivo();
    if (!status.allowed) {
      throw new BadRequestException(
        'Já existem 2 contas. Remova uma ou peça para a outra pessoa entrar com o e-mail dela.',
      );
    }

    const email = input.email.toLowerCase().trim();
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) {
      throw new BadRequestException('E-mail já cadastrado');
    }

    const passwordHash = await bcrypt.hash(input.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        role: UserRole.noivo,
        nome: input.nome.trim() || 'Noiva',
        telefone: input.telefone?.trim() || '',
      },
    });

    const config = await this.prisma.casamentoConfig.findFirst();
    if (config && (!config.nomeNoiva || config.nomeNoiva === 'Noiva')) {
      await this.prisma.casamentoConfig.update({
        where: { id: config.id },
        data: { nomeNoiva: user.nome },
      });
    }

    return { user: this.sanitize(user) };
  }

  async changePassword(
    userId: string,
    input: { currentPassword: string; newPassword: string },
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Conta sem senha');
    }
    const ok = await bcrypt.compare(input.currentPassword, user.passwordHash);
    if (!ok) {
      throw new BadRequestException('Senha atual incorreta');
    }
    if (input.newPassword.length < 6) {
      throw new BadRequestException('Nova senha deve ter no mínimo 6 caracteres');
    }
    const passwordHash = await bcrypt.hash(input.newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
    return { ok: true };
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
    });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Credenciais inválidas');
    }
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Credenciais inválidas');
    const accessToken = await this.sign(user.id);
    return { accessToken, user: this.sanitize(user) };
  }

  async loginWithToken(tokenRaw: string) {
    const token = tokenRaw.trim().toUpperCase();
    let convite = await this.prisma.conviteAcesso.findFirst({
      where: { token, ativo: true },
    });

    if (!convite) {
      const convidado = await this.prisma.convidado.findFirst({
        where: { token },
        include: { padrinho: true },
      });
      if (!convidado) {
        throw new UnauthorizedException('Convite inválido');
      }
      const role = convidado.padrinho
        ? UserRole.padrinho
        : UserRole.convidado;
      convite = await this.prisma.conviteAcesso.create({
        data: {
          token,
          role,
          nome: convidado.nome,
          convidadoId: convidado.id,
          ativo: true,
        },
      });
    }

    let user = null as Awaited<ReturnType<typeof this.prisma.user.findFirst>>;

    if (convite.role === UserRole.cerimonialista) {
      user = await this.prisma.user.findFirst({
        where: { role: UserRole.cerimonialista, nome: convite.nome },
      });
      if (!user) {
        user = await this.prisma.user.create({
          data: {
            role: UserRole.cerimonialista,
            nome: convite.nome || 'Cerimonialista',
          },
        });
      }
    } else if (convite.convidadoId) {
      user = await this.prisma.user.findFirst({
        where: { convidadoId: convite.convidadoId },
      });
      if (!user) {
        const convidado = await this.prisma.convidado.findUnique({
          where: { id: convite.convidadoId },
        });
        user = await this.prisma.user.create({
          data: {
            role: convite.role,
            nome: convite.nome || convidado?.nome || '',
            convidadoId: convite.convidadoId,
          },
        });
      }
    } else {
      throw new UnauthorizedException('Convite sem vínculo');
    }

    const accessToken = await this.sign(user.id);
    return { accessToken, user: this.sanitize(user) };
  }

  /** Convidado/padrinho que entrou pelo link cria e-mail e senha. Role não muda. */
  async completarCadastro(
    userId: string,
    input: { email: string; password: string; nome?: string },
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();
    if (
      user.role !== UserRole.convidado &&
      user.role !== UserRole.padrinho
    ) {
      throw new BadRequestException(
        'Este cadastro é só para convidados e padrinhos',
      );
    }
    if (user.passwordHash) {
      throw new BadRequestException(
        'Você já tem cadastro. Entre com e-mail e senha.',
      );
    }
    const email = input.email.toLowerCase().trim();
    if (!email) throw new BadRequestException('Informe um e-mail');
    if (!input.password || input.password.length < 6) {
      throw new BadRequestException('Senha deve ter no mínimo 6 caracteres');
    }
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists && exists.id !== user.id) {
      throw new BadRequestException('E-mail já cadastrado');
    }
    const passwordHash = await bcrypt.hash(input.password, 10);
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: {
        email,
        passwordHash,
        nome: input.nome?.trim() || user.nome,
      },
    });
    return { user: this.sanitize(updated) };
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();
    return this.sanitize(user);
  }
}
