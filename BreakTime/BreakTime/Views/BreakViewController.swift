import Cocoa

protocol BreakViewControllerDelegate: AnyObject {
    func postponeBreakRequested(minutes: Int)
    func skipBreakRequested()
}

class BreakViewController: NSViewController {
    private var timerLabel: NSTextField!
    private var messageLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var postpone5Button: NSButton!
    private var postpone10Button: NSButton!
    private var skipBreakButton: NSButton!
    private var buttonContainer: NSView!
    private var modernFrame: NSView!
    
    weak var delegate: BreakViewControllerDelegate?
    
    override func loadView() {
        self.view = EventBlockingView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make our view accept first responder
        view.window?.makeFirstResponder(view)
    }
    
    private func setupUI() {
        // Create a modern container view
        modernFrame = NSView()
        modernFrame.wantsLayer = true
        
        // Use a semi-transparent background that works in both light and dark mode
        modernFrame.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor
        modernFrame.layer?.cornerRadius = 24.0
        modernFrame.layer?.shadowOpacity = 0.5
        modernFrame.layer?.shadowRadius = 20
        modernFrame.layer?.shadowOffset = CGSize(width: 0, height: -5)
        modernFrame.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modernFrame)
        
        // Message label (main title)
        messageLabel = NSTextField(labelWithString: "BreakTime ☕️")
        messageLabel.font = NSFont.systemFont(ofSize: 48, weight: .bold)
        messageLabel.textColor = NSColor.labelColor
        messageLabel.alignment = .center
        messageLabel.backgroundColor = .clear
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        modernFrame.addSubview(messageLabel)
        
        // Subtitle label
        subtitleLabel = NSTextField(labelWithString: "Rest your eyes and stretch")
        subtitleLabel.font = NSFont.systemFont(ofSize: 18, weight: .regular)
        subtitleLabel.textColor = NSColor.secondaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        modernFrame.addSubview(subtitleLabel)
        
        // Create a container for the timer to ensure fixed width
        let timerContainer = NSView()
        timerContainer.translatesAutoresizingMaskIntoConstraints = false
        modernFrame.addSubview(timerContainer)
        
        // Timer label
        timerLabel = NSTextField(labelWithString: "05:00")
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 96, weight: .bold)
        timerLabel.textColor = NSColor.labelColor
        timerLabel.alignment = .center
        timerLabel.backgroundColor = .clear
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure consistent size by using monospaced digits
        timerLabel.usesSingleLineMode = true
        timerLabel.lineBreakMode = .byClipping
        
        // Add timer to the container
        timerContainer.addSubview(timerLabel)
        
        // Pin timer to container
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerContainer.centerYAnchor),
            timerLabel.widthAnchor.constraint(equalToConstant: 280), // Fixed width that fits all possible times
            timerLabel.heightAnchor.constraint(equalToConstant: 120) // Fixed height for consistency
        ])
        
        // Create the button container view
        buttonContainer = NSView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        modernFrame.addSubview(buttonContainer)
        
        // Setup the modern button style
        let createModernButton = { (title: String, primary: Bool) -> NSButton in
            let button = NSButton(title: title, target: nil, action: nil)
            button.bezelStyle = .rounded
            button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
            button.wantsLayer = true
            
            // Use standard button styling across all buttons
            // This ensures consistency with system UI
            
            button.layer?.cornerRadius = 8.0
            button.translatesAutoresizingMaskIntoConstraints = false
            
            return button
        }
        
        // Postpone 5 button
        postpone5Button = createModernButton("Postpone 5 min", false)
        postpone5Button.target = self
        postpone5Button.action = #selector(postpone5Tapped)
        buttonContainer.addSubview(postpone5Button)
        
        // Postpone 10 button
        postpone10Button = createModernButton("Postpone 10 min", false)
        postpone10Button.target = self
        postpone10Button.action = #selector(postpone10Tapped)
        buttonContainer.addSubview(postpone10Button)
        
        // Skip break button
        skipBreakButton = createModernButton("Skip Break", true)
        skipBreakButton.target = self
        skipBreakButton.action = #selector(skipBreakTapped)
        buttonContainer.addSubview(skipBreakButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Main container positioning
            modernFrame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modernFrame.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            modernFrame.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            modernFrame.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            // Center main content
            messageLabel.centerXAnchor.constraint(equalTo: modernFrame.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: modernFrame.topAnchor, constant: 60),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: modernFrame.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            
            // Position the timer container
            timerContainer.centerXAnchor.constraint(equalTo: modernFrame.centerXAnchor),
            timerContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            timerContainer.widthAnchor.constraint(equalToConstant: 280), // Fixed width
            timerContainer.heightAnchor.constraint(equalToConstant: 120), // Fixed height
            
            // Position button container
            buttonContainer.centerXAnchor.constraint(equalTo: modernFrame.centerXAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: modernFrame.bottomAnchor, constant: -60),
            buttonContainer.widthAnchor.constraint(equalToConstant: 400),
            buttonContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Position buttons within container
            postpone5Button.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 20),
            postpone5Button.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            postpone5Button.widthAnchor.constraint(equalToConstant: 170),
            postpone5Button.heightAnchor.constraint(equalToConstant: 38),
            
            postpone10Button.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -20),
            postpone10Button.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            postpone10Button.widthAnchor.constraint(equalToConstant: 170),
            postpone10Button.heightAnchor.constraint(equalToConstant: 38),
            
            skipBreakButton.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            skipBreakButton.topAnchor.constraint(equalTo: postpone5Button.bottomAnchor, constant: 20),
            skipBreakButton.widthAnchor.constraint(equalToConstant: 170),
            skipBreakButton.heightAnchor.constraint(equalToConstant: 38)
        ])
    }
    
    // We'll remove the cursor animation in the modern UI
    
    // Keep track of the last displayed time to prevent unnecessary updates
    private var lastDisplayedSeconds: Int = -1
    
    func updateTimer(seconds: Int) {
        // Only update the display if the time has actually changed
        if seconds != lastDisplayedSeconds {
            lastDisplayedSeconds = seconds
            
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            let timeString = String(format: "%02d:%02d", minutes, remainingSeconds)
            
            // Just update the timer text directly without animation
            // This ensures consistent size without pulsating
            timerLabel.stringValue = timeString
            
            // Update the subtitle text based on time remaining with a more conversational tone
            if seconds > 60 {
                subtitleLabel.stringValue = "Rest your eyes and stretch"
            } else {
                subtitleLabel.stringValue = "Break ending soon..."
            }
        }
    }
    
    @objc private func postpone5Tapped() {
        animateButtonPress(postpone5Button)
        print("Adding 5 minutes to work session")
        delegate?.postponeBreakRequested(minutes: 5)
    }
    
    @objc private func postpone10Tapped() {
        animateButtonPress(postpone10Button)
        print("Adding 10 minutes to work session")
        delegate?.postponeBreakRequested(minutes: 10)
    }
    
    @objc private func skipBreakTapped() {
        animateButtonPress(skipBreakButton)
        print("Skip break button tapped")
        delegate?.skipBreakRequested()
    }
    
    private func animateButtonPress(_ button: NSButton) {
        guard let buttonLayer = button.layer else { return }
        
        // Save original properties
        let originalBackgroundColor = buttonLayer.backgroundColor
        let originalTransform = buttonLayer.transform
        
        // Create a "press" effect with scale and slight color change
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        
        // Scale down slightly
        let transform = CATransform3DMakeScale(0.95, 0.95, 1.0)
        buttonLayer.transform = transform
        
        // Darken the button slightly
        if let backgroundColor = buttonLayer.backgroundColor {
            let color = NSColor(cgColor: backgroundColor)?.withAlphaComponent(0.7)
            buttonLayer.backgroundColor = color?.cgColor
        }
        
        CATransaction.commit()
        
        // Restore original properties after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.1)
            
            buttonLayer.transform = originalTransform
            buttonLayer.backgroundColor = originalBackgroundColor
            
            CATransaction.commit()
        }
    }
}

// Removed ScanlineView class that was causing Metal library issues

/// Custom view that blocks only mouse events (not keyboard) except for those targeting buttons
class EventBlockingView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Get the result of the normal hit testing
        guard let hitView = super.hitTest(point) else {
            return self
        }
        
        // Allow button clicks and their subviews to pass through
        if hitView is NSButton {
            return hitView
        }
        
        // Check if the hit view is inside a button or any of its subviews
        var parent: NSView? = hitView
        while parent != nil && parent != self {
            if parent is NSButton {
                return hitView
            }
            parent = parent?.superview
        }
        
        // For everything else, return self to capture the event
        return self
    }
    
    override func mouseDown(with event: NSEvent) {
        // Capture and consume the event without beeping
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Capture and consume the event
    }
    
    override func mouseUp(with event: NSEvent) {
        // Capture and consume the event
    }
    
    // Don't override keyboard events - allow typing
}
