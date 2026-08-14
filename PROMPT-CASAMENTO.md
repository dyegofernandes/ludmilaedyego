# Prompt de desenvolvimento — App Casamento

Cole este documento inteiro em um agente de IA (Cursor, etc.) e peça: **"Implemente este prompt"** ou **"Gere o protótipo visual das telas descritas"**.

Este prompt segue o mesmo padrão técnico e de organização do projeto **LavaRápido** (`PROMPT-LAVARAPIDO.md`): Flutter mobile + Supabase (Postgres, Auth, Storage, Realtime), com `AppStore` centralizado e papéis distintos no app.

---

## Papel do agente

Você é um product designer + engenheiro mobile sênior. Sua tarefa é projetar e/ou implementar o aplicativo **Casamento**, um sistema de gestão do casamento com área gerencial dos noivos e portal para padrinhos/convidados, multiplataforma (Android e iPhone), com banco de dados na nuvem.

Responda e implemente sempre em **português (Brasil)** na interface e na documentação do produto.

---

## Visão do produto

O Casamento permite que os **noivos** (área gerencial):

- cadastrem e controlem **itens de gasto** do casamento;
- criem e **aprovem tarefas / coisas a fazer**;
- cadastrem **convidados**;
- vinculem **padrinhos** a partir da lista de convidados (sem cadastro paralelo de pessoa);
- adicionem **fotos** dos noivos ou do evento;
- cadastrem a **lista de presentes** que desejam receber;
- configurem nomes dos noivos, data, local e capa do casamento.

E permite que **padrinhos** e **convidados**:

- entrem no app (login);
- vejam o que os noivos solicitaram (presentes e, para padrinhos, tarefas atribuídas);
- confirmem presença (RSVP: sim / não / talvez);
- vejam fotos liberadas;
- reservem um presente da lista (“vou presentear”).

O branding (nomes dos noivos + capa) configurado pelos noivos deve aparecer no splash, cabeçalhos e área do convidado/padrinho.

---

## Stack obrigatória (MVP)

| Camada | Tecnologia |
|--------|------------|
| App mobile | **Flutter** (Android + iOS) |
| Backend / DB | **Supabase** (Auth, Postgres, Storage, Realtime) |
| Estado | **Provider** + `AppStore` (`ChangeNotifier`) |
| Rotas | **go_router** |
| Config | `--dart-define=SUPABASE_URL` e `SUPABASE_ANON_KEY` + **modo demo** sem Supabase |

Não use Nest/Express/Spring nem API REST própria neste MVP — o Flutter fala direto com Supabase (PostgREST), como no LavaRápido. Não use React Native.

---

## Personas

### 1. Noivo / admin (`role: noivo`)
Um ou ambos os noivos. Acesso total: gastos, tarefas/aprovações, convidados, padrinhos, fotos, presentes, configuração do casamento.

### 2. Padrinho (`role: padrinho`)
Pessoa já cadastrada como convidado e vinculada como padrinho/madrinha. Acesso: RSVP, lista de presentes, fotos liberadas, tarefas/solicitações atribuídas a si.

### 3. Convidado (`role: convidado`)
Convidado com login. Acesso limitado: RSVP, ver e reservar presentes, ver fotos liberadas, ver dados públicos do casamento (nomes, data, local).

---

## Funcionalidades detalhadas

### 1. Autenticação
- Login por e-mail e senha (Supabase Auth).
- Papéis: `noivo`, `padrinho`, `convidado` (campo `role` em `profiles`).
- Após login, redirecionar para home conforme o papel:
  - `noivo` → shell gerencial;
  - `padrinho` → home padrinho;
  - `convidado` → home convidado.
- Cadastro de conta do convidado/padrinho: noivos cadastram a pessoa em `convidados` e depois vinculam `user_id` (ou o próprio convidado cria conta com e-mail já existente na lista — no MVP, preferir: noivo cria/atualiza vínculo; seeds demo cobrem os três papéis).
- Auto-cadastro público aberto **não** cria `noivo`. Role `noivo` só via seed/SQL ou promoção manual.

### 2. Configuração do casamento (somente noivo)
Tela **Configurações** com:
- **Nome do noivo** e **nome da noiva** (obrigatórios);
- **Data** e **horário** da cerimônia;
- **Local** (texto);
- **Capa / foto principal** (upload PNG/JPG; preview; botão “Alterar capa”);
- Mensagem de boas-vindas (opcional);
- WhatsApp de contato dos noivos (opcional, para `wa.me`).

Regras:
- Só `noivo` pode editar.
- Nomes e capa refletem imediatamente no splash, login e homes de convidado/padrinho.
- Capa no Storage (`capa/capa.*`); URL em `casamento_config.capa_url`.

### 3. Gastos (somente noivo)
CRUD de itens de gasto:
- descrição;
- categoria (ex.: buffet, decoração, foto, traje, igreja, outros);
- valor previsto (`numeric`);
- valor real (`numeric` nullable);
- status: `pendente` | `pago` | `cancelado`;
- data prevista / data pagamento (opcional);
- observações (opcional).

Na listagem: total previsto, total pago e restante. Filtro por categoria e status.

### 4. Tarefas / aprovações (gerencial + visão padrinho)
Itens “a fazer” no casamento, com fluxo de aprovação:

`pendente` → `aprovado` → `feito`

- Também permitir `rejeitado` e `cancelado`.
- Campos: título, descrição, responsável opcional (`padrinho_id` ou texto livre), prazo, status, prioridade (`baixa` | `media` | `alta`).
- **Noivo**: CRUD completo; aprova, rejeita, marca como feito.
- **Padrinho**: vê apenas tarefas atribuídas a si; pode marcar progresso para `feito` quando já estiver `aprovado` (não aprova sozinho no MVP).
- Convidado comum: sem acesso a tarefas.

### 5. Convidados (somente noivo cadastra; convidado edita próprio RSVP)
Campos mínimos:
- nome completo;
- telefone (WhatsApp);
- e-mail (opcional; usado para vincular login);
- lado: `noivo` | `noiva` | `ambos`;
- mesa (texto/número opcional);
- quantidade de acompanhantes (int default 0);
- `rsvp`: `pendente` | `sim` | `nao` | `talvez`;
- `user_id` uuid nullable (FK profiles, se tiver login);
- observações (opcional).

Lista pesquisável (nome, telefone, e-mail). Indicadores de RSVP na listagem.

### 6. Padrinhos (somente noivo)
- **Não** cadastrar pessoa do zero: escolher um registro de `convidados`.
- Campos: `convidado_id` (único), tipo (`padrinho` | `madrinha`), papel/função (ex.: alianças, livro, padrinho de honra), ordem de exibição.
- Ao vincular, se o convidado tiver `user_id`, atualizar `profiles.role` para `padrinho` (se ainda não for `noivo`).
- Remover vínculo de padrinho não apaga o convidado.

### 7. Fotos
- Upload (câmera ou galeria) pelos noivos.
- Tipos: `noivos` | `evento` | `outro`.
- Flag `publico` (boolean): se true, convidados/padrinhos veem; se false, só noivos.
- Armazenar no **Supabase Storage**; salvar URL na tabela `fotos`.
- Galeria com grid; noivo pode excluir.

### 8. Lista de presentes
**Noivo** — CRUD:
- nome;
- descrição (opcional);
- link da loja (opcional);
- valor estimado (opcional);
- imagem URL (opcional);
- `reservado_por_convidado_id` nullable;
- ativo (boolean).

**Convidado / padrinho**:
- ver presentes ativos;
- reservar um presente (“Vou presentear”) — um presente só pode ter um reservante;
- desfazer própria reserva;
- não ver quem reservou outros presentes além do próprio (noivo vê tudo).

### 9. RSVP (convidado e padrinho)
- Na home: destaque para confirmar presença.
- Opções: `sim`, `nao`, `talvez`.
- Atualiza o registro em `convidados` vinculado ao `user_id`.
- Noivo vê RSVP consolidado (contagens) na área de convidados.

### 10. Área do convidado / padrinho
- Home: nomes dos noivos, data/local, status do próprio RSVP, CTA presentes e fotos.
- Padrinho: seção extra “Minhas tarefas” / solicitações dos noivos.
- Sem acesso a gastos nem configuração.

---

## Telas principais (descrição visual para protótipo)

Direção visual: celebrativo e elegante, atmosfera de casamento (luz suave, textura sutil ou foto de capa em full-bleed no hero). **Não** usar cream/terracotta genérico de IA, **não** tema roxo/indigo padrão, **não** dark mode como padrão, **não** cards no hero, **não** pills excessivos. Tipografia expressiva (evitar Inter/Roboto/Arial). Nomes dos noivos são o sinal hero-level no primeiro viewport (branding do evento).

### T1 — Splash
- Fundo full-bleed com capa do casamento (ou gradiente/textura se ainda não houver capa).
- Nomes dos noivos centralizados, hero-level (ex.: “Ana & Bruno”).
- Transição suave para Login (~1,5s).

### T2 — Login
- Nomes / capa no topo.
- Campos e-mail e senha.
- Botão “Entrar”.
- Uma composição clara; sem cards decorativos.

### T3 — Home Noivos (resumo gerencial)
- App bar com nomes dos noivos.
- Resumo: totais de gastos, RSVPs confirmados, tarefas pendentes de aprovação, presentes reservados.
- Bottom nav: Início | Gastos | Tarefas | Convidados | Mais (Presentes, Fotos, Padrinhos, Config).

### T4 — Gastos (Noivo)
- Lista de itens com valor e status.
- Totais no topo (previsto / pago / restante) — fora do hero; seção própria.
- CTA “Novo gasto”.
- Filtros por categoria/status.

### T5 — Tarefas / Aprovações (Noivo)
- Lista por status (pendente de aprovação em destaque).
- Tap → detalhe: aprovar, rejeitar, marcar feito, atribuir padrinho.
- CTA “Nova tarefa”.

### T6 — Convidados (Noivo)
- Lista pesquisável com chip/indicador de RSVP.
- Tap → editar / ver detalhe.
- CTA “Novo convidado”.
- Resumo de contagens RSVP.

### T7 — Padrinhos (Noivo)
- Lista de padrinhos/madrinhas com papel.
- CTA “Vincular padrinho” → picker da lista de convidados + tipo + papel.

### T8 — Presentes (Noivo)
- Lista com status livre/reservado e nome de quem reservou.
- CRUD completo.

### T9 — Fotos (Noivo)
- Grid de fotos + “Adicionar foto”.
- Toggle público/privado por item.
- Tipos noivos/evento/outro.

### T10 — Configurações do casamento (Noivo)
- Preview da capa (grande).
- Nomes, data, local, WhatsApp, mensagem.
- Botão “Salvar” + feedback.

### T11 — Home Convidado
- Header com nomes dos noivos + data/local.
- Bloco principal: RSVP (confirmar presença).
- Atalhos: Presentes | Fotos.

### T12 — Home Padrinho
- Igual à home convidado + bloco “Solicitações / minhas tarefas”.

### T13 — Presentes (Convidado/Padrinho)
- Lista de presentes ativos.
- Botão “Vou presentear” / “Cancelar minha reserva”.
- Sem expor reservantes de outros itens.

### T14 — Fotos públicas (Convidado/Padrinho)
- Grid somente de fotos com `publico = true`.

### T15 — Minhas tarefas (Padrinho)
- Lista das tarefas atribuídas; marcar como feito quando aprovadas.

---

## Modelo de dados (Supabase / Postgres)

### `profiles`
- `id` uuid PK (FK auth.users)
- `role` text (`noivo` | `padrinho` | `convidado`)
- `nome` text
- `telefone` text nullable
- `created_at` timestamptz

### `casamento_config`
- `id` uuid PK (uma linha ativa)
- `nome_noivo` text not null
- `nome_noiva` text not null
- `data_cerimonia` timestamptz nullable
- `local` text nullable
- `capa_url` text nullable
- `whatsapp` text nullable
- `mensagem_boas_vindas` text nullable
- `updated_at` timestamptz

### `gastos`
- `id` uuid PK
- `descricao` text not null
- `categoria` text not null
- `valor_previsto` numeric(12,2) not null default 0
- `valor_real` numeric(12,2) nullable
- `status` text not null default `pendente`
  check (`pendente` | `pago` | `cancelado`)
- `data_prevista` date nullable
- `data_pagamento` date nullable
- `observacoes` text nullable
- `created_at` timestamptz

### `tarefas`
- `id` uuid PK
- `titulo` text not null
- `descricao` text nullable
- `status` text not null default `pendente`
  check (`pendente` | `aprovado` | `feito` | `rejeitado` | `cancelado`)
- `prioridade` text not null default `media`
  check (`baixa` | `media` | `alta`)
- `prazo` date nullable
- `padrinho_id` uuid nullable FK padrinhos
- `criado_por` uuid nullable FK profiles
- `created_at` timestamptz
- `updated_at` timestamptz

### `convidados`
- `id` uuid PK
- `user_id` uuid nullable FK profiles (se tiver login)
- `nome` text not null
- `telefone` text nullable
- `email` text nullable
- `lado` text not null default `ambos`
  check (`noivo` | `noiva` | `ambos`)
- `mesa` text nullable
- `acompanhantes` int not null default 0
- `rsvp` text not null default `pendente`
  check (`pendente` | `sim` | `nao` | `talvez`)
- `observacoes` text nullable
- `created_at` timestamptz

### `padrinhos`
- `id` uuid PK
- `convidado_id` uuid not null unique FK convidados on delete cascade
- `tipo` text not null check (`padrinho` | `madrinha`)
- `papel` text nullable
- `ordem` int not null default 0
- `created_at` timestamptz

### `fotos`
- `id` uuid PK
- `tipo` text not null check (`noivos` | `evento` | `outro`)
- `url` text not null
- `legenda` text nullable
- `publico` boolean not null default false
- `created_at` timestamptz

### `presentes`
- `id` uuid PK
- `nome` text not null
- `descricao` text nullable
- `link` text nullable
- `valor_estimado` numeric(12,2) nullable
- `imagem_url` text nullable
- `ativo` boolean not null default true
- `reservado_por_convidado_id` uuid nullable FK convidados
- `reservado_em` timestamptz nullable
- `created_at` timestamptz

### Políticas (RLS) — resumo
- Helper `public.is_noivo()` (security definer) baseado em `profiles.role = 'noivo'`.
- **Noivo**: CRUD amplo em todas as tabelas de negócio; leitura total de RSVP e reservas.
- **Convidado / padrinho**:
  - ler `casamento_config`;
  - ler/atualizar **próprio** `convidados` (via `user_id`) — principalmente `rsvp`;
  - ler `presentes` ativos; reservar/desreservar apenas se `reservado_por_convidado_id` for null ou for o próprio;
  - ler `fotos` com `publico = true`;
  - padrinho: ler `tarefas` onde `padrinho_id` aponta para seu vínculo; atualizar status para `feito` quando `aprovado`.
- `gastos` e `casamento_config` (escrita): só noivo.
- `padrinhos` (escrita): só noivo.

### Storage buckets
- `capa` — capa / foto principal do casamento
- `fotos-casamento` — galeria de fotos

### Seeds sugeridos (modo demo / SQL)
- 1 usuário `noivo`, 1 `padrinho`, 1 `convidado`
- `casamento_config` com nomes fallback “Noivo & Noiva”
- Alguns gastos, tarefas, convidados, 1 padrinho vinculado, presentes e fotos mock

---

## Regras de negócio

1. Padrinho **só** existe vinculado a um convidado (`convidado_id` único).
2. Um presente só pode ser reservado por **um** convidado; quem reservou pode cancelar; noivo pode liberar reserva.
3. Convidado/padrinho não acessam gastos nem edição de configuração.
4. Só noivo aprova/rejeita tarefas; padrinho conclui tarefas já aprovadas atribuídas a si.
5. Fotos privadas (`publico = false`) invisíveis para convidado/padrinho.
6. RSVP do convidado autenticado atualiza apenas o próprio registro em `convidados`.
7. Valores monetários em BRL formatados (`R$ 1.250,00`).
8. Realtime opcional no MVP para RSVP/presentes na home do noivo (desejável; se complexo, refresh manual aceitável no MVP).
9. Modo demo sem Supabase: dados locais + contas hardcoded (como no LavaRápido).

---

## Estrutura sugerida do projeto Flutter

```
app/
  lib/
    main.dart
    app.dart              # Provider + GoRouter + redirects por role
    core/                 # tema, constantes, formatters, widgets base
    data/
      app_store.dart      # camada única de dados (demo + Supabase)
    models/
      models.dart
    features/
      auth/
      home_noivo/
      gastos/
      tarefas/
      convidados/
      padrinhos/
      presentes/
      fotos/
      configuracoes/
      convidado_home/
      padrinho_home/
  android/
  ios/
  pubspec.yaml
supabase/
  schema.sql              # tabelas, RLS, seeds, storage
  migration_*.sql         # patches futuros
PROMPT-CASAMENTO.md       # esta especificação
README.md                 # setup (após implementação)
```

Usar navegação clara (`go_router`). Tema via `ThemeData` + variáveis de cor nomeadas. Erros de escrita no `AppStore` no padrão `Future<String?>` (`null` = ok).

---

## Critérios de aceite do MVP

- [ ] App roda em Android e iOS (Flutter).
- [ ] Login com papéis `noivo`, `padrinho` e `convidado`, com homes distintas.
- [ ] Noivo cadastra gastos e vê totais previsto/pago/restante.
- [ ] Noivo cria tarefas, aprova/rejeita e marca como feito.
- [ ] Noivo cadastra convidados e acompanha RSVP.
- [ ] Noivo vincula padrinho **somente** a partir da lista de convidados.
- [ ] Noivo sobe fotos (públicas/privadas); convidado/padrinho veem só públicas.
- [ ] Noivo monta lista de presentes; convidado/padrinho reservam e cancelam própria reserva.
- [ ] Convidado/padrinho confirmam presença (RSVP).
- [ ] Padrinho vê tarefas atribuídas e conclui as aprovadas.
- [ ] Noivo configura nomes, data, local e capa; splash/login/homes refletem.
- [ ] Dados persistidos no Supabase (nuvem) e modo demo sem chaves.

---

## Ordem de implementação sugerida

1. Projeto Flutter + tema + rotas + splash/login (mock/demo).
2. Supabase: `schema.sql`, RLS, Auth, seeds (noivo, padrinho, convidado, `casamento_config`).
3. Configurações do casamento (nomes + capa).
4. CRUD convidados + RSVP.
5. Padrinhos (vínculo a partir de convidados) + ajuste de `role`.
6. Gastos (CRUD + totais).
7. Tarefas / aprovações (+ visão padrinho).
8. Presentes (CRUD noivo + reserva convidado).
9. Fotos (Storage + flag público).
10. Homes convidado/padrinho + polimento visual.
11. README de setup + checklist de aceite.

---

## Instruções finais para o agente

1. Siga esta especificação sem inventar features fora do MVP (pagamentos online, convite digital complexo, multi-casamento/tenant, chat, mapa interativo, etc.).
2. Priorize um fluxo utilizável de ponta a ponta nos três papéis.
3. Se for só protótipo visual: implemente as telas T1–T15 com navegação clicável e dados mockados, já mostrando nomes/capa editáveis em Configurações.
4. Se for implementação completa: entregue código Flutter em `app/` + SQL em `supabase/schema.sql` + README de setup (espelhando a organização do LavaRápido).
5. UI em português do Brasil; código e commits em linguagem consistente com o repositório.
6. Branding dinâmico a partir de `casamento_config` — nunca hardcodar os nomes finais além do fallback “Noivo & Noiva”.
7. Reaproveite os padrões do LavaRápido: `AppStore`, Provider, go_router, `--dart-define`, modo demo, Storage, RLS por papel.
`)