# Documentação técnica — Quando Vence?

**App:** Quando Vence? (lembrete de vencimento de documentos pessoais)
**Plataforma:** iOS 26+, SwiftUI + SwiftData + StoreKit 2 + UserNotifications, **somente iPhone**
**Modelo de negócio:** download grátis, paywall no 6º documento, compra única não-consumível
**Local-first:** 100% offline, sem backend, sem conta, sem rede em nenhum ponto (princípio 0.1)

Este documento descreve o sistema **como ele ficou implementado de fato**, seguindo os 6 itens da seção 19 da spec.

---

## 1. Modelo de dados (linguagem de negócio)

O app tem **uma única tabela**, `documento`, em SwiftData (princípio 0.3 — uma tabela só, sem chave estrangeira, sem relação). Cada registro é um documento pessoal que a pessoa quer acompanhar o vencimento.

### Tabela `documento` (`Sources/Models/Documento.swift`)

| Campo | Tipo | Significado de negócio |
|---|---|---|
| `id` | UUID | Identificador único do documento. |
| `nome` | String | Nome livre, inclusive de terceiros (ex.: "RG do meu pai (Antônio)"). É o único campo obrigatório do cadastro. |
| `categoria` | `categoria_documento` | Uma das 5 categorias fixas (ver enum abaixo). Padrão: `pessoal`. |
| `data_vencimento` | Date | Data em que o documento vence. Base do cálculo de urgência e do agendamento de avisos. Guardada à meia-noite local. |
| `foto` | Data? (`@Attribute(.externalStorage)`) | Foto de referência opcional, guardada como binário fora da linha do store. Nula no caso mais comum. Dado potencialmente sensível — por isso nunca sai do aparelho. |
| `criado_em` | Date | Quando o registro foi criado (auditoria, não exibido na UI). |
| `atualizado_em` | Date | Última edição (auditoria, não exibido na UI). |

Convenção de idioma (spec 18): os nomes de tabela/coluna/enum estão em **português, snake_case**, espelhando o banco; o resto do código (views, serviços, helpers) está em inglês.

**Exclusão:** hard delete. Não há histórico nem soft delete.

**Lógica que NÃO vive no banco:** nenhum dado computado é persistido. Urgência, cor, rótulo de status e agrupamento são derivados em tempo de leitura (ver item 3 e 5).

### Enum `categoria_documento` (`Sources/Models/CategoriaDocumento.swift`)

As 5 categorias fixas, na ordem exata do protótipo:

| Valor (banco) | Rótulo exibido | Uso típico |
|---|---|---|
| `viagem` | Viagem | Passaporte, visto |
| `pessoal` | Pessoal | RG, documentos de terceiros |
| `trabalho` | Trabalho | Certificados profissionais (NR-10, alvará) |
| `saude` | Saúde | Carteirinha de plano |
| `veiculo` | Veículo | CNH, seguro do carro |

### Configurações (não são tabela)

Os ajustes de aviso vivem em `@AppStorage`/`UserDefaults` (spec 7), não em SwiftData — são 5 escalares sem necessidade de histórico:

| Chave | Tipo | Default |
|---|---|---|
| `aviso_90_dias` | Bool | `true` |
| `aviso_30_dias` | Bool | `true` |
| `aviso_7_dias` | Bool | `true` |
| `aviso_1_dia` | Bool | `false` |
| `horario_aviso_index` | Int | `1` (= 09:00) |

O estado de compra (paywall) **não** é persistido como fonte de verdade — é derivado de `Transaction.currentEntitlements` do StoreKit 2 a cada abertura (ver item 3).

---

## 2. Relação entre tabelas

**Não se aplica.** O modelo tem uma tabela única (`documento`), sem chave estrangeira e sem relação (princípio 0.3). Esta seção existe explicitamente para registrar essa decisão, não por omissão.

---

## 3. Lógica fora da UI (módulos internos — seção 13)

### `AgendadorDeAvisos` (`Sources/Services/AgendadorDeAvisos.swift`)

Módulo de notificações locais (`UNUserNotificationCenter`, sem push remoto). Identificadores previsíveis por documento (`"<uuid>-90"`, `"<uuid>-30"`, `"<uuid>-7"`, `"<uuid>-1"`, `"<uuid>-0"`) para permitir cancelar/reagendar sem deixar notificação órfã.

- **`solicitarPermissaoSeNecessario() async -> Bool`** — pede permissão só se ainda não foi concedida nem negada (assunção 6 — no 1º cadastro). Devolve se o app está autorizado. O cadastro nunca é bloqueado por recusa.
- **`statusAutorizacao() async -> UNAuthorizationStatus`** — usado pela Lista para exibir o aviso discreto quando as notificações estão negadas.
- **`agendar(documento:config:)`** — cancela primeiro os pendentes daquele documento e recria: uma notificação por intervalo ativo (90/30/7/1) cuja data resultante ainda seja futura, **mais uma sempre no dia exato do vencimento** (identificador `-0`, independente dos toggles — regra 11.3). Só agenda instantes futuros. Agenda mesmo sem permissão (o SO só não entrega).
- **`cancelar(documentoId:)`** — remove os 5 identificadores previsíveis daquele documento (regra 11.4 / spec 8.5).
- **`reagendarTudo(documentos:config:)`** — cancela e recria para todos os documentos de uma vez; chamado quando os toggles ou o horário de Ajustes mudam (regra 11.4).

### `GerenciadorDeCompra` (`Sources/Services/GerenciadorDeCompra.swift`)

Módulo StoreKit 2, produto único não-consumível `quandovence_desbloqueio_completo`.

- **`verificarDesbloqueio()`** (exposto como estado `compraDesbloqueada`) — lê `Transaction.currentEntitlements`; verdadeiro se o produto está ativo e não revogado (regra 11.6). Reavaliado a cada abertura do app (`atualizarEntitlementsSilencioso()`).
- **`comprar() async`** — inicia o fluxo de compra; conclui (`finish`) a transação verificada e desbloqueia imediatamente.
- **`restaurar() async`** — chama `AppStore.sync()` e reavalia o entitlement (restaura numa instalação nova com o mesmo Apple ID).
- **`carregar() async`** — busca o `Product` para exibir o preço localizado (`product.displayPrice`, ex.: "R$ 19,90").

O preço mostrado no Paywall vem sempre de `displayPrice`, nunca de texto fixo.

---

## 4. Mapa tela → dados

| Tela | Arquivo | Lê | Escreve |
|---|---|---|---|
| Lista (Home) | `Views/Lista/ListaView.swift` | `documento` (via `@Query`), status de notificação | — |
| Detalhe | `Views/Detalhe/DetalheView.swift` | `documento`, `ConfiguracaoAvisos` | `documento` (exclusão) + cancela notificações |
| Formulário (Novo/Editar) | `Views/Formulario/FormularioView.swift` | `documento` (edição) | `documento` (cria/edita) + agenda notificações |
| Ajustes | `Views/Ajustes/AjustesView.swift` | `@AppStorage`, `documento` (só contagem) | `@AppStorage` + reagenda todas as notificações |
| Paywall | `Views/Paywall/PaywallView.swift` | StoreKit (`GerenciadorDeCompra`) | StoreKit (compra/restauração) — não toca em `documento` |

---

## 5. Lógica das principais funcionalidades por tela

### Lista (épico 8.1) — `ListaViewModel`
- Agrupa os documentos em **Vencidos** (`dias < 0`), **Vence em breve** (`0…30`) e **Em dia** (`> 30`), ordenados por proximidade do vencimento (mais urgente primeiro).
- Seção sem itens não é exibida.
- Resumo do topo: "Tudo em dia — nada a fazer agora" quando nada precisa de atenção; senão, "N documento(s) precisam de atenção" com singular/plural.
- Estado vazio quando não há nenhum documento.
- Aviso discreto quando a permissão de notificação está negada (toque abre os Ajustes do iPhone).
- Botão "Adicionar documento" fixo na base aplica o gate do paywall (ver Paywall).

### Detalhe (épico 8.2) — `CalculadoraDeStatus`
- Número grande = dias até/desde o vencimento; legenda correspondente ("dias até o vencimento" / "dias desde o vencimento" / "vence hoje").
- Data por extenso, categoria e resumo dos avisos ativos ("90, 30, 7 dias antes" ou "Desativados").
- Foto exibida só quando `foto != nil`.
- "Excluir documento" pede confirmação nativa (regra 11.5); ao confirmar, cancela as notificações pendentes e volta à lista.

### Formulário (épicos 8.3/8.4) — `FormularioViewModel`
- Validação única e bloqueante: nome não vazio após `trim()` (regra 11.7) — botão Salvar fica cinza (`#C7C7CC`) enquanto inválido.
- Categoria com seleção única, "Pessoal" pré-selecionada.
- **Calendário customizado** (`CalendarioView`, não o DatePicker de roda): navega entre meses, destaca hoje mesmo sem seleção, marca o dia selecionado.
- Data padrão de novo documento: hoje + 30 dias.
- Foto opcional via `PhotosPicker`, comprimida antes de gravar; legenda "Fica salva só neste aparelho" sempre visível.
- Ao salvar: grava, pede permissão no 1º cadastro, (re)agenda os avisos, navega ao Detalhe (novo) ou volta (edição). Editar reusa a mesma tela e **não conta para o limite do paywall**.

### Ajustes (épico 8.6)
- 4 toggles (90/30/7/1) e o horário (ciclo entre 08:00/09:00/12:00/19:00); qualquer mudança dispara `reagendarTudo` de forma assíncrona (regra 11.4).
- Contagem total de documentos e confirmação de privacidade ("Sem conta, sem nuvem, sem sincronização. Nada sai do seu iPhone.").

### Paywall (épico 8.8)
- Aparece **só** ao tentar adicionar o 6º documento sem ter comprado (contagem ≥ 5 e entitlement inativo — regra 11.6). Nunca na abertura nem ao ver/editar/excluir.
- Compra libera o cadastro imediatamente; "Restaurar compra" reavalia o entitlement.
- Sem referência visual no protótipo (assunção 8): segue só a paleta/tipografia da seção 16.

---

## 6. Divergências em relação ao spec

1. **Copy das notificações (adição, não divergência).** O protótipo não define o texto das notificações locais. Foi criado texto próprio, em tom direto (seção 15): "\<nome\> vence hoje." / "\<nome\> vence amanhã." / "\<nome\> vence em N dias." — título "Quando Vence?".
2. **Foto no modelo, não em arquivo.** Seguindo a spec 7 à risca, a foto é `Data?` com `@Attribute(.externalStorage)` no próprio `documento` (diferente do projeto irmão Estante, que guarda o nome do arquivo em disco). Há um helper `FotoUtil` que só redimensiona (≤1200px) e comprime (JPEG ~0.7) antes de gravar.
3. **Aviso do dia do vencimento para documentos já vencidos.** A regra 11.3 diz "sempre" agendar o aviso do dia exato; na prática, ele só é agendado se o instante ainda for futuro (o SO não permite agendar no passado). Para um documento já vencido, nenhum aviso futuro é criado — comportamento inevitável e coerente com "cuja data resultante ainda esteja no futuro".
4. **Preço em ambiente de teste.** O preço exibido vem de `product.displayPrice`. Rodando pelo scheme do Xcode (que referencia `QuandoVence.storekit`), aparece **R$ 19,90**; se o app for lançado fora do Xcode sem o arquivo de configuração StoreKit, o preço pode aparecer diferente (artefato de ambiente, não do código).
5. **Ícone do app e `CFBundleIconName`.** O ícone (`AppIcon-1024.png`, 1024×1024, opaco) foi embutido a partir do `quandovence.png` (que era 512×512 com transparência): composto sobre `#1C1C1E` para remover o alpha e escalado para 1024. Como o Info.plist é manual (`GENERATE_INFOPLIST_FILE: NO`), o Xcode **não injeta** `CFBundleIconName` automaticamente — a chave foi declarada à mão no Info.plist (`CFBundleIconName = AppIcon`). Sem ela, a App Store rejeita o build ("Missing Info.plist value CFBundleIconName" + "Missing required icon file 120x120"). **Não remover essa chave, nem reintroduzir alpha no ícone, em builds futuros.**

---

## Pendências para device real / App Store (fora do que o simulador cobre — seções 22/26)

- Testar o fluxo de permissão de notificação (concedida e negada) em **device real**.
- Testar o paywall de ponta a ponta em **sandbox** do StoreKit, incluindo "Restaurar compra" numa instalação nova com o mesmo Apple ID.
- Criar/confirmar o produto de IAP não-consumível `quandovence_desbloqueio_completo` (R$ 19,90) no App Store Connect.
- Preencher o Privacy Nutrition Label (foto de documento como dado sensível) e publicar a política de privacidade.
- Auditar acessibilidade com VoiceOver ligado em device.

_(Ícone do app: concluído — ver divergência 5.)_
