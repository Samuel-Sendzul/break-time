import Foundation

enum TimerState {
    case working
    case breaking
    case paused
    case stopped
}

protocol TimerServiceDelegate: AnyObject {
    func timerStateDidChange(state: TimerState)
    func timerDidComplete()
    func timerDidUpdate(secondsRemaining: Int)
}

class TimerService {
    private var timer: Timer?
    private var settings: TimerSettings
    private(set) var secondsRemaining: Int = 0
    private(set) var state: TimerState = .stopped
    
    // Keep track of the last active state to handle pause/resume correctly
    private var lastActiveState: TimerState = .working
    
    weak var delegate: TimerServiceDelegate?
    
    init(settings: TimerSettings = TimerSettings.defaultSettings) {
        self.settings = settings
    }
    
    func startWorkTimer() {
        // Reset the timer completely
        state = .working
        lastActiveState = .working
        secondsRemaining = settings.workDurationMinutes * 60
        startTimer()
        delegate?.timerStateDidChange(state: state)
    }
    
    func startBreakTimer() {
        // Reset the timer completely for break
        state = .breaking
        lastActiveState = .breaking
        secondsRemaining = settings.breakDurationMinutes * 60
        startTimer()
        delegate?.timerStateDidChange(state: state)
    }
    
    func resumeTimer() {
        // Only resume if we're in paused state
        guard state == .paused else { return }
        
        // Restore the last active state (working or breaking)
        state = lastActiveState
        startTimer()
        delegate?.timerStateDidChange(state: state)
    }
    
    func pauseTimer() {
        // Only pause if we're in an active state
        guard state == .working || state == .breaking else { return }
        
        // Remember what state we were in
        lastActiveState = state
        
        // Pause the timer
        timer?.invalidate()
        timer = nil
        state = .paused
        delegate?.timerStateDidChange(state: state)
    }
    
    func stopTimer() {
        // Stop the timer completely
        timer?.invalidate()
        timer = nil
        state = .stopped
        secondsRemaining = 0
        delegate?.timerStateDidChange(state: state)
    }
    
    func postponeBreak(byMinutes minutes: Int) {
        guard state == .breaking else { return }
        
        // End the break and start a new work session with extra time
        pauseTimer()
        startWorkTimerWithExtraTime(minutes: minutes)
    }
    
    /// Starts a work timer with additional time added
    func startWorkTimerWithExtraTime(minutes: Int) {
        state = .working
        lastActiveState = .working
        secondsRemaining = minutes * 60  // Only use the postponed minutes
        startTimer()
        delegate?.timerStateDidChange(state: state)
    }
    
    func updateSettings(_ newSettings: TimerSettings) {
        settings = newSettings
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    private func timerTick() {
        guard secondsRemaining > 0 else {
            timer?.invalidate()
            timer = nil
            delegate?.timerDidComplete()
            return
        }
        
        secondsRemaining -= 1
        delegate?.timerDidUpdate(secondsRemaining: secondsRemaining)
    }
}