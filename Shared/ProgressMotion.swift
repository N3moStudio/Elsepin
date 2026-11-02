/// Only visual progress changes here; this policy must never pause the underlying request.
enum ProgressMotion {
    static func isPaused(visible: Bool, active: Bool, reduceMotion: Bool, lowPower: Bool) -> Bool {
        !visible || !active || reduceMotion || lowPower
    }
}
