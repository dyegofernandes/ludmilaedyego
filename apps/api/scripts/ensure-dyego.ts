/**
 * Cria/atualiza a conta do Dyego no Postgres.
 * Uso: npx ts-node --transpile-only scripts/ensure-dyego.ts
 */
import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const email = 'dyego.fernandes.vieira@gmail.com';
  const password = '123456';
  const nome = 'Dyego';
  const passwordHash = await bcrypt.hash(password, 10);

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    await prisma.user.update({
      where: { id: existing.id },
      data: { passwordHash, role: UserRole.noivo, nome },
    });
    console.log('Conta atualizada:', email);
  } else {
    const demo = await prisma.user.findFirst({
      where: { role: UserRole.noivo, email: 'noivo@demo.com' },
    });
    if (demo) {
      await prisma.user.update({
        where: { id: demo.id },
        data: { email, passwordHash, nome, role: UserRole.noivo },
      });
      console.log('Conta demo convertida para:', email);
    } else {
      await prisma.user.create({
        data: {
          email,
          passwordHash,
          role: UserRole.noivo,
          nome,
        },
      });
      console.log('Conta criada:', email);
    }
  }

  const config = await prisma.casamentoConfig.findFirst();
  if (config) {
    await prisma.casamentoConfig.update({
      where: { id: config.id },
      data: { nomeNoivo: 'Dyego', nomeNoiva: config.nomeNoiva || 'Ludmila' },
    });
  } else {
    await prisma.casamentoConfig.create({
      data: {
        nomeNoivo: 'Dyego',
        nomeNoiva: 'Ludmila',
        mensagemBoasVindas: 'Bem-vindos ao nosso casamento!',
      },
    });
  }

  console.log('Login: dyego.fernandes.vieira@gmail.com / 123456');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
