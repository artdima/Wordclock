import SwiftUI

struct ClockScreen: View {
    @ObservedObject var engine: ClockEngine

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                Text(engine.phrase)
                    .font(.system(size: fontSize(for: geometry.size), weight: .thin, design: .default))
                    .minimumScaleFactor(0.3)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, geometry.size.width * 0.07)
                    .offset(x: engine.drift.width * geometry.size.width * 0.015,
                            y: engine.drift.height * geometry.size.height * 0.015)
                    .id(engine.phrase)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.9), value: engine.phrase)
        }
        .ignoresSafeArea()
    }

    private func fontSize(for size: CGSize) -> CGFloat {
        let characters = CGFloat(max(engine.phrase.count, 1))
        let usableArea = size.width * size.height * 0.30
        let estimated = sqrt(usableArea / characters * 1.45)
        let limit = min(size.width, size.height) * 0.32
        return max(min(estimated, limit) * engine.textScale, 8)
    }
}
