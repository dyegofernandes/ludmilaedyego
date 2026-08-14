-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('noivo', 'cerimonialista', 'padrinho', 'convidado');

-- CreateEnum
CREATE TYPE "GastoStatus" AS ENUM ('pendente', 'pago', 'cancelado');

-- CreateEnum
CREATE TYPE "TarefaStatus" AS ENUM ('pendente', 'aprovado', 'feito', 'rejeitado', 'cancelado');

-- CreateEnum
CREATE TYPE "Prioridade" AS ENUM ('baixa', 'media', 'alta');

-- CreateEnum
CREATE TYPE "DestinoTarefa" AS ENUM ('noivos', 'padrinho');

-- CreateEnum
CREATE TYPE "LadoConvidado" AS ENUM ('noivo', 'noiva', 'ambos');

-- CreateEnum
CREATE TYPE "RsvpStatus" AS ENUM ('pendente', 'sim', 'nao', 'talvez');

-- CreateEnum
CREATE TYPE "TipoPadrinho" AS ENUM ('padrinho', 'madrinha');

-- CreateEnum
CREATE TYPE "FotoTipo" AS ENUM ('noivos', 'evento', 'outro');

-- CreateEnum
CREATE TYPE "TipoDespedida" AS ENUM ('solteiro', 'solteira');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT,
    "passwordHash" TEXT,
    "role" "UserRole" NOT NULL,
    "nome" TEXT NOT NULL DEFAULT '',
    "telefone" TEXT NOT NULL DEFAULT '',
    "convidadoId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CasamentoConfig" (
    "id" TEXT NOT NULL,
    "nomeNoivo" TEXT NOT NULL,
    "nomeNoiva" TEXT NOT NULL,
    "dataCerimonia" TIMESTAMP(3),
    "local" TEXT,
    "localCerimonia" TEXT,
    "enderecoCerimonia" TEXT,
    "localFesta" TEXT,
    "enderecoFesta" TEXT,
    "capaUrl" TEXT,
    "whatsapp" TEXT,
    "mensagemBoasVindas" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CasamentoConfig_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Gasto" (
    "id" TEXT NOT NULL,
    "descricao" TEXT NOT NULL,
    "categoria" TEXT NOT NULL,
    "valorPrevisto" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "valorReal" DECIMAL(12,2),
    "status" "GastoStatus" NOT NULL DEFAULT 'pendente',
    "dataPrevista" DATE,
    "dataPagamento" DATE,
    "observacoes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Gasto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Convidado" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "telefone" TEXT,
    "email" TEXT,
    "lado" "LadoConvidado" NOT NULL DEFAULT 'ambos',
    "mesa" TEXT,
    "acompanhantes" JSONB NOT NULL DEFAULT '[]',
    "token" TEXT,
    "rsvp" "RsvpStatus" NOT NULL DEFAULT 'pendente',
    "observacoes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Convidado_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Padrinho" (
    "id" TEXT NOT NULL,
    "convidadoId" TEXT NOT NULL,
    "tipo" "TipoPadrinho" NOT NULL,
    "papel" TEXT,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Padrinho_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Tarefa" (
    "id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "descricao" TEXT,
    "status" "TarefaStatus" NOT NULL DEFAULT 'pendente',
    "prioridade" "Prioridade" NOT NULL DEFAULT 'media',
    "destino" "DestinoTarefa" NOT NULL DEFAULT 'noivos',
    "prazo" DATE,
    "padrinhoId" TEXT,
    "criadoPor" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Tarefa_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Compromisso" (
    "id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "descricao" TEXT,
    "inicio" TIMESTAMP(3) NOT NULL,
    "fim" TIMESTAMP(3),
    "local" TEXT,
    "criadoPor" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Compromisso_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CardapioItem" (
    "id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "descricao" TEXT,
    "ordem" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "CardapioItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AtracaoItem" (
    "id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "descricao" TEXT,
    "horario" TEXT,
    "ordem" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "AtracaoItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ConviteAcesso" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "role" "UserRole" NOT NULL,
    "nome" TEXT NOT NULL DEFAULT '',
    "convidadoId" TEXT,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ConviteAcesso_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Foto" (
    "id" TEXT NOT NULL,
    "tipo" "FotoTipo" NOT NULL,
    "url" TEXT NOT NULL,
    "legenda" TEXT,
    "publico" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Foto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Presente" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "descricao" TEXT,
    "link" TEXT,
    "valorEstimado" DECIMAL(12,2),
    "imagemUrl" TEXT,
    "ativo" BOOLEAN NOT NULL DEFAULT true,
    "reservadoPorConvidadoId" TEXT,
    "reservadoEm" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Presente_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DespedidaEvento" (
    "tipo" "TipoDespedida" NOT NULL,
    "data" TIMESTAMP(3),
    "local" TEXT,
    "endereco" TEXT,
    "observacoes" TEXT,

    CONSTRAINT "DespedidaEvento_pkey" PRIMARY KEY ("tipo")
);

-- CreateTable
CREATE TABLE "DespedidaParticipante" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "tipo" "TipoDespedida" NOT NULL,
    "telefone" TEXT,
    "confirmado" BOOLEAN NOT NULL DEFAULT false,
    "observacoes" TEXT,
    "convidadoId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DespedidaParticipante_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_convidadoId_key" ON "User"("convidadoId");

-- CreateIndex
CREATE UNIQUE INDEX "Convidado_token_key" ON "Convidado"("token");

-- CreateIndex
CREATE UNIQUE INDEX "Padrinho_convidadoId_key" ON "Padrinho"("convidadoId");

-- CreateIndex
CREATE UNIQUE INDEX "ConviteAcesso_token_key" ON "ConviteAcesso"("token");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_convidadoId_fkey" FOREIGN KEY ("convidadoId") REFERENCES "Convidado"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Padrinho" ADD CONSTRAINT "Padrinho_convidadoId_fkey" FOREIGN KEY ("convidadoId") REFERENCES "Convidado"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Tarefa" ADD CONSTRAINT "Tarefa_padrinhoId_fkey" FOREIGN KEY ("padrinhoId") REFERENCES "Padrinho"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Tarefa" ADD CONSTRAINT "Tarefa_criadoPor_fkey" FOREIGN KEY ("criadoPor") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Compromisso" ADD CONSTRAINT "Compromisso_criadoPor_fkey" FOREIGN KEY ("criadoPor") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConviteAcesso" ADD CONSTRAINT "ConviteAcesso_convidadoId_fkey" FOREIGN KEY ("convidadoId") REFERENCES "Convidado"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Presente" ADD CONSTRAINT "Presente_reservadoPorConvidadoId_fkey" FOREIGN KEY ("reservadoPorConvidadoId") REFERENCES "Convidado"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DespedidaParticipante" ADD CONSTRAINT "DespedidaParticipante_convidadoId_fkey" FOREIGN KEY ("convidadoId") REFERENCES "Convidado"("id") ON DELETE SET NULL ON UPDATE CASCADE;
