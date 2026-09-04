-- CreateEnum
CREATE TYPE "AudienciaPresente" AS ENUM ('convidados', 'padrinhos');

-- AlterTable
ALTER TABLE "Presente" ADD COLUMN "audiencia" "AudienciaPresente" NOT NULL DEFAULT 'convidados';
