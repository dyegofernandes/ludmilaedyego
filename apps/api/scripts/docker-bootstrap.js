/**
 * Garante conta do noivo + config mínima (idempotente, não apaga dados).
 */
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  const email =
    process.env.BOOTSTRAP_NOIVO_EMAIL || 'dyego.fernandes.vieira@gmail.com';
  const password = process.env.BOOTSTRAP_NOIVO_PASSWORD || '123456';
  const nome = process.env.BOOTSTRAP_NOIVO_NOME || 'Dyego';
  const passwordHash = await bcrypt.hash(password, 10);

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    await prisma.user.update({
      where: { id: existing.id },
      data: { passwordHash, role: 'noivo', nome },
    });
    console.log('[bootstrap] Conta atualizada:', email);
  } else {
    await prisma.user.create({
      data: { email, passwordHash, role: 'noivo', nome },
    });
    console.log('[bootstrap] Conta criada:', email);
  }

  const config = await prisma.casamentoConfig.findFirst();
  if (config) {
    await prisma.casamentoConfig.update({
      where: { id: config.id },
      data: {
        nomeNoivo: nome,
        nomeNoiva: config.nomeNoiva || 'Ludmila',
      },
    });
  } else {
    await prisma.casamentoConfig.create({
      data: {
        nomeNoivo: nome,
        nomeNoiva: 'Ludmila',
        mensagemBoasVindas: 'Bem-vindos ao nosso casamento!',
      },
    });
  }

  console.log(`[bootstrap] Login: ${email} / (senha do BOOTSTRAP_NOIVO_PASSWORD)`);
}

main()
  .catch((e) => {
    console.error('[bootstrap]', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
