// LinhaDocumento.swift — linha de um documento na lista (spec 8.1/16; redesign
// nativo /design opção B, "estilo Lembretes").
//
// Recria a célula de lista agrupada do iOS: um ponto colorido de urgência à
// esquerda (regra 11.1), nome e data em duas linhas, e o rótulo de status à
// direita. Sem ícone de categoria e sem barra lateral — a cor entra só como
// urgência (princípio 0.4). Documentos "em dia" usam o rótulo em cinza; vencidos/
// vence em breve usam a cor de status. VoiceOver lê a linha como uma frase única
// (spec 17).

import SwiftUI

struct LinhaDocumento: View {
    let documento: Documento

    private var status: StatusDocumento {
        CalculadoraDeStatus.status(dataVencimento: documento.data_vencimento)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Ponto de urgência (regra 11.1 / spec 16).
            Circle()
                .fill(status.cor)
                .frame(width: 11, height: 11)

            VStack(alignment: .leading, spacing: 1) {
                Text(documento.nome)
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(Formatters.dataCurta(documento.data_vencimento))
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(status.statusLabel)
                .font(.system(size: 15))
                .foregroundStyle(status.urgencia == .emDia ? Palette.textMuted : status.cor)
                .lineLimit(1)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        // Rótulo único de VoiceOver — "CNH, em 5 anos" (spec 17).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilityLabels.card(nome: documento.nome, statusLabel: status.statusLabel))
        .accessibilityAddTraits(.isButton)
    }
}
