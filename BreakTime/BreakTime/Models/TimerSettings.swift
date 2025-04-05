import Foundation

struct TimerSettings: Codable {
    var workDurationMinutes: Int
    var breakDurationMinutes: Int
    var startAtLogin: Bool
    
    static let defaultSettings = TimerSettings(
        workDurationMinutes: 25,
        breakDurationMinutes: 5,
        startAtLogin: false
    )
}