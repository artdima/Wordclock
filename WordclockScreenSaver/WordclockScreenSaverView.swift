import ScreenSaver
import SwiftUI
import os

@objc(WordclockScreenSaverView)
final class WordclockScreenSaverView: ScreenSaverView, NSWindowDelegate {
    private let engine: ClockEngine
    private var sheetWindow: NSWindow?
    private var willStopObserver: NSObjectProtocol?

    override init?(frame: NSRect, isPreview: Bool) {
        engine = ClockEngine(settings: SettingsStore.load(), bundle: WordclockBundle.bundle)
        super.init(frame: frame, isPreview: isPreview)
        WordclockBundle.logger.notice("view \(Int(frame.width))x\(Int(frame.height)) preview=\(isPreview) in \(WordclockBundle.process, privacy: .public)")

        animationTimeInterval = 0.5
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        let hostingView = NSHostingView(rootView: ClockScreen(engine: engine))
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)

        willStopObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.screensaver.willstop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isAnimating else { return }
            WordclockBundle.logger.notice("willstop: stopping animation in \(WordclockBundle.process, privacy: .public)")
            self.stopAnimation()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let willStopObserver {
            DistributedNotificationCenter.default().removeObserver(willStopObserver)
        }
    }

    override func animateOneFrame() {
        super.animateOneFrame()
        engine.tick()
    }

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        WordclockBundle.logger.notice("configureSheet requested in \(WordclockBundle.process, privacy: .public)")

        let content = ConfigureView(
            settings: SettingsStore.load(),
            onCancel: { [weak self] in self?.closeSheet() },
            onSave: { [weak self] settings in
                SettingsStore.save(settings)
                self?.engine.apply(settings)
                self?.closeSheet()
            }
        )

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: true)
        window.title = "Wordclock"
        window.isReleasedWhenClosed = false
        window.delegate = self
        let hostingView = NSHostingView(rootView: content)
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        sheetWindow = window

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self, weak window] in
            guard let self, let window, self.sheetWindow === window, !window.isVisible, window.sheetParent == nil else { return }
            WordclockBundle.logger.notice("host did not present the sheet, showing it standalone in \(WordclockBundle.process, privacy: .public)")
            window.level = .floating
            window.center()
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
        return window
    }

    private func closeSheet() {
        guard let window = sheetWindow else { return }
        if let parent = window.sheetParent {
            parent.endSheet(window)
            sheetWindow = nil
        } else {
            window.close()
        }
    }

    func windowWillClose(_ notification: Notification) {
        sheetWindow = nil
    }
}
