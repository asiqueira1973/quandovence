# Spec — Quando Vence? (app de lembrete de vencimento de documentos pessoais)

**Versão do documento:** 1.2
**Responsável de produto:** Alexandre Siqueira
**Status:** rascunho
**Data:** 2026-08-02

## Como usar este documento

Este documento é a fonte única de verdade do produto "Quando Vence?" para quem for implementá-lo, incluindo um agente de código. Toda decisão de UX, dado, regra ou fluxo que o time de implementação precisar já está — ou deveria estar — resolvida aqui; quando não está, ela foi movida deliberadamente para a seção 24 (Assunções declaradas) ou 25 (Perguntas abertas).

**Antes de gerar qualquer código a partir deste spec, revise a seção 24.** Assunção não revisada vira verdade no momento em que o agente de código começa a implementar.

**Referência visual definitiva:** o protótipo gerado no Claude Design (pasta `quando-vence-handoff/`, arquivo `quando-vence/project/Quando Vence.dc.html`) é a fonte de verdade de layout, cor, espaçamento e copy — não a descrição em prosa da seção 16. O agente de código deve ler esse arquivo (e o `README.md` do bundle) por inteiro antes de implementar qualquer tela, e recriar pixel a pixel em SwiftUI — sem copiar a estrutura interna do HTML, só o resultado visual.

---

## 0. Princípios não-negociáveis

1. **Local-first, sem exceção.** O app funciona 100% offline, sempre. Nenhuma chamada de rede no MVP — nem para sincronizar, nem para telemetria.
2. **Cadastrar um documento nunca leva mais de 30 segundos.** Nome, categoria e data já bastam para salvar; foto é opcional e nunca bloqueia o cadastro.
3. **Uma tabela só.** Sem relação de chave estrangeira, sem múltiplos perfis, sem servidor — cada regra nova só se justifica se este princípio não bastar para resolvê-la de outro jeito.
4. **Cor tem um único significado: urgência.** Vermelho é vencido, laranja é "vence em breve", cinza-neutro é "em dia". Nenhuma outra cor de marca ou decoração compete com esse código — é o oposto do Estante de propósito (ver seção 16).
5. **O app nunca deixa a pessoa descobrir um vencimento tarde demais.** Todo documento cadastrado tem aviso agendado; a ausência de aviso é sempre uma escolha explícita da pessoa em Ajustes, nunca um esquecimento do app.

---

## 1. Visão e problema

"Quando Vence?" é um app iOS para cadastrar documentos pessoais com data de vencimento (passaporte, CNH, RG, vistos, licenças profissionais, seguros, carteirinha de plano de saúde) e receber avisos antes que vençam. Nasce de um problema concreto e sem boa solução em português: hoje, quem quer isso monta uma gambiarra de lembretes manuais espalhados (Notas, Calendário, Evernote) — não existe um app dedicado, simples e confiável nesse nicho em PT-BR. A referência internacional mais próxima (RemindMe) não tem tração nem localização para o Brasil.

**Avaliação de complexidade:** baixa a média para um desenvolvedor solo — mesmo perfil do Estante. Não há backend, não há login, não há integração com API externa. A maior parte do esforço está em UI (lista agrupada por urgência, calendário customizado de seleção de data, tela de ajustes com toggles) e no agendamento de notificações locais (`UNUserNotificationCenter`), que é a peça nova em relação ao Estante — o Estante não tinha lembrete algum.

**Anti-escopo** — o que este produto explicitamente não é:
- Não guarda o documento em si como identidade digital (não substitui CNH Digital, carteira de trabalho digital etc.) — guarda só o registro de vencimento e, opcionalmente, uma foto de referência.
- Não lê data de vencimento automaticamente de uma foto (sem OCR no MVP).
- Não tem conceito de "pessoa" ou "perfil" — documento de terceiro (ex.: "RG do meu pai") é só texto livre no nome, não uma entidade separada.
- Não sincroniza entre aparelhos nem tem conta no MVP.
- Não compartilha documentos entre usuários do app.
- Não gera cobrança recorrente — é compra única (IAP não-consumível), mesmo modelo do Estante.

---

## 2. Personas e cenários de uso

- **Pessoa organizada que já foi pega de surpresa uma vez** — passaporte vencido em cima da viagem, CNH vencida na blitz. Quer nunca mais depender da própria memória.
- **Cuidador informal de documentos de terceiros** — cuida da parte administrativa de pais idosos ou de filhos e hoje mistura isso com os próprios lembretes, sem separação clara.
- **Profissional com licença/certificado com prazo** (ex.: NR-10, alvará, CRM/CREA) — vencimento tem consequência prática (não pode trabalhar), não é só burocracia.

O cenário mais difícil de uso, e que mais define a arquitetura, é: a pessoa está regularizando um documento agora (renovou o passaporte, por exemplo) e precisa editar a data em segundos, sem precisar re-cadastrar do zero — e o aviso antigo precisa desaparecer e o novo precisa ser reagendado automaticamente, sem deixar notificação órfã.

---

## 3. Escopo do MVP

### Dentro do MVP

- Cadastro de documento com nome (obrigatório), categoria (viagem/pessoal/trabalho/saúde/veículo, obrigatória, padrão "pessoal"), data de vencimento (obrigatória), foto de referência (opcional, salva só no aparelho).
- Tela inicial (lista) agrupada em três seções por urgência: **Vencidos**, **Vence em breve** (≤30 dias), **Em dia** (>30 dias) — ordenada por proximidade do vencimento dentro de cada grupo, mais urgente primeiro.
- Resumo no topo da lista ("N documentos precisam de atenção" ou "Tudo em dia — nada a fazer agora").
- Tela de detalhe: número em destaque de dias até/desde o vencimento, categoria, data completa, resumo dos avisos ativos, foto (se houver), excluir.
- Editar documento (reaproveita a mesma tela de cadastro, pré-preenchida).
- Excluir documento (com reagendamento/cancelamento de notificações pendentes daquele documento).
- Tela de Ajustes: quatro avisos configuráveis por toggle (90 / 30 / 7 / 1 dia antes do vencimento — 90/30/7 ativos por padrão, 1 dia desativado por padrão), horário de envio dos avisos (ciclo entre 4 horários fixos: 08:00, 09:00, 12:00, 19:00 — padrão 09:00), contagem de documentos salvos, confirmação de que os dados ficam só no aparelho.
- Aviso automático no dia exato do vencimento, sempre enviado, independente dos toggles de 90/30/7/1 dia (ver regra 11.3).
- Modelo de negócio: download grátis, com **paywall ao atingir 5 documentos cadastrados** e compra única (IAP não-consumível) de **R$ 19,90** para desbloquear cadastro ilimitado — mesmo preço já usado nos outros apps (seção 4, 11 e 24).
- Identidade visual sóbria e neutra — ver seção 16.

### Fora do MVP

| Item | Destino | Motivo / dependência |
|---|---|---|
| Sincronização entre aparelhos via iCloud/CloudKit | Adiado — v1.1 | Mesma decisão do Estante: MVP é local em um único aparelho; mudança pequena em SwiftData se decidir depois (seção 28) |
| Leitura automática de data de vencimento por foto (OCR) | Adiado — v1.2 | Depende de decidir se o app continua 100% offline ou passa a usar Vision framework local (não precisa de rede, mas é escopo novo) |
| Categorias customizáveis pelo usuário | Descartado no MVP | As 5 categorias fixas cobrem os casos de uso mapeados; abrir categoria livre complica o ícone e a cor (seção 24) |
| Exportação em CSV/PDF da lista de documentos | Descartado no MVP | Não pedido; diferente do Estante, aqui não há "post pronto" nem necessidade de compartilhar a lista |
| Conceito de "pessoa"/perfil para documentos de terceiros | Descartado | Contraria o princípio 0.3 (uma tabela só); nome do documento como texto livre já resolve (seção 24) |
| Layout dedicado para iPad | Descartado | App restrito a iPhone (decisão explícita, mesma do Hora do Remédio) — não haverá versão iPad em nenhuma release |
| Login / conta de usuário | Descartado | Contraria o princípio 0.1 (local-first) |

---

## 4. Arquitetura

- **Plataforma:** iOS nativo, SwiftUI, mínimo iOS 26 (SDK obrigatório para submissões à App Store a partir de 28/abr/2026 — pesquisa reaproveitada da spec do Estante, 2026-08-01). **Somente iPhone** — mesma decisão do Hora do Remédio (diferente do Estante, que sai para iPhone e iPad). No App Store Connect, marcar "iPhone" como único destino suportado; não gerar layout nem testar em iPad.
- **Persistência:** SwiftData, local-first, sem `cloudKitDatabase` configurado no MVP (mesma decisão do Estante — fácil de ligar depois).
- **Compra:** StoreKit 2, produto único não-consumível.
- **Notificações:** `UserNotifications` framework, notificações locais agendadas (`UNCalendarNotificationTrigger`), sem push remoto — não há servidor para disparar push mesmo.
- **Sem dependência de rede em nenhum ponto do MVP.**
- **Reaproveitar** o mesmo bundle ID prefix e Apple Developer Team já usados no Estante e no Hora do Remédio (ver seção 27).
- **Projeto de referência declarado:** Estante (spec "O que eu ando lendo") — mesma stack, mesmas convenções de nomenclatura e estrutura de documento, mesmo padrão de paywall.

---

## 5. Perfis de usuário

Não se aplica — app single-user, sem conta, sem múltiplos perfis de acesso. Seção mantida vazia intencionalmente (ver princípio 0.3).

## 6. Autenticação e identidade

Não se aplica — não há login. Seção mantida vazia intencionalmente.

---

## 7. Modelo de dados

### Diagrama (texto)

```
documento (tabela única, sem chave estrangeira, sem relação)
```

### Tabela `documento`

| Campo | Tipo | Nulo? | Default | Descrição |
|---|---|---|---|---|
| `id` | uuid | não | `gen_random_uuid()`-equivalente do SwiftData | Identificador único |
| `nome` | text | não | — | Nome livre do documento, inclusive de terceiros (ex.: "RG do meu pai (Antônio)") |
| `categoria` | enum `categoria_documento` | não | `pessoal` | Uma das 5 categorias fixas |
| `data_vencimento` | date | não | — | Data de vencimento; usada para calcular urgência e agendar avisos |
| `foto` | binary (`@Attribute(.externalStorage)`) | sim | `null` | Nulo quando a pessoa optou por não anexar foto — é o caso mais comum |
| `criado_em` | timestamp | não | data/hora atual no momento da criação | Auditoria simples, não exibida na UI |
| `atualizado_em` | timestamp | não | data/hora atual, atualizado a cada edição | Auditoria simples, não exibida na UI |

**Enum `categoria_documento`:** `viagem`, `pessoal`, `trabalho`, `saude`, `veiculo` — valores e ordem exatamente como no design (ver seção 16), sem tradução nem sinônimo.

**Constraints:** `nome` não pode ser string vazia após `trim()` (validado na UI antes de habilitar o botão Salvar — ver épico 8.3). Sem unique constraint: duas pessoas podem ter documentos com o mesmo nome (dois "Passaporte" de dois membros da família, por exemplo).

**Estratégia de exclusão:** hard delete. Não há histórico, relatório ou tela que dependa de documento excluído continuar existindo — soft delete só adicionaria complexidade sem benefício (contraria o princípio 0.3).

**Lógica que vive no banco:** nenhuma. Todo cálculo (dias até vencimento, cor de status, agrupamento) é derivado em tempo de leitura na camada de UI/ViewModel, nunca persistido — evita o dado computado ficar desatualizado.

**Dados de seed:** nenhum em produção. Para desenvolvimento/preview, reaproveitar os 7 documentos de exemplo do protótipo do Claude Design (CNH, Passaporte, RG do pai, Seguro do carro, Carteirinha do plano, Certificado NR-10, Visto EUA) como dados de preview do SwiftUI, nunca em build de release.

### Configurações (não é tabela — `UserDefaults`/`@AppStorage`)

Decisão deliberada de **não** modelar Ajustes como entidade SwiftData: são 5 valores escalares, sem necessidade de histórico, consulta ou relação. Usar `@AppStorage`:

| Chave | Tipo | Default | Descrição |
|---|---|---|---|
| `aviso_90_dias` | bool | `true` | Aviso 90 dias antes do vencimento |
| `aviso_30_dias` | bool | `true` | Aviso 30 dias antes do vencimento |
| `aviso_7_dias` | bool | `true` | Aviso 7 dias antes do vencimento |
| `aviso_1_dia` | bool | `false` | Aviso 1 dia antes do vencimento |
| `horario_aviso_index` | int | `1` | Índice no array fixo `["08:00","09:00","12:00","19:00"]` — índice 1 = 09:00 |

O estado de compra (paywall desbloqueado ou não) **não** é lido de `UserDefaults` como fonte de verdade — é derivado de `Transaction.currentEntitlements` do StoreKit 2 a cada abertura do app, e só cacheado localmente para leitura instantânea offline (ver seção 11).

---

## 8. Épicos e critérios de aceite

### 8.1 Listar documentos (Home)
Objetivo: mostrar todos os documentos agrupados por urgência, com o mais urgente sempre visível primeiro.

Fluxo: app abre → calcula urgência de cada documento com base em `data_vencimento` vs. hoje → agrupa em Vencidos / Vence em breve / Em dia → mostra resumo no topo → estado vazio quando não há nenhum documento cadastrado ainda ("Adicione seu primeiro documento").

Critérios de aceite:
- [ ] Documento com `data_vencimento` no passado aparece em "Vencidos", com `statusLabel` "Venceu ontem" (exatamente 1 dia) ou "Venceu há N dias".
- [ ] Documento com 0 a 30 dias até o vencimento aparece em "Vence em breve", com `statusLabel` "Vence hoje" (0 dias), "Amanhã" (1 dia) ou "Em N dias".
- [ ] Documento com mais de 30 dias aparece em "Em dia", com `statusLabel` em meses (<365 dias) ou anos (≥365 dias), conforme regra 11.2.
- [ ] Seção sem nenhum documento não é exibida (ex.: sem vencidos, a seção "Vencidos" nem aparece).
- [ ] Resumo no topo mostra "Tudo em dia — nada a fazer agora" quando não há nenhum documento vencido nem vencendo em breve; caso contrário, "N documento(s) precisam de atenção" com singular/plural corretos.
- [ ] Tocar em qualquer card abre o Detalhe daquele documento.
- [ ] Botão "Adicionar documento" sempre visível, fixo na base da tela.

### 8.2 Ver detalhe do documento
Objetivo: mostrar todos os dados de um documento e permitir editar/excluir.

Critérios de aceite:
- [ ] Número grande mostra dias até o vencimento (ou dias desde, se vencido) com legenda correspondente ("dias até o vencimento" / "dias desde o vencimento" / "vence hoje").
- [ ] Mostra data completa por extenso, categoria e resumo dos avisos ativos (ex.: "90, 30, 7 dias antes" ou "Desativados" se nenhum estiver ligado).
- [ ] Foto aparece somente se `foto != null`.
- [ ] Botão "Editar" abre o formulário pré-preenchido com os dados atuais.
- [ ] Botão "Excluir documento" pede confirmação antes de excluir (ver regra 11.5) e, ao confirmar, remove o documento e todas as notificações pendentes associadas, voltando para a lista.

### 8.3 Cadastrar documento
Objetivo: criar um novo documento em menos de 30 segundos.

Critérios de aceite:
- [ ] Botão "Salvar" fica desabilitado (cinza, `#C7C7CC`) enquanto o campo Nome estiver vazio ou só espaços.
- [ ] Categoria tem seleção única entre as 5 opções, com "Pessoal" pré-selecionada por padrão.
- [ ] Calendário customizado (não o `DatePicker` nativo em roda) permite navegar entre meses e selecionar o dia; data de hoje é destacada mesmo sem estar selecionada.
- [ ] Data padrão ao abrir o formulário de novo documento: hoje + 30 dias.
- [ ] Foto é opcional; ao anexar, mostra "Foto anexada" e ação "Remover"; ao não anexar, mostra "Adicionar foto" e ação "Escolher", com a legenda "Fica salva só neste aparelho" sempre visível.
- [ ] Ao salvar com sucesso, agenda as notificações do documento (épico 8.7) e navega para o Detalhe do documento recém-criado.
- [ ] **Se o total de documentos já cadastrados for 5 e a pessoa não tiver o desbloqueio comprado**, tocar em "Adicionar documento" na lista não abre o formulário — abre a tela de Paywall (épico 8.8) em vez disso.

### 8.4 Editar documento
Objetivo: alterar dados de um documento existente sem duplicar nem perder o histórico de notificações.

Critérios de aceite:
- [ ] Reaproveita a tela de cadastro (8.3), pré-preenchida, com título "Editar" em vez de "Novo documento".
- [ ] Ao salvar, cancela todas as notificações pendentes antigas daquele documento e reagenda com base nos dados novos (regra 11.4) — mesmo que só a data tenha mudado.
- [ ] Editar não conta para o limite do paywall (só criação de documento novo conta).

### 8.5 Excluir documento
Coberto pelos critérios de aceite do épico 8.2.

### 8.6 Ajustes
Objetivo: controlar quando e como os avisos chegam.

Critérios de aceite:
- [ ] Cada um dos 4 toggles (90/30/7/1 dia) liga/desliga independentemente e reagenda **todas** as notificações futuras de **todos** os documentos ao ser alterado (não só as novas — ver regra 11.4).
- [ ] Alterar o horário (ciclando entre os 4 valores fixos) reagenda todas as notificações futuras para o novo horário.
- [ ] Mostra contagem total de documentos salvos e a confirmação "Só neste aparelho" / "Sem conta, sem nuvem, sem sincronização. Nada sai do seu iPhone."

### 8.7 Agendamento de notificações locais
Objetivo: garantir que todo documento cadastrado gera avisos reais no sistema operacional, não só um cálculo em tela.

Critérios de aceite:
- [ ] Na primeira vez que a pessoa tenta salvar um documento, o app solicita permissão de notificação (`UNUserNotificationCenter.requestAuthorization`) se ainda não foi concedida nem negada.
- [ ] Se a permissão for negada, o documento é salvo normalmente (o cadastro nunca é bloqueado por isso), mas a lista mostra um aviso discreto de que as notificações estão desativadas nas Configurações do sistema.
- [ ] Para cada documento, uma notificação é agendada para cada intervalo ativo em Ajustes (90/30/7/1) que ainda esteja no futuro em relação a hoje, mais uma sempre no dia exato do vencimento (regra 11.3), todas no horário configurado.
- [ ] Notificações de um documento excluído ou editado são canceladas antes de reagendar (nunca duas notificações órfãs para o mesmo documento).

### 8.8 Paywall (IAP não-consumível)
Objetivo: bloquear cadastro do 6º documento até a compra, sem nunca bloquear a visualização dos documentos já cadastrados.

Critérios de aceite:
- [ ] Tela de Paywall aparece só ao tentar adicionar o 6º documento sem ter comprado o desbloqueio — nunca ao abrir o app, nunca ao editar/ver/excluir documentos existentes.
- [ ] Compra via sandbox do StoreKit libera o cadastro ilimitado imediatamente após confirmação.
- [ ] "Restaurar compra" funciona numa instalação diferente com o mesmo Apple ID.
- [ ] Estado de compra é verificado via `Transaction.currentEntitlements` a cada abertura do app (não só uma vez, no primeiro launch).

---

## 9. Fluxo principal ponta a ponta (primeiro uso)

1. Pessoa abre o app pela primeira vez → lista vazia, estado "Adicione seu primeiro documento".
2. Toca em "Adicionar documento" → preenche nome, categoria, data → toca em Salvar.
3. App solicita permissão de notificação (se ainda não perguntou) → pessoa aceita ou recusa.
4. Documento salvo → notificações agendadas conforme regra 11.3 (mesmo que a permissão tenha sido negada — agenda mesmo assim; o SO só não entrega) → navega para o Detalhe.
5. Pessoa volta para a lista → vê o documento na seção correspondente à urgência calculada.

Caminho de exceção: pessoa nunca concede permissão de notificação → app continua funcionando 100% como lista/lembrete visual manual; a pessoa só perde os avisos push, nunca o cadastro em si.

---

## 10. Inventário de telas

| Tela | O que mostra | Ações (leitura/escrita) | Lê/escreve |
|---|---|---|---|
| Lista (Home) | Documentos agrupados por urgência + resumo | Leitura; navega para Detalhe ou Formulário | `documento` (leitura) |
| Detalhe | Todos os dados de um documento | Leitura; navega para Editar ou Excluir | `documento` (leitura), `documento` (escrita ao excluir) |
| Formulário (Novo/Editar) | Campos de cadastro | Escrita | `documento` (escrita) |
| Ajustes | Toggles de aviso, horário, contagem | Leitura/escrita | `@AppStorage` (leitura/escrita), `documento` (leitura, só para contagem) |
| Paywall | Oferta de desbloqueio | Escrita (compra) | StoreKit (não lê/escreve `documento`) |

---

## 11. Regras de negócio

| # | Regra | Onde é aplicada |
|---|---|---|
| 11.1 | Urgência: `dias = data_vencimento − hoje`. `dias < 0` → Vencido (vermelho `#C93A2C`). `0 ≤ dias ≤ 30` → Vence em breve (laranja `#C87A12`). `dias > 30` → Em dia (cinza `#C7C7CC`). | Frontend (calculado a cada renderização da lista, nunca persistido) |
| 11.2 | Rótulo de status: vencido há 1 dia → "Venceu ontem"; vencido há N dias → "Venceu há N dias"; 0 dias → "Vence hoje"; 1 dia → "Amanhã"; 2–30 dias → "Em N dias"; 31–364 dias → "Em N meses" (arredondado, `round(dias/30)`); ≥365 dias → "Em N ano(s)" (`floor(dias/365)`, singular só quando `dias < 730`). | Frontend |
| 11.3 | Notificações agendadas por documento: uma para cada intervalo ativo em Ajustes (90/30/7/1 dias antes) cuja data resultante ainda esteja no futuro, **mais uma sempre no dia exato do vencimento**, independente dos toggles — essa última nunca é desligável. | Módulo de notificações (seção 13) |
| 11.4 | Reagendamento: qualquer mudança em (a) data de vencimento de um documento, (b) toggles de Ajustes, ou (c) horário de Ajustes cancela as notificações pendentes afetadas e recria do zero — nunca soma nem deixa duplicata. | Módulo de notificações |
| 11.5 | Exclusão de documento pede confirmação (alerta nativo do iOS) antes de efetivar — ação destrutiva e irreversível (hard delete). | Frontend |
| 11.6 | Paywall: cadastro do 6º documento (contagem de todos os documentos existentes, de qualquer categoria) é bloqueado enquanto `Transaction.currentEntitlements` não confirmar a compra do produto não-consumível. Documentos do 1º ao 5º são sempre gratuitos. Compra desbloqueia para sempre, sem limite adicional. | Frontend + StoreKit 2 |
| 11.7 | Campo `nome` não pode ser string vazia (após `trim()`); é a única validação bloqueante do formulário. | Frontend |

Fusos e viradas de dia: cálculo de `dias` usa a data local do aparelho, à meia-noite (`startOfToday`), igual ao protótipo do Claude Design — sem lógica de fuso horário adicional, dado que é sempre o fuso do próprio aparelho.

---

## 12. Máquina de estados

Não há máquina de estados formal — o único "estado" do sistema é a urgência (regra 11.1), que é sempre recalculada, nunca persistida ou transicionada manualmente. O único ciclo de vida real é o de compra (StoreKit): não comprado → comprado → (restaurado, se reinstalar). StoreKit 2 já garante que não existe estado intermediário observável pelo app.

---

## 13. Contratos de módulos internos (sem backend)

Como é local-first sem servidor, esta seção substitui contratos de API por contratos de módulo interno:

**`AgendadorDeAvisos`** (módulo de notificações)
- `agendar(documento: Documento, config: ConfiguracaoAvisos)` — cria as notificações locais conforme regra 11.3, usando `UNCalendarNotificationTrigger` com o horário de `config.horarioAvisoIndex`.
- `cancelar(documentoId: UUID)` — remove todas as notificações pendentes daquele documento (`removePendingNotificationRequests(withIdentifiers:)`, usando um identificador previsível tipo `"\(documentoId)-90"`, `"\(documentoId)-30"` etc.).
- `reagendarTudo(documentos: [Documento], config: ConfiguracaoAvisos)` — chamado quando Ajustes muda; cancela e recria para todos os documentos de uma vez.

**`GerenciadorDeCompra`** (módulo StoreKit)
- `verificarDesbloqueio() -> Bool` — lê `Transaction.currentEntitlements`, retorna se o produto não-consumível está ativo.
- `comprar() async throws` — inicia o fluxo de compra do StoreKit 2.
- `restaurar() async throws` — chama `AppStore.sync()` e reavalia `verificarDesbloqueio()`.

---

## 14. Relatórios, exportação e importação

Não se aplica — fora do MVP (ver seção 3).

---

## 15. Copy e tom de voz

Copy final já definida no protótipo do Claude Design — não é placeholder, deve ser usada literalmente. Destaques que o agente de código deve reaproveitar exatamente:

- Resumo da lista: `"Tudo em dia — nada a fazer agora"` / `"1 documento precisa de atenção"` / `"N documentos precisam de atenção"`.
- Botão principal: `"Adicionar documento"`.
- Confirmação de privacidade (Ajustes): `"Sem conta, sem nuvem, sem sincronização. Nada sai do seu iPhone."`
- Legenda de foto no formulário: `"Fica salva só neste aparelho."`
- Explicação dos avisos (Ajustes): `"Você recebe um aviso em cada intervalo marcado antes do vencimento — e mais um no dia."`
- Botão destrutivo: `"Excluir documento"` (cor `#C0362B`, mais escura que o vermelho de status para diferenciar "ação perigosa" de "sinalização de urgência").

Tom geral: direto, sem entusiasmo artificial, sem ilustração fofa — o oposto do tom do Estante.

---

## 16. Direção visual / design system

**Fonte de verdade:** o protótipo em `quando-vence-handoff/quando-vence/project/Quando Vence.dc.html`. O que segue é um resumo para consulta rápida — em caso de conflito, o arquivo do protótipo vence.

**Paleta:**
| Uso | Cor |
|---|---|
| Fundo das telas | `#F5F5F7` |
| Fundo externo (frame) | `#E9E9EC` |
| Cards | `#FFFFFF`, com sombra sutil (`0 1px 2px rgba(0,0,0,0.06-0.07)`, `0 4px 14px rgba(0,0,0,0.03-0.04)`), cantos de 12px |
| Texto primário | `#1C1C1E` |
| Texto secundário | `#6E6E73` |
| Texto de rótulo de seção (uppercase) | `#A1A1A6` |
| Texto terciário/placeholder | `#8E8E93` |
| **Vermelho (vencido)** | `#C93A2C` |
| **Laranja (vence em breve)** | `#C87A12` |
| **Cinza-neutro (em dia)** | `#C7C7CC` |
| Vermelho de ação destrutiva (excluir) | `#C0362B` |
| Azul de ação do sistema (links, ‹ voltar, ›) | `#007AFF` (cor padrão do iOS, não é cor de marca do produto) |
| Botão primário (Salvar / Adicionar) | fundo `#1C1C1E`, texto `#FFFFFF` |

**Tipografia:** SF Pro / `-apple-system`, sem fonte customizada.

**Ícones:** SVG de linha (`stroke-width: 1.6-1.7`, sem preenchimento), um por categoria — os 5 paths exatos já estão definidos no protótipo (objeto `CATS`) e devem ser recriados como `Shape`/`Path` do SwiftUI ou convertidos para SF Symbols equivalentes, se existir um SF Symbol suficientemente parecido (decisão livre do agente, desde que o resultado visual bata).

**Cor semântica vs. cor de marca:** este produto **não tem cor de marca** — decisão deliberada (princípio 0.4). Toda cor que aparece (vermelho/laranja/cinza) é status, nunca decoração. É o oposto intencional do Estante, que é colorido por natureza.

**Modo escuro:** não especificado no protótipo — tratar como **livre para o agente**, seguindo as convenções padrão do iOS (cores adaptativas do sistema) já que a paleta é neutra o suficiente para isso não quebrar a leitura de status.

---

## 17. Requisitos não-funcionais

- Abertura do app (cold start) até a lista renderizada: **< 1s** em iPhone dos últimos 4 anos.
- 100% funcional offline — nenhuma tela depende de rede.
- Acessibilidade: Dynamic Type suportado em todos os textos, VoiceOver com rótulo descritivo em cada card ("CNH, vence em 18 dias" em vez de ler os elementos separadamente), contraste mínimo AA em todas as combinações de cor (checar especialmente laranja `#C87A12` sobre branco).
- Área de toque mínima de 44px em todos os elementos interativos (já respeitado no protótipo).
- Compatibilidade mínima: iOS 26, somente iPhone (destino "iPhone" no App Store Connect — sem suporte a iPad).
- Volume de dados esperado: dezenas de documentos por usuário, nunca centenas — sem necessidade de paginação ou índice especial.
- Idioma: português do Brasil apenas no MVP.
- Tamanho do binário: sem preocupação especial — sem assets pesados (sem ilustração, ao contrário do Estante).

---

## 18. Convenções de código, documentação e estrutura do repositório

- **Banco em português, código em inglês** — mesma convenção do Estante: `documento`, `categoria`, `data_vencimento` no SwiftData; `Document`, `category`, `dueDate` seriam nomes em inglês só se este projeto decidisse diferente, o que **não** é o caso aqui (mantém português também no modelo Swift, espelhando o banco, igual ao Estante).
- **Comentário de cabeçalho em português** em toda função, view model e módulo (`AgendadorDeAvisos`, `GerenciadorDeCompra`), explicando o que faz, o que recebe, o que devolve, e a regra do spec que implementa (com número da seção, ex. "implementa regra 11.3").
- **Estrutura de pastas sugerida:**
  ```
  QuandoVence/
    Models/          (Documento.swift, CategoriaDocumento.swift)
    Views/
      Lista/
      Detalhe/
      Formulario/
      Ajustes/
      Paywall/
    Services/        (AgendadorDeAvisos.swift, GerenciadorDeCompra.swift)
    DesignSystem/     (cores, tipografia — extraídos da seção 16)
  ```
- **Documentação viva:** `DOCUMENTACAO-TECNICA.md` gerado ao final (seção 19), atualizado a cada mudança relevante.
- **Variáveis de ambiente:** nenhuma — não há backend nem chave de API no MVP.

---

## 19. Documento de documentação técnica

Ao final da implementação, o agente de código deve gerar `DOCUMENTACAO-TECNICA.md` na raiz do repositório, em português, com:

1. Modelo de dados explicado em linguagem de negócio (tabela `documento`, enum `categoria_documento` e o que cada valor significa).
2. Relação entre tabelas — não se aplica (tabela única), declarar isso explicitamente em vez de omitir a seção.
3. Lógica que vive fora da UI: os dois módulos da seção 13 (`AgendadorDeAvisos`, `GerenciadorDeCompra`), com o que cada método faz de fato.
4. Mapa tela → dados: reaproveitar a tabela da seção 10, ajustada para o que foi implementado de fato.
5. Lógica das principais funcionalidades por tela — o que é validado, gravado e calculado em cada uma.
6. Divergências em relação a este spec.

---

## 20. Privacidade, segurança e conformidade

- Dado coletado: nome do documento, categoria, data de vencimento, foto opcional — todos fornecidos pela própria pessoa, nada inferido.
- Onde fica: exclusivamente no armazenamento local do aparelho (SwiftData), sem backup em servidor próprio. Backup do iCloud do próprio sistema operacional (se a pessoa tiver ativado) é do usuário, não do app — o app não configura CloudKit no MVP.
- Quem acessa: só a própria pessoa, no próprio aparelho.
- Retenção: até a pessoa excluir o documento ou desinstalar o app.
- Exportar/apagar dados: apagar é feito documento a documento (épico 8.2) ou desinstalando o app (remove tudo). Sem exportação no MVP (ver seção 14) — se isso virar problema de conformidade (ex.: pessoa pedir os dados dela), o caminho é desinstalar/reinstalar não resolve isso; **registrar como pergunta aberta se algum dia vender fora do Brasil e precisar de portabilidade formal** (seção 25).
- Dado sensível: foto de documento de identidade é dado potencialmente sensível (mostra RG, CNH etc.) — por isso a decisão de mantê-la 100% local, nunca em rede, é também uma decisão de privacidade, não só de arquitetura (reforça princípio 0.1).
- Segredos/chaves: nenhum no MVP — não há API key nem credencial de servidor.

---

## 21. Métricas de sucesso

Sem telemetria embutida no app (coerente com o princípio local-first — instrumentar uso individual exigiria rede ou coleta que o produto se propõe a não fazer). Métricas de sucesso vêm só do lado de fora do app:
- Taxa de conversão do paywall (App Store Connect / Analytics de vendas).
- Nota média e reviews na App Store.
- Taxa de retenção agregada e anônima disponível no App Store Connect (não requer código adicional no app).

---

## 22. Estratégia de teste

- Testar manualmente o fluxo de permissão de notificação (concedida e negada) em device real — simulador não reflete o comportamento real de notificação local de forma confiável.
- Testar reagendamento (regra 11.4): editar a data de um documento e confirmar que a notificação antiga não dispara mais.
- Testar o paywall de ponta a ponta: 5 primeiros documentos livres, 6º bloqueado, compra via sandbox libera, restaurar compra numa instalação limpa com o mesmo Apple ID.
- Testar cálculo de urgência em casos de borda: documento que vence hoje, documento que venceu ontem, virada de mês/ano (documento vencendo 31/12 → 01/01).
- Testar exclusão: confirmar que notificações pendentes daquele documento realmente somem do Centro de Notificações.

---

## 23. Riscos e mitigação

| Risco | Impacto | Probabilidade | Mitigação |
|---|---|---|---|
| Notificação local não dispara se o usuário nunca concede permissão | Perda do valor central do produto (o app vira só uma lista manual) | Média | Pedir permissão de forma clara no primeiro cadastro (não no primeiro launch, que é mais fácil de recusar sem contexto); mostrar aviso discreto na lista se estiver desativada |
| Cálculo de "meses"/"anos" (regra 11.2) ficar confuso perto de transições (ex.: 29 dias vs 31 dias) | Rótulo de status impreciso, mas não crítico | Baixa | Já especificado com fórmula exata na regra 11.2; testar casos de borda (seção 22) |
| Reagendamento de notificações em massa (regra 11.4) ser lento com muitos documentos | Trava percebida ao mudar Ajustes | Baixa (volume esperado é dezenas, não centenas — seção 17) | Rodar `reagendarTudo` de forma assíncrona, sem bloquear a UI |
| Ícone de categoria (SVG customizado) não ficar visualmente idêntico ao protótipo | Divergência de marca visual | Baixa | Comparar lado a lado com o protótipo antes de considerar o épico pronto (DoD, seção 26) |

---

## 24. Assunções declaradas

*Assunção não revisada vira verdade no minuto em que o agente de código começa a codar — revise antes de gerar código.*

1. **Limite do paywall: 5 documentos gratuitos**, igual ao Estante. Alternativa considerada: como o protótipo já mostra 7 documentos de exemplo, um limite maior (ex. 7 ou 8) talvez reflita melhor o uso real de alguém com família — mas mantive 5 por consistência com o produto irmão. Se você preferir outro número, é só avisar.
2. **Preço da compra única confirmado: R$ 19,90**, mesmo valor já praticado nos outros apps (Estante/Hora do Remédio).
3. **Documento de terceiro fica só no nome** (texto livre), sem campo estruturado de "pessoa" — decisão de manter uma tabela só (princípio 0.3). Se no futuro isso virar dor real (filtrar "documentos do meu pai", por exemplo), é uma extensão simples de v1.1.
4. **Ícones de categoria recriados como `Path`/`Shape` customizado**, não necessariamente SF Symbols — só usar SF Symbol se o agente encontrar um equivalente visualmente idêntico; caso contrário, recriar os paths exatos do protótipo.
5. **Modo escuro segue o padrão adaptativo do sistema iOS**, sem paleta escura desenhada à mão — o protótipo não especifica modo escuro.
6. **Permissão de notificação é pedida no primeiro cadastro de documento**, não no primeiro launch do app — decisão de UX para dar contexto à pessoa antes de pedir a permissão (aumenta taxa de aceite).
7. **Identificador do produto de IAP confirmado:** `quandovence_desbloqueio_completo`, mesmo padrão de nomenclatura do Estante.
8. **Tela de Paywall sem referência visual do Claude Design** — o protótipo foi gerado antes da decisão de modelo de negócio, então essa tela não está no handoff. Fica livre para o agente de código desenhar, seguindo só a paleta e tipografia da seção 16 (sem exigência de pixel-perfect contra um mockup, diferente das outras 4 telas).
9. **Ícone do app está sendo produzido à parte** por Alexandre, fora deste fluxo — não é responsabilidade do agente de código gerar.

---

## 25. Perguntas abertas

O agente de código deve **perguntar em vez de assumir** ao cruzar com qualquer item abaixo:

1. **Bundle ID e Apple Developer Team** — reaproveitar o prefixo já usado no Estante/Hora do Remédio; precisa do valor exato antes de configurar o projeto Xcode.
3. **Ícone final do app** — assim como no Estante, não faz parte do protótipo do Claude Design; precisa ser produzido à parte antes da submissão (em andamento, ver seção 24).

---

## 26. Definition of Done

- [ ] Todos os épicos da seção 8 implementados e validados contra seus critérios de aceite.
- [ ] Telas conferidas visualmente, pixel a pixel, contra `quando-vence-handoff/quando-vence/project/Quando Vence.dc.html` — exceto o Paywall (8.8), que não tem mockup de referência (seção 24, assunção 8) e só precisa seguir a paleta/tipografia da seção 16.
- [ ] Fluxo de permissão de notificação testado em device real (concedida e negada).
- [ ] Reagendamento de notificações testado ao editar data, ao mudar toggles de Ajustes e ao mudar horário.
- [ ] Trial do paywall testado de ponta a ponta em sandbox, incluindo "Restaurar compra" numa instalação diferente com o mesmo Apple ID.
- [ ] Produto de IAP não-consumível criado e configurado no App Store Connect (identificador `quandovence_desbloqueio_completo`, preço R$ 19,90 — seção 24).
- [ ] Cálculo de urgência e de rótulo de status (regras 11.1 e 11.2) testado nos casos de borda da seção 22.
- [ ] Exclusão testada de ponta a ponta: documento some da lista e as notificações associadas somem do sistema.
- [ ] Modelos de dados (SwiftData) em português conforme seção 7, sem tabela/enum fora do padrão.
- [ ] Todas as funções e módulos comentados conforme seção 18.
- [ ] `DOCUMENTACAO-TECNICA.md` gerado e conferido contra o sistema implementado de fato.
- [ ] Política de privacidade publicada e Privacy Nutrition Label preenchido no App Store Connect (foto de documento de identidade como dado sensível, ver seção 20).
- [ ] Acessibilidade validada: Dynamic Type, VoiceOver nos cards da lista, contraste AA nas cores de status.
- [ ] Seção 24 (Assunções) e seção 25 (Perguntas abertas) revisadas e confirmadas por Alexandre antes da submissão à App Store.

---

## 27. Próximos passos operacionais

1. Revisar as seções 24 e 25 deste documento — em especial preço do IAP, bundle ID/Team e nome do produto.
2. Conferir que a pasta `quando-vence-handoff/` está presente na raiz do repositório antes de começar a implementar as telas — o agente de código deve ler o `Quando Vence.dc.html` e o `README.md` do bundle como referência visual definitiva.
3. Reaproveitar o prefixo de bundle ID e o Apple Developer Team já usados no Estante e no Hora do Remédio.
4. Criar o produto de IAP não-consumível no App Store Connect antes de implementar o épico 8.8, para testar contra um produto real em sandbox desde cedo.
5. Implementar primeiro o modelo de dados (seção 7), depois o módulo de notificações (seção 13, épico 8.7 — é a peça mais arriscada tecnicamente), só depois as telas, na ordem 8.1 → 8.8.
6. Gerar o ícone final do app separadamente (não faz parte do protótipo do Claude Design).
7. Rodar no iOS Simulator para capturar screenshots da App Store assim que os épicos 8.1, 8.3 e 8.8 estiverem estáveis.

---

## 28. Roadmap: próximas releases

**v1.1**
- Sincronização entre aparelhos via iCloud/CloudKit — adiada do MVP por decisão explícita (seção 3), tecnicamente simples de ligar depois já que o modelo de dados (seção 7) não tem nada que impeça isso.
- Campo estruturado de "pessoa" para documentos de terceiros, se a busca/filtro por "documentos do meu pai" virar demanda real (hoje é só texto livre no nome, seção 24).

**v1.2**
- Leitura automática de data de vencimento por foto usando Vision framework local (sem depender de rede, mas escopo novo — precisaria de nova seção 13).
- Categorias customizáveis pelo usuário, além das 5 fixas.

---

## 29. Protocolo de mudanças incrementais

Depois que a v1 estiver pronta e publicada, para qualquer ajuste pequeno:

1. Faça um commit de checkpoint antes de qualquer mudança.
2. Não cole este spec inteiro de novo — cole só o trecho novo ou alterado, ou escreva um spec adicional específico da feature.
3. Escreva a instrução como diff sobre o que já existe, não como um recomeço.
4. Diga nominalmente o que **não** deve mudar.
5. Peça a lista de arquivos que serão criados/alterados **antes** de qualquer código, e aprove antes de deixar o agente prosseguir.
6. Revise o `git diff` contra o que foi aprovado; reverta qualquer arquivo que passou do escopo combinado.
7. Exija a atualização do `DOCUMENTACAO-TECNICA.md` no mesmo commit da mudança.

**Modelo de prompt para colar:**

```
O projeto "Quando Vence?" já existe e está funcionando (não é um projeto novo).
Mudança pontual: [descreva a mudança].
Não altere nada fora de: [liste os arquivos/telas esperados].
Antes de codar, monte o plano e a lista de arquivos que vai criar/alterar e me mostre para aprovação.
Depois de implementar, atualize o DOCUMENTACAO-TECNICA.md refletindo essa mudança.
```

---

## Anexo — Fontes

- Requisito de SDK mínimo iOS 26 para submissões à App Store a partir de 28/abr/2026 — pesquisa reaproveitada da spec do Estante ("O que eu ando lendo"), consultada em 2026-08-01, ainda válida em 2026-08-02.
- Handoff de design do Claude Design, compartilhado por Alexandre nesta conversa: `quando-vence-handoff/quando-vence/project/Quando Vence.dc.html` e `quando-vence-handoff/quando-vence/README.md` — usado como referência definitiva de layout, cor, copy e comportamento de tela.
- Spec de referência "O que eu ando lendo" (Estante) — usada como referência de stack (Swift + SwiftUI + SwiftData + StoreKit 2), modelo de paywall e estrutura de documento.
