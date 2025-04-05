import XCTest
@testable import BreakTime

class BreakTimeTests: XCTestCase {
    
    // MARK: - TimerSettings Tests
    
    func testDefaultTimerSettings() {
        // Test the default settings have expected values
        let defaultSettings = TimerSettings.defaultSettings
        
        XCTAssertEqual(defaultSettings.workDurationMinutes, 25)
        XCTAssertEqual(defaultSettings.breakDurationMinutes, 5)
        XCTAssertFalse(defaultSettings.startAtLogin)
    }
    
    func testTimerSettingsCodable() {
        // Test encoding and decoding of TimerSettings
        let settings = TimerSettings(workDurationMinutes: 30, breakDurationMinutes: 10, startAtLogin: true)
        
        // Encode to data
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(settings)
            
            // Decode back
            let decoder = JSONDecoder()
            let decodedSettings = try decoder.decode(TimerSettings.self, from: data)
            
            // Verify
            XCTAssertEqual(decodedSettings.workDurationMinutes, 30)
            XCTAssertEqual(decodedSettings.breakDurationMinutes, 10)
            XCTAssertTrue(decodedSettings.startAtLogin)
        } catch {
            XCTFail("Failed to encode/decode TimerSettings: \(error)")
        }
    }
    
    // MARK: - SettingsService Tests
    
    func testSettingsServiceSaveLoad() {
        // Use a unique key for testing to avoid interference with app settings
        let testKey = "com.breaktime.settings.test"
        let settingsService = SettingsService()
        
        // Save custom settings
        let customSettings = TimerSettings(workDurationMinutes: 45, breakDurationMinutes: 15, startAtLogin: true)
        
        // Use UserDefaults directly for testing
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(customSettings) {
            UserDefaults.standard.set(encoded, forKey: testKey)
        }
        
        // Load from same key
        if let savedData = UserDefaults.standard.data(forKey: testKey),
           let settings = try? JSONDecoder().decode(TimerSettings.self, from: savedData) {
            
            XCTAssertEqual(settings.workDurationMinutes, 45)
            XCTAssertEqual(settings.breakDurationMinutes, 15)
            XCTAssertTrue(settings.startAtLogin)
        } else {
            XCTFail("Failed to load settings from UserDefaults")
        }
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: testKey)
    }
    
    // MARK: - TimerService Tests
    
    func testTimerServiceInitialState() {
        let timerService = TimerService()
        
        XCTAssertEqual(timerService.state, .stopped)
        XCTAssertEqual(timerService.secondsRemaining, 0)
    }
    
    func testTimerServiceStartWork() {
        let settings = TimerSettings(workDurationMinutes: 25, breakDurationMinutes: 5, startAtLogin: false)
        let timerService = TimerService(settings: settings)
        
        // Start a work timer
        timerService.startWorkTimer()
        
        // Verify it's in the working state
        XCTAssertEqual(timerService.state, .working)
        XCTAssertEqual(timerService.secondsRemaining, 25 * 60)
    }
    
    func testTimerServicePauseResume() {
        let settings = TimerSettings(workDurationMinutes: 25, breakDurationMinutes: 5, startAtLogin: false)
        let timerService = TimerService(settings: settings)
        
        // Start a work timer
        timerService.startWorkTimer()
        
        // Pause it
        timerService.pauseTimer()
        
        // Verify it's paused
        XCTAssertEqual(timerService.state, .paused)
        
        // Store the time remaining
        let timeRemaining = timerService.secondsRemaining
        
        // Resume
        timerService.resumeTimer()
        
        // Verify it resumed with the same time
        XCTAssertEqual(timerService.state, .working)
        XCTAssertEqual(timerService.secondsRemaining, timeRemaining)
    }
    
    func testTimerServiceStop() {
        let settings = TimerSettings(workDurationMinutes: 25, breakDurationMinutes: 5, startAtLogin: false)
        let timerService = TimerService(settings: settings)
        
        // Start a work timer
        timerService.startWorkTimer()
        
        // Stop it
        timerService.stopTimer()
        
        // Verify it's stopped and reset
        XCTAssertEqual(timerService.state, .stopped)
        XCTAssertEqual(timerService.secondsRemaining, 0)
    }
    
    func testTimerServiceTicking() {
        let expectation = XCTestExpectation(description: "Timer ticks")
        
        let settings = TimerSettings(workDurationMinutes: 25, breakDurationMinutes: 5, startAtLogin: false)
        let timerService = TimerService(settings: settings)
        
        // Create a mock delegate
        class MockDelegate: TimerServiceDelegate {
            var updateCount = 0
            let expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            
            func timerStateDidChange(state: TimerState) {}
            
            func timerDidComplete() {}
            
            func timerDidUpdate(secondsRemaining: Int) {
                updateCount += 1
                if updateCount >= 3 {
                    expectation.fulfill()
                }
            }
        }
        
        let mockDelegate = MockDelegate(expectation: expectation)
        timerService.delegate = mockDelegate
        
        // Start a work timer
        timerService.startWorkTimer()
        
        // Wait for the timer to tick at least 3 times (3 seconds)
        wait(for: [expectation], timeout: 3.5)
        
        // Verify time has decreased
        XCTAssertLessThan(timerService.secondsRemaining, 25 * 60)
        XCTAssertGreaterThanOrEqual(mockDelegate.updateCount, 3)
    }
}
