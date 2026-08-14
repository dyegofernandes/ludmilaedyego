import { Body, Controller, Get, Post, Put, Req, UseGuards } from '@nestjs/common';
import {
  IsEmail,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(4)
  password!: string;
}

class TokenDto {
  @IsString()
  @MinLength(3)
  token!: string;
}

class InviteParceiroDto {
  @IsString()
  @MinLength(2)
  nome!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsOptional()
  @IsString()
  telefone?: string;
}

class ChangePasswordDto {
  @IsString()
  @MinLength(4)
  currentPassword!: string;

  @IsString()
  @MinLength(6)
  newPassword!: string;
}

class CompletarCadastroDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsOptional()
  @IsString()
  nome?: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto.email, dto.password);
  }

  @Post('token')
  loginToken(@Body() dto: TokenDto) {
    return this.auth.loginWithToken(dto.token);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Req() req: { user: { userId: string } }) {
    return this.auth.me(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('noivos')
  listNoivos() {
    return this.auth.listNoivos();
  }

  @UseGuards(JwtAuthGuard)
  @Post('invite-parceiro')
  inviteParceiro(
    @Req() req: { user: { userId: string } },
    @Body() dto: InviteParceiroDto,
  ) {
    return this.auth.inviteParceiro(req.user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Put('change-password')
  changePassword(
    @Req() req: { user: { userId: string } },
    @Body() dto: ChangePasswordDto,
  ) {
    return this.auth.changePassword(req.user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('completar-cadastro')
  completarCadastro(
    @Req() req: { user: { userId: string } },
    @Body() dto: CompletarCadastroDto,
  ) {
    return this.auth.completarCadastro(req.user.userId, dto);
  }
}
