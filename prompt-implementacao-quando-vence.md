Implemente o app iOS "Quando Vence?" a partir do documento `spec-quando-vence.md` (nesta mesma pasta), seguindo-o à risca.

Antes de codar:
1. Leia a spec inteira, incluindo as seções 24 (Assunções declaradas) e 25 (Perguntas abertas). Para qualquer item da seção 25, PERGUNTE em vez de assumir.
2. Leia por completo `quando-vence-handoff/quando-vence/README.md` e `quando-vence-handoff/quando-vence/project/Quando Vence.dc.html` — é a referência visual definitiva (cores, espaçamento, layout, copy). Recrie o resultado visual em SwiftUI; não copie a estrutura interna do HTML.
3. Monte o plano de implementação e a lista de tarefas ANTES de escrever qualquer código, e mostre para minha aprovação.

Ordem de implementação:
1. Modelo de dados (seção 7) — SwiftData, convenção de nomenclatura em português.
2. Módulos internos (seção 13): `AgendadorDeAvisos` e `GerenciadorDeCompra`.
3. Telas, na ordem dos épicos: 8.1 (Lista) → 8.2 (Detalhe) → 8.3 (Cadastrar) → 8.4 (Editar) → 8.6 (Ajustes) → 8.7 (Notificações, integrado às telas anteriores) → 8.8 (Paywall).

Convenções obrigatórias (seção 18 da spec):
- Banco/modelo de dados em português, `snake_case`/PascalCase espelhando o português (documento, categoria, data_vencimento).
- Código, funções e nomes de arquivo em inglês, exceto os nomes que espelham o banco.
- Todo função, view model e módulo leva comentário de cabeçalho em português explicando o que faz e qual regra do spec implementa (com número da seção, ex. "implementa regra 11.3").

Valide cada épico contra os critérios de aceite da seção 8 antes de seguir para o próximo.

Siga literalmente as regras de negócio da seção 11 e a copy da seção 15 — não invente rótulo, cor ou texto que não esteja no protótipo ou na spec.

Ao final, gere `DOCUMENTACAO-TECNICA.md` na raiz do projeto, em português, com os 6 itens da seção 19, descrevendo o sistema como ele ficou implementado de fato.
