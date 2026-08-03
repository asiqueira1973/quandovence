// CartaoDocumento.swift — card de um documento na lista (spec 8.1/16).
//
// Recria o card do protótipo: fundo branco, cantos 12px, sombra dupla sutil, barra
// lateral de 4px na cor de urgência (regra 11.1), ícone da categoria, nome, data
// curta e rótulo de status à direita. Documentos "em dia" usam o rótulo em cinza
// (#8E8E93, peso 500); vencidos/vence em breve usam a cor de status (peso 600),
// exatamente como no protótipo. VoiceOver lê o card como uma frase única (spec 17).

import SwiftUI

struct CartaoDocumento: View {
    let documento: Documento

    private var status: StatusDocumento {
        CalculadoraDeStatus.status(dataVencimento: documento.data_vencimento)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Barra lateral de urgência (regra 11.1 / spec 16).
            Rectangle()
                .fill(status.cor)
                .frame(width: 4)

            HStack(spacing: 12) {
                CategoriaIconView(categoria: documento.categoria, size: 17)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(documento.nome)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                    Text(Formatters.dataCurta(documento.data_vencimento))
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(status.statusLabel)
                    .font(.system(size: 13, weight: status.urgencia == .emDia ? .medium : .semibold))
                    .foregroundStyle(status.urgencia == .emDia ? Palette.textMuted : status.cor)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 96, alignment: .trailing)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .frame(minHeight: 74)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 4)
        .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
        .contentShape(Rectangle())
        // Rótulo único de VoiceOver — "CNH, venceu há 21 dias" (spec 17).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilityLabels.card(nome: documento.nome, statusLabel: status.statusLabel))
        .accessibilityAddTraits(.isButton)
    }
}
