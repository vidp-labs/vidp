import AppKit
import CMPV
import VidpEngine

final class PlayerView: NSView {
    private(set) var mpv: OpaquePointer?
    private(set) var renderCtx: OpaquePointer?
    private(set) var playerLayer: PlayerLayer?
    weak var delegate: PlayerDelegate?
    var onPiPToggle: (() -> Void)?
    private(set) var fileLoaded = false
    private(set) var currentPath: String?
    private var currentMedia: MediaInfo?
    private var playbackBackend: PlayerViewBackend!
    private var playbackEngine: PlaybackEngine!

    private var overlayView: NSView!
    private var titleLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        autoresizingMask = [.width, .height]
        let layer = PlayerLayer()
        layer.player = self
        self.layer = layer
        playerLayer = layer

        playbackBackend = PlayerViewBackend(owner: self)
        playbackEngine = PlaybackEngine(backend: playbackBackend) { [weak self] event in
            DispatchQueue.main.async {
                self?.handlePlaybackEvent(event)
            }
        }

        setupOverlay()
        registerForDraggedTypes([.fileURL])

        NotificationCenter.default.addObserver(
            self, selector: #selector(settingsDidChange),
            name: .appSettingsDidChange, object: nil)
    }

    private func setupOverlay() {
        overlayView = NSView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overlayView)

        let iconView = NSImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = NSImage(
            systemSymbolName: "arrow.down.doc", accessibilityDescription: "Drop a video file")?
            .withSymbolConfiguration(
                NSImage.SymbolConfiguration(
                    pointSize: HomepageEmptyStateStyle.iconPointSize, weight: .regular))
        iconView.contentTintColor = .secondaryLabelColor
        iconView.imageScaling = .scaleProportionallyUpOrDown
        overlayView.addSubview(iconView)

        titleLabel = NSTextField(labelWithString: "Drag & drop a video to play")
        titleLabel.font = .systemFont(
            ofSize: HomepageEmptyStateStyle.titleFontSize, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(titleLabel)

        subtitleLabel = NSTextField(labelWithString: "or press \u{2318}O to browse files")
        subtitleLabel.font = .systemFont(ofSize: HomepageEmptyStateStyle.subtitleFontSize)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.topAnchor.constraint(equalTo: overlayView.topAnchor),
            iconView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: HomepageEmptyStateStyle.iconViewSize),
            iconView.heightAnchor.constraint(equalToConstant: HomepageEmptyStateStyle.iconViewSize),
            titleLabel.topAnchor.constraint(
                equalTo: iconView.bottomAnchor, constant: HomepageEmptyStateStyle.verticalSpacing),
            titleLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: HomepageEmptyStateStyle.verticalSpacing),
            subtitleLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor),
        ])
    }

    func showOverlay() {
        overlayView.isHidden = false
    }

    func hideOverlay() {
        overlayView.isHidden = true
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if hasValidFile(sender: sender) {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                self.overlayView.animator().wantsLayer = true
                self.overlayView.animator().layer?.backgroundColor =
                    NSColor.selectedContentBackgroundColor.withAlphaComponent(0.3).cgColor
                self.overlayView.animator().layer?.cornerRadius = 16
            }
            return .copy
        }
        return []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            self.overlayView.animator().layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        hasValidFile(sender: sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        overlayView.layer?.borderWidth = 0
        let opts: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingContentsConformToTypes: ["public.movie"]
        ]
        guard
            let urls = sender.draggingPasteboard.readObjects(
                forClasses: [NSURL.self], options: opts) as? [URL],
            let url = urls.first
        else { return false }
        delegate?.playerView(self, didReceiveFile: url.path)
        return true
    }

    private func hasValidFile(sender: NSDraggingInfo) -> Bool {
        let opts: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingContentsConformToTypes: ["public.movie"]
        ]
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: opts)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            playerLayer?.contentsScale = window.backingScaleFactor
        }
    }

    // Paused mpv emits no update callbacks, so a resize would leave the last
    // IOSurface stretched until play resumes.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        playerLayer?.setNeedsDisplay()
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            super.keyDown(with: event)
            return
        }
        guard fileLoaded else { return }
        switch event.keyCode {
        case 124:  // →
            seek(seconds: event.modifierFlags.contains(.shift) ? 30 : 10)
        case 123:  // ←
            seek(seconds: event.modifierFlags.contains(.shift) ? -30 : -10)
        case 126:  // ↑
            adjustVolume(delta: 1)
        case 125:  // ↓
            adjustVolume(delta: -1)
        default:
            switch event.characters {
            case "f":
                window?.toggleFullScreen(nil)
            case "p":
                onPiPToggle?()
            case "m":
                toggleMute()
            case " ":
                cyclePause()
            case "l":
                nextTrack()
            case "h":
                prevTrack()
            default:
                super.keyDown(with: event)
            }
        }
    }

    func stop() {
        playbackEngine.stop()
    }

    fileprivate func stopBackend() {
        guard let mpv else { return }
        "stop".withCString { cmd in
            var args: [UnsafePointer<CChar>?] = [cmd, nil]
            mpv_command(mpv, &args)
        }
        fileLoaded = false
        currentPath = nil
        currentMedia = nil
        showOverlay()
    }

    func cyclePause() {
        try? playbackEngine.togglePause()
    }

    fileprivate func cyclePauseBackend() {
        guard let mpv else { return }
        "cycle".withCString { cmd in
            "pause".withCString { prop in
                var args: [UnsafePointer<CChar>?] = [cmd, prop, nil]
                mpv_command(mpv, &args)
            }
        }
    }

    fileprivate func pauseBackend() {
        guard let mpv else { return }
        "set".withCString { cmd in
            "pause".withCString { prop in
                "yes".withCString { val in
                    var args: [UnsafePointer<CChar>?] = [cmd, prop, val, nil]
                    mpv_command(mpv, &args)
                }
            }
        }
    }

    func nextTrack() {
        delegate?.playerDidRequestNext()
    }

    func prevTrack() {
        delegate?.playerDidRequestPrev()
    }

    func unpause() {
        try? playbackEngine.play()
    }

    fileprivate func unpauseBackend() {
        guard let mpv else { return }
        "set".withCString { cmd in
            "pause".withCString { prop in
                "no".withCString { val in
                    var args: [UnsafePointer<CChar>?] = [cmd, prop, val, nil]
                    mpv_command(mpv, &args)
                }
            }
        }
    }

    func adjustVolume(delta: Int) {
        if boolProperty("mute") == true {
            try? playbackEngine.setMuted(false)
            delegate?.playerDidToggleMute(false)
        }
        let current = Int(intProperty("volume") ?? 100)
        let new = min(100, max(0, current + delta))
        try? playbackEngine.setVolume(Double(new))
        delegate?.playerDidAdjustVolume(new)
    }

    func toggleMute() {
        let muted = !(boolProperty("mute") ?? false)
        try? playbackEngine.setMuted(muted)
        delegate?.playerDidToggleMute(muted)
    }

    func seek(seconds: Double) {
        try? playbackEngine.seek(by: seconds)
    }

    fileprivate func seekBackend(seconds: Double) {
        guard let mpv else { return }
        String(seconds).withCString { val in
            "seek".withCString { cmd in
                "relative".withCString { flag in
                    var args: [UnsafePointer<CChar>?] = [cmd, val, flag, nil]
                    mpv_command(mpv, &args)
                }
            }
        }
        if fileLoaded {
            delegate?.playerDidSeek(seconds: seconds)
        }
    }

    func cycleSpeed() {
        let current = doubleProperty("speed") ?? 1.0
        let choices = [0.5, 1.0, 1.5, 2.0]
        let next = choices.first { $0 > current } ?? choices.first ?? 1.0
        try? playbackEngine.setSpeed(next)
    }

    func setSpeed(_ speed: Double) {
        try? playbackEngine.setSpeed(speed)
    }

    fileprivate func setSpeedBackend(_ speed: Double) {
        let clamped = min(max(speed, 0.5), 2.0)
        let label = String(format: "%.2f", clamped)
        setProperty("speed", label)
    }

    func seekAbsolute(_ seconds: Double) {
        try? playbackEngine.seek(to: seconds)
    }

    fileprivate func seekAbsoluteBackend(_ seconds: Double) {
        guard let mpv else { return }
        String(seconds).withCString { val in
            "seek".withCString { cmd in
                "absolute".withCString { flag in
                    var args: [UnsafePointer<CChar>?] = [cmd, val, flag, nil]
                    mpv_command(mpv, &args)
                }
            }
        }
    }

    func boolProperty(_ name: String) -> Bool? {
        guard let mpv else { return nil }
        var value: Int32 = 0
        return mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &value) >= 0 ? value != 0 : nil
    }

    /// Returns an error message on failure.
    func setup() -> String? {
        guard let layer = playerLayer, let glctx = layer.cglCtx else { return "no OpenGL context" }
        CGLSetCurrentContext(glctx)
        defer { CGLSetCurrentContext(nil) }

        guard let mpv = mpv_create() else { return "mpv_create() failed" }

        // Must be set before mpv_initialize().
        mpv_set_option_string(mpv, "vo", "libmpv")
        mpv_set_option_string(mpv, "hwdec", "videotoolbox")
        mpv_set_option_string(mpv, "keep-open", "always")
        mpv_set_option_string(mpv, "save-position-on-quit", "yes")
        AppSettings.applyOptions(to: mpv)

        guard mpv_initialize(mpv) >= 0 else {
            mpv_destroy(mpv)
            return "mpv_initialize() failed"
        }
        self.mpv = mpv

        var initParams = mpv_opengl_init_params(
            get_proc_address: glGetProcAddress,
            get_proc_address_ctx: nil)

        MPV_RENDER_API_TYPE_OPENGL.withCString { apiType in
            withUnsafeMutableBytes(of: &initParams) { initBuf in
                guard let initPtr = initBuf.baseAddress else { return }
                var params: [mpv_render_param] = [
                    mpv_render_param(
                        type: MPV_RENDER_PARAM_API_TYPE,
                        data: UnsafeMutableRawPointer(mutating: apiType)),
                    mpv_render_param(type: MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, data: initPtr),
                    mpv_render_param(),
                ]
                var ctx: OpaquePointer?
                guard mpv_render_context_create(&ctx, mpv, &params) >= 0, let ctx else {
                    mpv_destroy(mpv)
                    self.mpv = nil
                    return
                }
                self.renderCtx = ctx
                layer.renderCtx = ctx
                mpv_render_context_set_update_callback(
                    ctx, mpvUpdateCallback, Unmanaged.passUnretained(self).toOpaque())
            }
        }
        guard renderCtx != nil else {
            mpv_destroy(mpv)
            self.mpv = nil
            return "mpv_render_context_create() failed"
        }

        mpv_observe_property(mpv, 0, "width", MPV_FORMAT_INT64)
        mpv_observe_property(mpv, 0, "height", MPV_FORMAT_INT64)
        mpv_observe_property(mpv, 0, "pause", MPV_FORMAT_FLAG)
        // Natural EOF never sends END_FILE under keep-open=always;
        // eof-reached flipping true is the real end-of-file signal.
        mpv_observe_property(mpv, 0, "eof-reached", MPV_FORMAT_FLAG)

        listenForEvents()
        return nil
    }

    func load(path: String) {
        try? playbackEngine.load(URL(fileURLWithPath: path))
    }

    fileprivate func loadBackend(path: String) {
        guard let mpv else { return }
        fileLoaded = true
        currentPath = path
        currentMedia = MediaInfo(url: URL(fileURLWithPath: path))
        "loadfile".withCString { cmd in
            path.withCString { p in
                var args: [UnsafePointer<CChar>?] = [cmd, p, nil]
                if mpv_command(mpv, &args) < 0 {
                    DispatchQueue.main.async {
                        self.delegate?.playerDidEncounterError("Could not load \(path)")
                    }
                }
            }
        }
    }

    func doubleProperty(_ name: String) -> Double? {
        guard let mpv else { return nil }
        var value: Double = 0
        return mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &value) >= 0 ? value : nil
    }

    private func intProperty(_ name: String) -> Int64? {
        guard let mpv else { return nil }
        var value: Int64 = 0
        return mpv_get_property(mpv, name, MPV_FORMAT_INT64, &value) >= 0 ? value : nil
    }

    func trackList() -> [[String: Any]] {
        guard let mpv else { return [] }
        var node = mpv_node()
        guard mpv_get_property(mpv, "track-list", MPV_FORMAT_NODE, &node) >= 0 else { return [] }
        defer { mpv_free_node_contents(&node) }
        guard let list = node.u.list else { return [] }
        var results: [[String: Any]] = []
        for i in 0..<Int(list.pointee.num) {
            let entry = list.pointee.values[i]
            guard entry.format == MPV_FORMAT_NODE_MAP else { continue }
            guard let map = entry.u.list else { continue }
            var dict: [String: Any] = [:]
            for j in 0..<Int(map.pointee.num) {
                guard let keyPtr = map.pointee.keys?[j] else { continue }
                let val = map.pointee.values![j]
                let key = String(cString: keyPtr)
                switch val.format {
                case MPV_FORMAT_INT64:
                    dict[key] = val.u.int64
                case MPV_FORMAT_FLAG:
                    dict[key] = val.u.flag != 0 ? Int64(1) : Int64(0)
                case MPV_FORMAT_STRING:
                    if let s = val.u.string { dict[key] = String(cString: s) }
                default:
                    break
                }
            }
            results.append(dict)
        }
        return results
    }

    func setProperty(_ name: String, _ value: String) {
        guard let mpv else { return }
        _ = name.withCString { n in
            value.withCString { v in
                mpv_set_property_string(mpv, n, v)
            }
        }
    }

    func setTrack(_ property: String, id: Int) {
        let kind: TrackKind
        switch property {
        case "aid": kind = .audio
        case "vid": kind = .video
        default: kind = .subtitle
        }
        try? playbackEngine.selectTrack(TrackSelection(kind: kind, id: id == 0 ? nil : id))
    }

    fileprivate func setTrackBackend(_ property: String, id: Int) {
        guard let mpv else { return }
        let value = id == 0 ? "no" : "\(id)"
        "set".withCString { cmd in
            property.withCString { prop in
                value.withCString { val in
                    var args: [UnsafePointer<CChar>?] = [cmd, prop, val, nil]
                    mpv_command(mpv, &args)
                }
            }
        }
    }

    private func restoreSavedTracks() {
        guard let path = currentPath else { return }
        let defaults = UserDefaults.standard
        // Saved aid/sid from another file may not exist here; a nonexistent id
        // leaves mpv with no track selected (silent / missing subs). Only restore
        // ids that exist — id 0 ("no") always does.
        let tracks = trackList()
        func exists(type: String, id: Int) -> Bool {
            if id == 0 { return type == "sub" }
            return tracks.contains {
                ($0["type"] as? String) == type && ($0["id"] as? Int64) == Int64(id)
            }
        }
        if let sub = (defaults.object(forKey: "sid:\(path)") as? Int)
            ?? (defaults.object(forKey: "sid:last") as? Int),
            exists(type: "sub", id: sub)
        {
            setTrack("sid", id: sub)
        }
        if let audio = (defaults.object(forKey: "aid:\(path)") as? Int)
            ?? (defaults.object(forKey: "aid:last") as? Int),
            exists(type: "audio", id: audio)
        {
            setTrack("aid", id: audio)
        }
    }

    private func listenForEvents() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while let mpv = self?.mpv {
                let event = mpv_wait_event(mpv, -1).pointee
                switch event.event_id {
                case MPV_EVENT_PROPERTY_CHANGE:
                    if let prop = event.data?.assumingMemoryBound(to: mpv_event_property.self) {
                        let name = String(cString: prop.pointee.name)
                        if name == "width" || name == "height" {
                            let w = self?.intProperty("width") ?? 0
                            let h = self?.intProperty("height") ?? 0
                            DispatchQueue.main.async {
                                self?.playbackBackend.eventHandler?(
                                    .videoSizeChanged(
                                        VideoSize(width: Int(w), height: Int(h))))
                            }
                        } else if name == "pause" {
                            let paused = self?.boolProperty("pause") ?? false
                            DispatchQueue.main.async {
                                self?.playbackBackend.eventHandler?(
                                    .stateChanged(
                                        self?.playbackState(isPaused: paused)
                                            ?? PlaybackState(isPaused: paused)))
                            }
                        } else if name == "eof-reached" {
                            if self?.boolProperty("eof-reached") == true {
                                DispatchQueue.main.async {
                                    self?.playbackBackend.eventHandler?(.ended)
                                }
                            }
                        }
                    }
                case MPV_EVENT_END_FILE:
                    if let endFile = event.data?.assumingMemoryBound(to: mpv_event_end_file.self) {
                        // Only errors surface here; natural EOF arrives via eof-reached,
                        // and END_FILE(stop) just means a new file replaced this one.
                        if endFile.pointee.reason == MPV_END_FILE_REASON_ERROR {
                            let msg = String(cString: mpv_error_string(endFile.pointee.error))
                            DispatchQueue.main.async {
                                self?.fileLoaded = false
                                self?.playbackBackend.eventHandler?(.failed(.failed(msg)))
                            }
                        }
                    }
                case MPV_EVENT_FILE_LOADED:
                    DispatchQueue.main.async {
                        if let media = self?.currentMedia {
                            self?.playbackBackend.eventHandler?(.mediaLoaded(media))
                        }
                    }
                case MPV_EVENT_SHUTDOWN:
                    DispatchQueue.main.async { NSApp.terminate(nil) }
                    return
                default:
                    break
                }
            }
        }
    }

    @objc private func settingsDidChange() {
        guard let mpv else { return }
        AppSettings.applySubtitle(to: mpv)
    }

    private func playbackState(isPaused: Bool) -> PlaybackState {
        PlaybackState(
            media: currentMedia,
            isPaused: isPaused,
            position: doubleProperty("time-pos"),
            duration: doubleProperty("duration"),
            volume: doubleProperty("volume"),
            isMuted: boolProperty("mute") ?? false,
            speed: doubleProperty("speed") ?? 1,
            videoSize: {
                guard let width = intProperty("width"), let height = intProperty("height") else {
                    return nil
                }
                return VideoSize(width: Int(width), height: Int(height))
            }())
    }

    private func handlePlaybackEvent(_ event: PlaybackEvent) {
        switch event {
        case .mediaLoaded:
            delegate?.playerDidFileLoad()
            restoreSavedTracks()
        case .stateChanged(let state):
            // Use mpv's live pause state.
            let paused = boolProperty("pause") ?? state.isPaused
            delegate?.playerDidUpdatePlaybackState(isPaused: paused)
        case .videoSizeChanged(let size):
            delegate?.playerDidUpdateVideoSize(width: Int64(size.width), height: Int64(size.height))
        case .ended:
            delegate?.playerDidEndFile()
        case .failed(let error):
            if case .failed(let message) = error {
                delegate?.playerDidEncounterError(message)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let renderCtx { mpv_render_context_free(renderCtx) }
        if let mpv { mpv_destroy(mpv) }
    }
}

private final class PlayerViewBackend: PlaybackBackend {
    weak var owner: PlayerView?
    var eventHandler: (@Sendable (PlaybackEvent) -> Void)?

    init(owner: PlayerView) {
        self.owner = owner
    }

    func load(_ media: MediaInfo) throws {
        owner?.loadBackend(path: media.url.path)
    }

    func stop() { owner?.stopBackend() }
    func play() throws { owner?.unpauseBackend() }
    func pause() throws { owner?.pauseBackend() }
    func togglePause() throws { owner?.cyclePauseBackend() }
    func seek(by seconds: Double) throws { owner?.seekBackend(seconds: seconds) }
    func seek(to seconds: Double) throws { owner?.seekAbsoluteBackend(seconds) }
    func setVolume(_ value: Double) throws { owner?.setProperty("volume", String(value)) }
    func setMuted(_ muted: Bool) throws { owner?.setProperty("mute", muted ? "yes" : "no") }
    func setSpeed(_ value: Double) throws { owner?.setSpeedBackend(value) }
    func selectTrack(_ track: TrackSelection) throws {
        let property: String
        switch track.kind {
        case .audio: property = "aid"
        case .video: property = "vid"
        case .subtitle: property = "sid"
        }
        owner?.setTrackBackend(property, id: track.id ?? 0)
    }
    func shutdown() {}
}
