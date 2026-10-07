-- CreateTable
CREATE TABLE "PlanoMesas" (
    "id" TEXT NOT NULL,
    "mesas" INTEGER NOT NULL DEFAULT 0,
    "cadeirasPorMesa" INTEGER NOT NULL DEFAULT 0,
    "alocacoes" JSONB NOT NULL DEFAULT '[]',
    "ladoMesas" JSONB NOT NULL DEFAULT '[]',
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlanoMesas_pkey" PRIMARY KEY ("id")
);
