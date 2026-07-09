import Cocoa
import Darwin

private let label = "local.reverser"
private let lockPath = "/tmp/\(label).lock"
private let nanosPerMs: UInt64 = 1_000_000
private let gestureEventType: UInt32 = 29

@_silgen_name("reverse_iohid_scroll")
private func reverseIOHIDScroll(_ event: CGEvent)

private func currentExecutablePath() -> String {
    var size: UInt32 = 0
    _NSGetExecutablePath(nil, &size)
    var buf = [CChar](repeating: 0, count: Int(size))
    _NSGetExecutablePath(&buf, &size)
    return URL(fileURLWithPath: String(cString: buf)).resolvingSymlinksInPath().path
}

private func monotonicNanos() -> UInt64 {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    return mach_absolute_time() * UInt64(info.numer) / UInt64(info.denom)
}

private func acquireSingletonLock() -> Bool {
    let fd = open(lockPath, O_CREAT | O_RDWR, 0o644)
    guard fd >= 0 else { return true }
    return flock(fd, LOCK_EX | LOCK_NB) == 0
}

private enum ScrollSource { case mouse, trackpad }

private var lastTouchTime: UInt64 = 0
private var maxTouchingSinceLastScroll = 0
private var lastSource: ScrollSource = .mouse

private let gestureCallback: CGEventTapCallBack = { _, type, eventRef, _ in
    if type.rawValue != gestureEventType { return Unmanaged.passUnretained(eventRef) }
    guard let ns = NSEvent(cgEvent: eventRef) else {
        return Unmanaged.passUnretained(eventRef)
    }
    let touching = ns.touches(matching: .touching, in: nil).count
    if touching >= 2 {
        lastTouchTime = monotonicNanos()
        maxTouchingSinceLastScroll = max(maxTouchingSinceLastScroll, touching)
    }
    return Unmanaged.passUnretained(eventRef)
}

private func classifyScrollSource(_ event: CGEvent) -> ScrollSource {
    let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    if continuous == 0 { return .mouse }

    let elapsed = monotonicNanos() &- lastTouchTime
    let touching = maxTouchingSinceLastScroll
    maxTouchingSinceLastScroll = 0

    if touching >= 2 && elapsed < 222 * nanosPerMs {
        return .trackpad
    }
    let momentumIsNormal = NSEvent(cgEvent: event)?.momentumPhase.isEmpty ?? true
    if momentumIsNormal && elapsed > 333 * nanosPerMs {
        return .mouse
    }
    return lastSource
}

private func reverseScrollWheel(_ event: CGEvent) {
    let d1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    let d2 = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
    let p1 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
    let p2 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
    let f1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
    let f2 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)

    event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -d1)
    event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: -d2)
    event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -f1)
    event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -f2)
    event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -p1)
    event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: -p2)

    reverseIOHIDScroll(event)
}

private var activeTap: CFMachPort?
private var passiveTap: CFMachPort?

private let scrollCallback: CGEventTapCallBack = { _, type, event, _ in
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        if let t = activeTap { CGEvent.tapEnable(tap: t, enable: true) }
        if let t = passiveTap { CGEvent.tapEnable(tap: t, enable: true) }
    case .scrollWheel:
        let source = classifyScrollSource(event)
        lastSource = source
        if source == .mouse { reverseScrollWheel(event) }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}

private func startEventTaps() {
    let scrollMask: CGEventMask =
        (1 << CGEventType.scrollWheel.rawValue)
        | (1 << CGEventType.tapDisabledByTimeout.rawValue)
        | (1 << CGEventType.tapDisabledByUserInput.rawValue)
    let gestureMask: CGEventMask = 1 << UInt64(gestureEventType)

    guard let scrollTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .tailAppendEventTap,
        options: .defaultTap,
        eventsOfInterest: scrollMask,
        callback: scrollCallback,
        userInfo: nil
    ) else { exit(1) }
    activeTap = scrollTap

    passiveTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .tailAppendEventTap,
        options: .listenOnly,
        eventsOfInterest: gestureMask,
        callback: gestureCallback,
        userInfo: nil
    )

    let scrollSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, scrollTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), scrollSrc, .commonModes)
    CGEvent.tapEnable(tap: scrollTap, enable: true)

    if let t = passiveTap {
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
    }

    CFRunLoopRun()
}

guard acquireSingletonLock() else { exit(0) }
startEventTaps()
