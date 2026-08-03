// GerenciadorDeCompra.swift — compra única via StoreKit 2 (spec 13, regra 11.6).
//
// Um único produto de IAP NÃO-CONSUMÍVEL (`quandovence_desbloqueio_completo`) que
// desbloqueia o cadastro ILIMITADO de documentos (spec 8.8). O estado de compra é
// derivado de `Transaction.currentEntitlements` a cada abertura (spec 7/11.6),
// nunca do UserDefaults como fonte de verdade — só cacheado em memória para leitura
// instantânea offline. O preço exibido no Paywall vem de `product.displayPrice`
// (ex.: "R$ 19,90"), não de texto fixo.

import StoreKit

@MainActor
final class GerenciadorDeCompra: ObservableObject {

    /// Produto de desbloqueio carregado do StoreKit (nil enquanto carrega/erro).
    @Published private(set) var produto: Product?

    /// Se a compra já foi feita (entitlement ativo) — libera cadastro ilimitado
    /// (regra 11.6). É o `verificarDesbloqueio()` da spec 13, exposto como estado.
    @Published private(set) var compraDesbloqueada = false

    /// Mensagem transitória para a UI (ex.: "Nenhuma compra encontrada", spec 12).
    @Published var mensagem: String?

    /// Em processamento (compra/restauração em curso) para desabilitar botões.
    @Published private(set) var processando = false

    private var updatesTask: Task<Void, Never>?

    // Atalho de teste: quando ligado (env `QUANDOVENCE_SKIP_STOREKIT`), não toca em
    // StoreKit — evita o prompt de conta Apple no Simulador sem conta sandbox. Não
    // afeta produção nem o teste real via scheme com QuandoVence.storekit (spec 8.8).
    static var skipStoreKit: Bool {
        ProcessInfo.processInfo.environment["QUANDOVENCE_SKIP_STOREKIT"] == "1"
    }

    init() {
        guard !Self.skipStoreKit else { return }
        // Escuta transações que chegam fora do fluxo de compra (aprovação pedida a
        // um responsável, ou compra feita em outro aparelho) — spec 8.8/11.6.
        updatesTask = Task { [weak self] in
            for await verificacao in Transaction.updates {
                await self?.processar(verificacao)
            }
        }
    }

    deinit { updatesTask?.cancel() }

    // Relê só o entitlement local (sem buscar produto na rede) — usado na abertura
    // para reavaliar o desbloqueio a cada launch (spec 8.8, critério 4).
    func atualizarEntitlementsSilencioso() async {
        guard !Self.skipStoreKit else { return }
        await verificarDesbloqueio()
    }

    // Carrega o produto e o estado atual de compra (spec 8.8). Chamado de forma
    // preguiçosa quando o Paywall precisa do preço.
    func carregar() async {
        guard !Self.skipStoreKit else { return }
        await verificarDesbloqueio()
        do {
            let produtos = try await Product.products(for: [AppConstants.iapProductID])
            produto = produtos.first
        } catch {
            produto = nil // sem rede/sandbox: o Paywall mostra estado sem preço
        }
    }

    /// Preço localizado para exibir no Paywall (spec 8.8) — ex.: "R$ 19,90".
    var precoExibicao: String? { produto?.displayPrice }

    // Inicia a compra do desbloqueio (spec 8.8/13). Devolve true se comprou. Em
    // cancelamento/falha, volta sem travar e sem repetir o Paywall (spec 12).
    @discardableResult
    func comprar() async -> Bool {
        guard !Self.skipStoreKit else { return false }
        guard let produto else {
            mensagem = "A compra está indisponível agora. Tente novamente em instantes."
            return false
        }
        processando = true
        defer { processando = false }
        do {
            let resultado = try await produto.purchase()
            switch resultado {
            case .success(let verificacao):
                await processar(verificacao)
                return compraDesbloqueada
            case .userCancelled, .pending:
                return false // cancelou/pendente: sem alerta bloqueante (spec 12)
            @unknown default:
                return false
            }
        } catch {
            mensagem = "Não foi possível concluir a compra agora."
            return false
        }
    }

    // Restaura uma compra anterior do mesmo Apple ID (spec 8.8/13). Chama
    // `AppStore.sync()` e reavalia o entitlement.
    @discardableResult
    func restaurar() async -> Bool {
        guard !Self.skipStoreKit else { return compraDesbloqueada }
        processando = true
        defer { processando = false }
        try? await AppStore.sync()
        await verificarDesbloqueio()
        if !compraDesbloqueada {
            mensagem = "Nenhuma compra encontrada para restaurar." // spec 12
        }
        return compraDesbloqueada
    }

    // Relê os entitlements atuais e atualiza o flag de desbloqueio (spec 13 —
    // `verificarDesbloqueio()`; regra 11.6).
    private func verificarDesbloqueio() async {
        for await verificacao in Transaction.currentEntitlements {
            if case .verified(let transaction) = verificacao,
               transaction.productID == AppConstants.iapProductID,
               transaction.revocationDate == nil {
                compraDesbloqueada = true
                return
            }
        }
        compraDesbloqueada = false
    }

    // Processa uma transação verificada e conclui (finish) para o StoreKit não a
    // reentregar (spec 8.8).
    private func processar(_ verificacao: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verificacao else { return }
        if transaction.productID == AppConstants.iapProductID, transaction.revocationDate == nil {
            compraDesbloqueada = true
        }
        await transaction.finish()
    }
}
