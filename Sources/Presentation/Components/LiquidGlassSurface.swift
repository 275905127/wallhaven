import SwiftUI

extension View {
    @ViewBuilder
    func liquidGlassSurface(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        isInteractive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            if let tint, isInteractive {
                glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else if let tint {
                glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            } else if isInteractive {
                glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    func liquidGlassCapsule(tint: Color? = nil, isInteractive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if let tint, isInteractive {
                glassEffect(.regular.tint(tint).interactive(), in: .capsule)
            } else if let tint {
                glassEffect(.regular.tint(tint), in: .capsule)
            } else if isInteractive {
                glassEffect(.regular.interactive(), in: .capsule)
            } else {
                glassEffect(.regular, in: .capsule)
            }
        } else {
            background(.ultraThinMaterial, in: Capsule())
        }
    }
}

struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

extension Button {
    @MainActor
    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else if prominent {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered)
        }
    }
}
