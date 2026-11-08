import AppKit

/// Fonts, colours and block decorations for rendered Markdown. Proportional
/// body text, with code in the shared monospace face and green, so code reads
/// as code at a glance.
enum MarkdownStyle {

    static let bodySize: CGFloat = 14
    static let body = NSFont.systemFont(ofSize: bodySize)
    static let code = NSFont.monospacedSystemFont(ofSize: bodySize - 1, weight: .regular)
    static let codeBold = NSFont.monospacedSystemFont(ofSize: bodySize - 1, weight: .semibold)

    /// H1 to H6.
    static func heading(_ level: Int) -> NSFont {
        let sizes: [CGFloat] = [28, 22, 18, 16, 14, 13]
        return NSFont.systemFont(ofSize: sizes[min(max(level, 1), 6) - 1], weight: .bold)
    }

    static let text = NSColor.labelColor
    static let secondary = NSColor.secondaryLabelColor
    static let rule = NSColor.tertiaryLabelColor
    static let tableBorder = NSColor.separatorColor
    static let tableHeaderFill = NSColor.quaternaryLabelColor.withAlphaComponent(0.08)

    static let codeText = dynamic(light: (0.25, 0.45, 0.14), dark: (0.62, 0.86, 0.52))
    static let codeFill = dynamic(light: (0.85, 0.91, 0.80), dark: (0.16, 0.24, 0.15))
    static let frontMatterFill = dynamic(light: (0.93, 0.93, 0.93), dark: (0.18, 0.18, 0.18))

    private static func dynamic(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let c = isDark ? dark : light
            return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
        }
    }

    static func paragraph(indent: CGFloat = 0, hanging: CGFloat = 0, before: CGFloat = 0,
                          after: CGFloat = 10, lineSpacing: CGFloat = 3,
                          alignment: NSTextAlignment = .natural,
                          blocks: [NSTextBlock] = []) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.firstLineHeadIndent = indent
        p.headIndent = indent + hanging
        p.paragraphSpacingBefore = before
        p.paragraphSpacing = after
        p.lineSpacing = lineSpacing
        p.alignment = alignment
        p.textBlocks = blocks
        if hanging > 0 { p.tabStops = [NSTextTab(textAlignment: .left, location: indent + hanging)] }
        return p
    }
}

/// A text block that draws its own background, since NSTextBlock only knows
/// square fills and solid borders: a rounded fill for code, a dotted rule
/// under H1 and H2, a solid bar left of a quote. Margins are left outside
/// the drawing, padding inside it.
final class MarkdownBlock: NSTextBlock {

    enum Decoration { case fill(NSColor), dottedRule, quoteBar }

    let decoration: Decoration

    init(_ decoration: Decoration, padding: CGFloat = 0, marginBelow: CGFloat = 0) {
        self.decoration = decoration
        super.init()
        // Without a width a bare NSTextBlock shrinks to nothing and stacks
        // its text one character per line.
        setValue(100, type: .percentageValueType, for: .width)
        if padding > 0 { setWidth(padding, type: .absoluteValueType, for: .padding) }
        if marginBelow > 0 { setWidth(marginBelow, type: .absoluteValueType, for: .margin, edge: .maxY) }
    }

    required init?(coder: NSCoder) { fatalError("not decoded") }

    override func drawBackground(withFrame frameRect: NSRect, in controlView: NSView?,
                                 characterRange charRange: NSRange, layoutManager: NSLayoutManager) {
        // NSTextView is flipped, so maxY is the bottom edge.
        var r = frameRect
        r.size.height -= width(for: .margin, edge: .maxY)

        switch decoration {
        case .fill(let color):
            color.setFill()
            NSBezierPath(roundedRect: r, xRadius: 8, yRadius: 8).fill()
        case .dottedRule:
            let path = NSBezierPath()
            path.move(to: NSPoint(x: r.minX, y: r.maxY - 1))
            path.line(to: NSPoint(x: r.maxX, y: r.maxY - 1))
            path.lineWidth = 2
            path.setLineDash([2, 3], count: 2, phase: 0)
            MarkdownStyle.rule.setStroke()
            path.stroke()
        case .quoteBar:
            MarkdownStyle.rule.setFill()
            NSBezierPath(roundedRect: NSRect(x: r.minX, y: r.minY, width: 3, height: r.height),
                         xRadius: 1.5, yRadius: 1.5).fill()
        }
    }
}
