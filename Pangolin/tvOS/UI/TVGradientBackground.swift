import SwiftUI

/// Shared background for tvOS screens: replaces flat black with a vertical charcoal
/// gradient and, once connected, a soft brand-colored light source anchored near the
/// top of the screen rather than a plain flat black backdrop.
struct TVGradientBackground: View {
    var isActive: Bool = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.045, green: 0.045, blue: 0.05)

                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.12, green: 0.12, blue: 0.13), location: 0),
                        .init(color: .clear, location: 0.6),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if isActive {
                    Ellipse()
                        .fill(Color("AccentColor").opacity(0.18))
                        .frame(width: proxy.size.width * 0.7, height: 260)
                        .blur(radius: 140)
                        .offset(y: -proxy.size.height * 0.28)
                }
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: isActive)
    }
}
