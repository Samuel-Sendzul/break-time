# BreakTime

A simple macOS application that helps you manage your work and break periods. The app runs in the menu bar and displays a full-screen overlay during break periods to prevent you from working through your breaks.

## Features

- Configure work and break durations
- Menu bar access for quick control
- Full-screen break overlay that blocks interaction with other apps
- Ability to postpone breaks by 5 or 10 minutes
- Automatic transition between work and break periods

## How to Use

1. **Open the project in Xcode**:
   - Double-click the `BreakTime.xcodeproj` file
   - Or open Xcode and select "Open..." from the File menu, then navigate to the project

2. **Build and Run**:
   - Press ⌘+R or click the "Run" button
   - The app will appear in your menu bar with a timer icon

3. **Using the App**:
   - Click the timer icon in the menu bar to:
     - Start a work timer
     - Access settings
     - Quit the app
   - When a break starts, the screen will fade to black
   - During breaks, you can postpone by 5 or 10 minutes if needed

## Project Structure

The project follows the Model-View-Controller (MVC) pattern:

### Models
- `TimerSettings`: Manages user preferences for work and break durations

### Views
- `BreakViewController`: Controls the UI for the break overlay

### Controllers
- `AppController`: Main controller that coordinates the application flow
- `OverlayWindowController`: Manages the break overlay window
- `SettingsWindowController`: Handles configuration of timer settings

### Services
- `TimerService`: Core timer functionality for managing work/break cycles
- `SettingsService`: Persists user settings

## Preparing for App Store Release

1. Configure your Apple Developer account in Xcode
2. Update the bundle identifier in the project settings
3. Create app icons using the provided template in Assets.xcassets
4. Create app screenshots and marketing materials
5. Archive the app (Product > Archive) and submit through App Store Connect