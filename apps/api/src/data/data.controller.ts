import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Req,
  UploadedFile,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DataService } from './data.service';
import { fotoUploadOptions, AdicionarFotosDto } from './foto-upload';
import { RsvpStatus } from '@prisma/client';

class RsvpDto {
  @IsEnum(RsvpStatus)
  status!: RsvpStatus;

  @IsOptional()
  @IsString()
  acompanhanteId?: string;
}

@Controller()
export class DataController {
  constructor(private readonly data: DataService) {}

  @Get('public/config')
  publicConfig() {
    return this.data.publicConfig();
  }

  @UseGuards(JwtAuthGuard)
  @Get('bootstrap')
  bootstrap(@Req() req: { user: { userId: string } }) {
    return this.data.bootstrap(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Put('config')
  salvarConfig(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.salvarConfig(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('gastos')
  upsertGasto(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertGasto(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('gastos/:id')
  removerGasto(@Req() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.data.removerGasto(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('tarefas')
  upsertTarefa(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertTarefa(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('tarefas/:id/feito')
  marcarFeita(@Req() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.data.marcarTarefaFeita(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('compromissos')
  upsertCompromisso(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertCompromisso(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('compromissos/:id')
  removerCompromisso(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerCompromisso(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('convidados')
  upsertConvidado(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertConvidado(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('convidados/:id')
  removerConvidado(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerConvidado(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('tarefas/:id')
  removerTarefa(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerTarefa(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('presentes/:id')
  removerPresente(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerPresente(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Put('rsvp')
  rsvp(
    @Req() req: { user: { userId: string } },
    @Body() body: RsvpDto,
  ) {
    return this.data.atualizarRsvp(
      req.user.userId,
      body.status,
      body.acompanhanteId,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Post('padrinhos')
  vincularPadrinho(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.vincularPadrinho(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('padrinhos/:id')
  removerPadrinho(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerPadrinho(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('presentes')
  upsertPresente(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertPresente(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('presentes/imagem')
  @UseInterceptors(FileInterceptor('file', fotoUploadOptions))
  uploadPresenteImagem(
    @Req() req: { user: { userId: string } },
    @UploadedFile() file: { filename: string } | undefined,
  ) {
    return this.data.uploadPresenteImagem(req.user.userId, file);
  }

  @UseGuards(JwtAuthGuard)
  @Post('presentes/:id/reservar')
  reservar(@Req() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.data.reservarPresente(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('presentes/:id/cancelar-reserva')
  cancelarReserva(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.cancelarReservaPresente(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('fotos')
  @UseInterceptors(FilesInterceptor('files', 30, fotoUploadOptions))
  adicionarFotos(
    @Req() req: { user: { userId: string } },
    @UploadedFiles() files: { filename: string }[],
    @Body() body: AdicionarFotosDto,
  ) {
    return this.data.adicionarFotos(req.user.userId, files ?? [], body);
  }

  @UseGuards(JwtAuthGuard)
  @Put('fotos')
  atualizarFoto(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.atualizarFoto(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('fotos/:id')
  removerFoto(@Req() req: { user: { userId: string } }, @Param('id') id: string) {
    return this.data.removerFoto(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('cardapio')
  upsertCardapio(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertCardapio(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('cardapio/:id')
  removerCardapio(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerCardapio(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('atracoes')
  upsertAtracao(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertAtracao(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('atracoes/:id')
  removerAtracao(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerAtracao(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('convites/cerimonialista')
  criarCerim(
    @Req() req: { user: { userId: string } },
    @Body() body: { nome?: string },
  ) {
    return this.data.criarConviteCerimonialista(req.user.userId, body.nome ?? '');
  }

  @UseGuards(JwtAuthGuard)
  @Post('convidados/:id/token')
  regenerarToken(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.regenerarTokenConvidado(req.user.userId, id);
  }

  @UseGuards(JwtAuthGuard)
  @Put('despedida/evento')
  despedidaEvento(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.salvarDespedidaEvento(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('despedida/participantes')
  despedidaPart(@Req() req: { user: { userId: string } }, @Body() body: any) {
    return this.data.upsertDespedidaParticipante(req.user.userId, body);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('despedida/participantes/:id')
  removerDespedidaPart(
    @Req() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    return this.data.removerDespedidaParticipante(req.user.userId, id);
  }
}
