import SwiftUI

extension View {
    func liquidGlassSurface(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        isInteractive: Bool = false
    ) -> some View {
        if let tint, isInteractive {
            glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
        } else if let tint {
            glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
        } else if isInteractive {
            glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }

    func liquidGlassCapsule(tint: Color? = nil, isInteractive: Bool = false) -> some View {
        if let tint, isInteractive {
            glassEffect(.regular.tint(tint).interactive(), in: .capsule)
        } else if let tint {
            glassEffect(.regular.tint(tint), in: .capsule)
        } else if isInteractive {
            glassEffect(.regular.interactive(), in: .capsule)
        } else {
            glassEffect(.regular, in: .capsule)
        }
    }
}

struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content()
        }
    }
}

extension Button {
    @MainActor
    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        if prominent {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.glass)
        }
    }
}
