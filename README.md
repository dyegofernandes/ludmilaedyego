# Ludmila & Dyego

App de gestão do casamento: gastos, tarefas, agenda, convidados, presentes, RSVP e área dos noivos.

## Estrutura

```
apps/api      # NestJS + Prisma + PostgreSQL
apps/mobile   # Flutter (Android/iOS)
apps/web      # React (navegador) — servido no nginx
docker-compose.yml       # Stack local (Postgres + API + web)
docker-compose.prod.yml  # Stack de produção (Jenkins)
Jenkinsfile
deploy/
```

## Deploy via Jenkins (igual Famili)

1. Publique o código em `https://github.com/dyegofernandes/ludmilaedyego.git` (branch `main`).
2. No Jenkins, crie um job **Pipeline** → *Pipeline script from SCM*:
   - Repo: `https://github.com/dyegofernandes/ludmilaedyego.git`
   - Credentials: `gitHub` (mesmo do Famili / Energiago)
   - Branch: `main`
   - Script path: `Jenkinsfile`
3. (Opcional) Variables do job:
   - `JWT_SECRET`
   - `POSTGRES_PASSWORD`
   - `PUBLIC_WEB_URL` (default `http://207.180.243.108:8086`)

O pipeline faz checkout → gera `.env` → `docker compose -f docker-compose.prod.yml -p casamento up -d --build` → healthcheck.

### Portas no servidor (não conflitam com Famili / Energiago)

| Serviço | Porta |
|---------|-------|
| Casamento API | **3004** |
| Casamento web (nginx) | **8086** |
| Famili API | 3003 |
| Famili web | 8085 |
| Energiago API | 3002 |
| Energiago web | 8084 |

URLs:
- Web: http://207.180.243.108:8086/
- API direta: http://207.180.243.108:3004/api/health
- API via proxy: http://207.180.243.108:8086/api/health

O nginx já aceita o nome **ludmilaedyego** / **ludmilaedyego.com**. Esse nome ainda não existe no DNS da internet. Enquanto isso, convidados entram pelo IP:8086. Quando o domínio estiver registrado, aponte o DNS (registro A) para `207.180.243.108` e no Jenkins use `PUBLIC_WEB_URL=http://ludmilaedyego.com`.

## Subir tudo (Docker local)

```powershell
cd c:\casamento
copy .env.example .env
# (opcional) edite senhas no .env

docker compose up -d --build
```

Na primeira vez, para popular dados de exemplo + tokens:

```powershell
# no .env: RUN_SEED=true  — depois volte para false
docker compose up -d --build
```

Ou só uma vez:

```powershell
$env:RUN_SEED="true"; docker compose up -d --build
```

| Serviço | URL / porta |
|---------|-------------|
| Web | http://ludmilaedyego/ |
| Web (localhost) | http://localhost:8086/ |
| API (direto) | http://localhost:3004/api/health |
| API (via web) | http://ludmilaedyego/api/health |
| Postgres | localhost:5434 |

O nginx responde pelo nome **ludmilaedyego**. Na primeira vez, rode como Administrador:

```powershell
powershell -ExecutionPolicy Bypass -File deploy\add-hosts-ludmilaedyego.ps1
```

Isso faz `http://ludmilaedyego` abrir neste computador. Convidados em outro celular/PC só resolvem esse nome se o DNS da internet apontar para o IP público desta máquina, ou se o nome estiver no hosts deles. Na mesma rede, também funciona pelo IP do PC (porta 80).

Para parar: `docker compose down`  
Para ver logs: `docker compose logs -f api web`

## Flutter (aponta para a API no Docker)

```powershell
cd c:\casamento\apps\mobile
flutter pub get

# Emulador Android:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3004

# Windows / Chrome:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3004

# Device físico (mesma rede):
flutter run --dart-define=API_BASE_URL=http://IP-DA-SUA-MAQUINA:3004
```

## Desenvolvimento local (sem Docker da API/web)

Só o Postgres:

```powershell
docker compose up -d postgres
```

Depois API e web no host:

```powershell
cd apps\api
npm install
npx prisma migrate deploy
npm run start:dev
# → :3001 (use apps/api/.env com DATABASE_URL em :5434)

cd apps\web
npm install
npm run dev
# → :5174
```

## Acessos

### Noivo (Dyego)

| Campo | Valor |
|--------|--------|
| E-mail | `dyego.fernandes.vieira@gmail.com` |
| Senha | `123456` |

A conta é criada automaticamente na subida do container da API.

### Cadastrar a noiva
1. Entre com a conta do Dyego (acesso total).
2. App: **Mais → Configurações → Conta → Cadastrar noiva**
3. Web: aba **Conta → Cadastrar noiva**
4. Ela entra em **Noivos** com o e-mail/senha — **mesmo acesso total**.

Não há cadastro público na tela de login.
- App: **Configurações → Conta → Trocar senha**
- Web: aba **Conta → Trocar senha**

### Convidados
1. Cadastre o convidado na aba **Convidados**.
2. Use **Copiar link** e envie (WhatsApp, e-mail, etc.).
3. O convidado abre o link, entra na área de convidado e pode **criar e-mail e senha**.
4. Depois entra em **Convidados** no login com esse e-mail. Continua só com acesso de convidado.

### Links de exemplo (com `RUN_SEED=true`)
`http://ludmilaedyego/convite/CERIM-LD26` · `http://ludmilaedyego/convite/PAD-CARLOS` · `http://ludmilaedyego/convite/CONV-JULI`

## Variáveis

Copie `.env.example` → `.env`. Principais:

```
POSTGRES_PASSWORD=casamento
JWT_SECRET=casamento-dev-secret-change-in-prod
WEB_PORT=8086
PUBLIC_WEB_URL=http://ludmilaedyego
API_PORT=3004
RUN_SEED=false
```

Em produção, troque `POSTGRES_PASSWORD` e `JWT_SECRET`.
