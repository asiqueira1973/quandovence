// DesignTokens.swift — cores e estilos base da identidade visual (spec seção 16).
//
// Fonte definitiva: o protótipo `quando-vence-handoff/.../Quando Vence.dc.html`,
// que prevalece sobre a prosa da spec. Os hex abaixo foram extraídos direto de lá.
//
// Princípio 0.4 (não-negociável): este produto NÃO tem cor de marca. Toda cor
// visível é STATUS de urgência — vermelho (vencido), laranja (vence em breve),
// cinza-neutro (em dia) — nunca decoração. Os neutros de fundo/texto adaptam para
// modo escuro seguindo o padrão do sistema iOS (spec 16, assunção 5); os três tons
// de status são mantidos legíveis nos dois temas.

import SwiftUI

extension Color {
    // Cria uma Color a partir de um inteiro hex 0xRRGGBB (helper interno, spec 16).
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    // Cria uma Color que adapta entre claro e escuro (spec 16, assunção 5).
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}

/// Paleta central do app (spec 16). Neutros adaptam claro/escuro; as três cores de
/// status são fixas (o vermelho/laranja escurecem de leve no dark para manter
/// contraste AA — spec 17). Nada aqui é cor de marca (princípio 0.4).
enum Palette {

    // Neutros semânticos ----------------------------------------------------
    /// Fundo das telas — `#F5F5F7` no claro (spec 16).
    static let screen = Color(light: 0xF5F5F7, dark: 0x000000)
    /// Fundo agrupado das telas em estilo lista "inset" do iOS (Home/Detalhe
    /// redesenhados — `systemGroupedBackground` #F2F2F7).
    static let groupedBackground = Color(light: 0xF2F2F7, dark: 0x000000)
    /// Separador fino do sistema entre células agrupadas (`separator` #C6C6C8).
    static let separator = Color(light: 0xC6C6C8, dark: 0x38383A)
    /// Fundo externo/frame — `#E9E9EC` (spec 16).
    static let backdrop = Color(light: 0xE9E9EC, dark: 0x0A0A0A)
    /// Cards — `#FFFFFF` no claro (spec 16).
    static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    /// Texto primário — `#1C1C1E` (spec 16).
    static let textPrimary = Color(light: 0x1C1C1E, dark: 0xF2F2F7)
    /// Texto secundário — `#6E6E73` (spec 16).
    static let textSecondary = Color(light: 0x6E6E73, dark: 0xA1A1A6)
    /// Rótulo de seção uppercase — `#A1A1A6` (spec 16).
    static let sectionLabel = Color(light: 0xA1A1A6, dark: 0x8E8E93)
    /// Texto terciário/placeholder — `#8E8E93` (spec 16).
    static let textMuted = Color(light: 0x8E8E93, dark: 0x8E8E93)
    /// Linha divisória fina entre células — `#F0F0F2` (spec 16).
    static let hairline = Color(light: 0xF0F0F2, dark: 0x2C2C2E)
    /// Borda de topo das barras fixas — `#E5E5EA` (spec 16).
    static let barBorder = Color(light: 0xE5E5EA, dark: 0x2C2C2E)
    /// Fundo do quadradinho de foto e do horário em Ajustes — `#F0F0F3` (spec 16).
    static let inset = Color(light: 0xF0F0F3, dark: 0x2C2C2E)
    /// Trilho desligado do toggle — `#E1E1E5` (spec 16).
    static let toggleOff = Color(light: 0xE1E1E5, dark: 0x39393D)

    // Cores de STATUS de urgência (o único uso de cor — princípio 0.4) ------
    /// Vermelho — vencido (spec 11.1 — `#C93A2C`).
    static let statusRed = Color(light: 0xC93A2C, dark: 0xFF6459)
    /// Laranja — vence em breve, ≤30 dias (spec 11.1 — `#C87A12`).
    static let statusOrange = Color(light: 0xC87A12, dark: 0xF5A623)
    /// Cinza-neutro — em dia, >30 dias (spec 11.1 — `#C7C7CC`).
    static let statusNeutral = Color(light: 0xC7C7CC, dark: 0x48484A)

    // Ações -----------------------------------------------------------------
    /// Fundo do botão primário (Salvar/Adicionar) — `#1C1C1E`, texto branco (spec 16).
    static let primaryButton = Color(light: 0x1C1C1E, dark: 0xF2F2F7)
    /// Texto do botão primário (contraste sobre `primaryButton`).
    static let primaryButtonText = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    /// Botão desabilitado (Salvar com nome vazio) — `#C7C7CC` (spec 8.3).
    static let disabledButton = Color(light: 0xC7C7CC, dark: 0x48484A)
    /// Vermelho de AÇÃO destrutiva (excluir) — `#C0362B`, mais escuro que o de
    /// status para diferenciar "ação perigosa" de "sinalização" (spec 15/16).
    static let destructive = Color(light: 0xC0362B, dark: 0xFF6459)
    /// Azul de ação do sistema (links, ‹ voltar, ›) — `#007AFF`, cor padrão do
    /// iOS, NÃO é cor de marca do produto (spec 16).
    static let systemBlue = Color(hex: 0x007AFF)
}

extension View {
    // Aplica o visual de card padrão do protótipo: cantos de 12px e a sombra dupla
    // sutil usada em todo o design (spec 16 — `0 1px 2px` + `0 4px 14px`).
    func documentoCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 4)
            .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
    }

    // Cartão de lista agrupada "inset" do iOS: branco, cantos arredondados e SEM
    // sombra (Home/Detalhe redesenhados no padrão nativo — /design opção B).
    func groupedCard(cornerRadius: CGFloat = 10) -> some View {
        self
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
