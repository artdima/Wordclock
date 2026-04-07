import ScreenSaver
import SwiftUI

@objc(VerbariusScreenSaverView)
final class VerbariusScreenSaverView: ScreenSaverView {
    private let engine: ClockEngine
    private var sheetWindow: NSWindow?

    override init?(frame: NSRect, isPreview: Bool) {
        let bundle = Bundle(for: VerbariusScreenSaverView.self)
        engine = ClockEngine(settings: SettingsStore.load(), bundle: bundle)
        super.init(frame: frame, isPreview: isPreview)

        animationTimeInterval = 0.5
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        let hostingView = NSHostingView(rootView: ClockScreen(engine: engine))
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func animateOneFrame() {
        super.animateOneFrame()
        engine.tick()
    }

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        if let sheetWindow { return sheetWindow }

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
                              styleMask: [.titled],
                              backing: .buffered,
                              defer: true)
        window.title = "Verbarius"

        let content = ConfigureView(
            settings: SettingsStore.load(),
            onCancel: { [weak self] in self?.closeSheet() },
            onSave: { [weak self] settings in
                SettingsStore.save(settings)
                self?.engine.apply(settings)
                self?.closeSheet()
            }
        )

        let hostingView = NSHostingView(rootView: content)
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        sheetWindow = window
        return window
    }

    private func closeSheet() {
        guard let window = sheetWindow else { return }
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.orderOut(nil)
        }
        sheetWindow = nil
    }
}
