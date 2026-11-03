import Foundation
import CoreGraphics

/// The built-in display as a lamp, via DisplayServices (the one brightness path that
/// works on an Apple Silicon built-in panel). `flashUp` dips, then rises to `level`:
/// the "it landed" cue for the ⌘ focus gesture on stage (TIAT, Oct 22).
enum ScreenLamp {
    private typealias Get = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32
    private typealias Set = @convention(c) (UInt32, Float) -> Int32
    private static let lib = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
    private static let getFn = lib.flatMap { dlsym($0, "DisplayServicesGetBrightness") }.map { unsafeBitCast($0, to: Get.self) }
    private static let setFn = lib.flatMap { dlsym($0, "DisplayServicesSetBrightness") }.map { unsafeBitCast($0, to: Set.self) }
    private static let queue = DispatchQueue(label: "menuband.screenlamp", qos: .userInteractive)

    static func read() -> Float? { guard let g = getFn else { return nil }; var v: Float = 0; return g(CGMainDisplayID(), &v) == 0 ? v : nil }
    static func set(_ v: Float) { _ = setFn?(CGMainDisplayID(), max(0, min(1, v))) }

    /// Dip to `dip`, then ease up to `level` over `seconds`. Never below the dip, never above 1.
    static func flashUp(to level: Float = 0.8, dip: Float = 0.45, seconds: Double = 0.35) {
        guard setFn != nil else { return }
        queue.async {
            let steps = 20
            set(dip)
            for i in 1...steps {
                usleep(useconds_t(seconds / Double(steps) * 1_000_000))
                let u = Float(i) / Float(steps)
                set(dip + (level - dip) * (1 - (1 - u) * (1 - u)))   // ease-out
            }
            NSLog("💡 screen lamp: up to %.0f%%", level * 100)
        }
    }
}
