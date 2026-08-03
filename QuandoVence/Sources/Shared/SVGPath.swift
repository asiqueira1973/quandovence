// SVGPath.swift — conversor de string de path SVG para `Path` do SwiftUI.
//
// Existe para recriar os ícones de categoria EXATAMENTE como no protótipo (objeto
// `CATS`, spec 16, assunção 4), sem depender de SF Symbols aproximados. Suporta os
// comandos usados pelos ícones: M/m, L/l, H/h, V/v, C/c, S/s, A/a, Z/z — incluindo
// a conversão de arco elíptico (A/a) para curvas de Bézier (necessária para o globo
// da Viagem e a cabeça do Pessoal, que são círculos). O `viewBox` de origem é
// 24×24; o path é escalado para o `rect` de destino no momento do desenho.

import SwiftUI
import CoreGraphics

enum SVGPath {

    // Converte uma lista de strings `d` (um subpath cada, como no `CATS`) em um
    // único `Path`, escalado do viewBox 24×24 para `rect`.
    static func path(for commands: [String], in rect: CGRect, viewBox: CGFloat = 24) -> Path {
        var path = Path()
        let sx = rect.width / viewBox
        let sy = rect.height / viewBox
        let transform = CGAffineTransform(translationX: rect.minX, y: rect.minY)
            .scaledBy(x: sx, y: sy)
        for d in commands {
            var parser = Parser(d)
            let cg = parser.parse()
            path.addPath(Path(cg).applying(transform))
        }
        return path
    }

    // Parser de um único atributo `d`. Devolve um CGPath no espaço do viewBox.
    private struct Parser {
        let chars: [Character]
        var i = 0
        var path = CGMutablePath()
        var current = CGPoint.zero      // ponto atual
        var start = CGPoint.zero        // início do subpath (para Z)
        var lastControl: CGPoint?       // último ponto de controle (para S/s)
        var lastCommand: Character = " "

        init(_ s: String) { chars = Array(s) }

        mutating func parse() -> CGPath {
            while i < chars.count {
                skipSeparators()
                guard i < chars.count else { break }
                let c = chars[i]
                if c.isLetter {
                    i += 1
                    execute(c)
                } else {
                    // Número sem letra: repete o comando anterior (regra SVG —
                    // M→L, m→l implícitos).
                    execute(implicitCommand())
                }
            }
            return path
        }

        private func implicitCommand() -> Character {
            switch lastCommand {
            case "M": return "L"
            case "m": return "l"
            default: return lastCommand
            }
        }

        private mutating func execute(_ c: Character) {
            switch c {
            case "M": current = point(); path.move(to: current); start = current
            case "m": current = point(relative: true); path.move(to: current); start = current
            case "L": current = point(); path.addLine(to: current)
            case "l": current = point(relative: true); path.addLine(to: current)
            case "H": current = CGPoint(x: num(), y: current.y); path.addLine(to: current)
            case "h": current = CGPoint(x: current.x + num(), y: current.y); path.addLine(to: current)
            case "V": current = CGPoint(x: current.x, y: num()); path.addLine(to: current)
            case "v": current = CGPoint(x: current.x, y: current.y + num()); path.addLine(to: current)
            case "C": cubic(relative: false)
            case "c": cubic(relative: true)
            case "S": smoothCubic(relative: false)
            case "s": smoothCubic(relative: true)
            case "A": arc(relative: false)
            case "a": arc(relative: true)
            case "Z", "z": path.addLine(to: start); current = start
            default: break
            }
            lastCommand = c
            if !"CcSs".contains(c) { lastControl = nil }
        }

        // --- leitura de curvas -------------------------------------------
        private mutating func cubic(relative: Bool) {
            let c1 = point(relative: relative, from: current)
            let c2 = point(relative: relative, from: current)
            let end = point(relative: relative, from: current)
            path.addCurve(to: end, control1: c1, control2: c2)
            lastControl = c2
            current = end
        }

        private mutating func smoothCubic(relative: Bool) {
            // Reflete o último controle sobre o ponto atual (regra do S/s).
            let c1: CGPoint
            if let lc = lastControl {
                c1 = CGPoint(x: 2 * current.x - lc.x, y: 2 * current.y - lc.y)
            } else {
                c1 = current
            }
            let c2 = point(relative: relative, from: current)
            let end = point(relative: relative, from: current)
            path.addCurve(to: end, control1: c1, control2: c2)
            lastControl = c2
            current = end
        }

        // --- arco elíptico convertido para Bézier ------------------------
        private mutating func arc(relative: Bool) {
            let rx = num(), ry = num(), xRot = num()
            let largeArc = flag(), sweep = flag()
            var end = CGPoint(x: num(), y: num())
            if relative { end = CGPoint(x: current.x + end.x, y: current.y + end.y) }
            addArc(from: current, to: end, rx: rx, ry: ry,
                   xAxisRotationDeg: xRot, largeArc: largeArc, sweep: sweep)
            current = end
        }

        // Endpoint → center parameterization (spec de implementação de SVG arc),
        // aproximando cada segmento de ≤90° por uma curva cúbica.
        private mutating func addArc(from p0: CGPoint, to p1: CGPoint,
                                     rx: CGFloat, ry: CGFloat,
                                     xAxisRotationDeg: CGFloat,
                                     largeArc: Bool, sweep: Bool) {
            if rx == 0 || ry == 0 { path.addLine(to: p1); return }
            var rx = abs(rx), ry = abs(ry)
            let phi = xAxisRotationDeg * .pi / 180
            let cosPhi = cos(phi), sinPhi = sin(phi)

            let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
            let x1p = cosPhi * dx + sinPhi * dy
            let y1p = -sinPhi * dx + cosPhi * dy

            // Corrige raios pequenos demais.
            let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
            if lambda > 1 {
                let s = sqrt(lambda); rx *= s; ry *= s
            }

            let sign: CGFloat = (largeArc != sweep) ? 1 : -1
            let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
            let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
            let co = sign * sqrt(max(0, num / den))
            let cxp = co * (rx * y1p / ry)
            let cyp = co * (-ry * x1p / rx)

            let cx = cosPhi * cxp - sinPhi * cyp + (p0.x + p1.x) / 2
            let cy = sinPhi * cxp + cosPhi * cyp + (p0.y + p1.y) / 2

            func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
                let dot = ux * vx + uy * vy
                let len = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
                var a = acos(min(1, max(-1, dot / len)))
                if ux * vy - uy * vx < 0 { a = -a }
                return a
            }

            let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
            var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry,
                              (-x1p - cxp) / rx, (-y1p - cyp) / ry)
            if !sweep && delta > 0 { delta -= 2 * .pi }
            if sweep && delta < 0 { delta += 2 * .pi }

            // Divide em segmentos de no máximo 90°.
            let segments = Int(ceil(abs(delta) / (.pi / 2)))
            let segDelta = delta / CGFloat(segments)
            var t1 = theta1
            for _ in 0..<segments {
                let t2 = t1 + segDelta
                let alpha = 4.0 / 3.0 * tan(segDelta / 4)

                func pt(_ t: CGFloat) -> CGPoint {
                    let x = cx + rx * cosPhi * cos(t) - ry * sinPhi * sin(t)
                    let y = cy + rx * sinPhi * cos(t) + ry * cosPhi * sin(t)
                    return CGPoint(x: x, y: y)
                }
                func deriv(_ t: CGFloat) -> CGPoint {
                    let x = -rx * cosPhi * sin(t) - ry * sinPhi * cos(t)
                    let y = -rx * sinPhi * sin(t) + ry * cosPhi * cos(t)
                    return CGPoint(x: x, y: y)
                }

                let e1 = pt(t1), e2 = pt(t2)
                let d1 = deriv(t1), d2 = deriv(t2)
                let c1 = CGPoint(x: e1.x + alpha * d1.x, y: e1.y + alpha * d1.y)
                let c2 = CGPoint(x: e2.x - alpha * d2.x, y: e2.y - alpha * d2.y)
                path.addCurve(to: e2, control1: c1, control2: c2)
                t1 = t2
            }
        }

        // --- leitura de tokens -------------------------------------------
        private mutating func point(relative: Bool = false, from base: CGPoint? = nil) -> CGPoint {
            let b = base ?? current
            let x = num(), y = num()
            return relative ? CGPoint(x: b.x + x, y: b.y + y) : CGPoint(x: x, y: y)
        }

        // Lê um número float (com sinal/decimal). Avança o cursor.
        private mutating func num() -> CGFloat {
            skipSeparators()
            var s = ""
            if i < chars.count, chars[i] == "-" || chars[i] == "+" { s.append(chars[i]); i += 1 }
            while i < chars.count {
                let c = chars[i]
                if c.isNumber || c == "." { s.append(c); i += 1 }
                else if c == "-" || c == "+" { break } // início de outro número
                else { break }
            }
            return CGFloat(Double(s) ?? 0)
        }

        // Lê um flag de arco (um único caractere '0' ou '1'), tratando o caso
        // clássico "100" = large=1, sweep=0, x=0 (spec SVG de arc flags).
        private mutating func flag() -> Bool {
            skipSeparators()
            guard i < chars.count else { return false }
            let c = chars[i]; i += 1
            return c == "1"
        }

        private mutating func skipSeparators() {
            while i < chars.count, chars[i] == " " || chars[i] == "," || chars[i] == "\n" || chars[i] == "\t" {
                i += 1
            }
        }
    }
}
