import Foundation

class SettingsService {
    private let settingsKey = "com.breaktime.settings"
    
    func saveSettings(_ settings: TimerSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    func loadSettings() -> TimerSettings {
        if let savedData = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(TimerSettings.self, from: savedData) {
            return settings
        }
        
        // Use default settings
        return TimerSettings.defaultSettings
    }
}
