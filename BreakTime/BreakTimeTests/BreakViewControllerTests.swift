import XCTest
@testable import BreakTime

class BreakViewControllerTests: XCTestCase {
    
    // Test the view controller initialization and setup
    func testBreakViewControllerInit() {
        let breakVC = BreakViewController()
        
        // Force the view to load
        _ = breakVC.view
        
        // Access UI elements via reflection for testing
        let mirror = Mirror(reflecting: breakVC)
        
        // Check that essential UI elements were created
        let timerLabel = mirror.children.first(where: { $0.label == "timerLabel" })?.value as? NSTextField
        let messageLabel = mirror.children.first(where: { $0.label == "messageLabel" })?.value as? NSTextField
        let postpone5Button = mirror.children.first(where: { $0.label == "postpone5Button" })?.value as? NSButton
        let postpone10Button = mirror.children.first(where: { $0.label == "postpone10Button" })?.value as? NSButton
        let skipBreakButton = mirror.children.first(where: { $0.label == "skipBreakButton" })?.value as? NSButton
        
        XCTAssertNotNil(timerLabel, "Timer label should be created")
        XCTAssertNotNil(messageLabel, "Message label should be created")
        XCTAssertNotNil(postpone5Button, "Postpone 5 button should be created")
        XCTAssertNotNil(postpone10Button, "Postpone 10 button should be created")
        XCTAssertNotNil(skipBreakButton, "Skip break button should be created")
    }
    
    // Test the updateTimer method
    func testUpdateTimer() {
        let breakVC = BreakViewController()
        
        // Force view to load
        _ = breakVC.view
        
        // Get the timer label using reflection
        let mirror = Mirror(reflecting: breakVC)
        guard let timerLabel = mirror.children.first(where: { $0.label == "timerLabel" })?.value as? NSTextField else {
            XCTFail("Timer label not found")
            return
        }
        
        // Test updating the timer with a specific value
        breakVC.updateTimer(seconds: 120) // 2 minutes
        
        // Verify the timer label was updated correctly
        XCTAssertEqual(timerLabel.stringValue, "02:00")
        
        // Test another value
        breakVC.updateTimer(seconds: 65) // 1 minute, 5 seconds
        XCTAssertEqual(timerLabel.stringValue, "01:05")
    }
    
    // Test delegate methods
    func testDelegateCalls() {
        // Create a mock delegate to track calls
        class MockDelegate: BreakViewControllerDelegate {
            var postponeCalledWithMinutes: Int?
            var skipBreakCalled = false
            
            func postponeBreakRequested(minutes: Int) {
                postponeCalledWithMinutes = minutes
            }
            
            func skipBreakRequested() {
                skipBreakCalled = true
            }
        }
        
        let mockDelegate = MockDelegate()
        let breakVC = BreakViewController()
        breakVC.delegate = mockDelegate
        
        // Force view to load
        _ = breakVC.view
        
        // Get the buttons using reflection - we verify their existence but use performSelector for testing
        let mirror = Mirror(reflecting: breakVC)
        guard mirror.children.first(where: { $0.label == "postpone5Button" })?.value as? NSButton != nil,
              mirror.children.first(where: { $0.label == "skipBreakButton" })?.value as? NSButton != nil else {
            XCTFail("Buttons not found")
            return
        }
        
        // This calls the objc methods via performSelector to simulate clicks
        // In a real test, you might want to actually trigger the action using the target/action
        breakVC.perform(NSSelectorFromString("postpone5Tapped"))
        
        // Verify delegate was called with correct parameters
        XCTAssertEqual(mockDelegate.postponeCalledWithMinutes, 5)
        
        // Test skip break button
        breakVC.perform(NSSelectorFromString("skipBreakTapped"))
        XCTAssertTrue(mockDelegate.skipBreakCalled)
    }
}