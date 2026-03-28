# LifeCompanion

LifeCompanion is an iOS app focused on healthy, productive, and balanced daily living. It brings together habits, medications, to-do planning, health tracking, meditation, and cognitive mini-games in a single app.

## Overview

LifeCompanion helps users manage everyday wellness with one unified experience:

- Track and complete daily tasks.
- Build healthy routines with habit tracking.
- Plan medications and monitor adherence.
- Record health-related metrics and progress.
- Practice short meditation sessions.
- Play memory games for mental stimulation.
- Receive reminder notifications for key activities.

## Tech Stack

- SwiftUI
- SwiftData
- UserNotifications
- MVVM architecture
- Swift Package Manager

## Minimum Requirements

- Xcode 15 or later
- iOS 17.0 or later
- macOS with iOS Simulator support

## Project Structure

Main project files live under `LifeCompanion/`:

```text
LifeCompanion/
|- LifeCompanion/
|  |- App/
|  |- Controller/
|  |- Extension/
|  |- Helper/
|  |- Localizable/
|  |- Model/
|  |- Resources/
|  |- ViewModel/
|  `- PrivacyPolicy.html
|- LifeCompanion.xcodeproj/
|- LifeCompanionTests/
|- Package.swift
`- run_tests.sh
```

## Getting Started

1. Clone the repository:

```bash
git clone https://github.com/gayeugur/LifeCompanion.git
cd LifeCompanion
```

2. Open the Xcode project:

```bash
open LifeCompanion/LifeCompanion.xcodeproj
```

3. Select the `LifeCompanion` scheme and run on an iOS 17+ simulator or physical device.

## Running Tests

From Xcode:

- Use `Cmd+U` to run the test suite.

From terminal:

```bash
cd LifeCompanion
./run_tests.sh
```

To run a specific test class or test method:

```bash
./run_tests.sh SimpleTests
```

Note: `run_tests.sh` uses `xcpretty`. If needed, install it with:

```bash
gem install xcpretty
```

## Screenshots

<img src="LifeCompanion/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-03-28%20at%2022.20.48.png" width="300" alt="Home screen" />
<img src="LifeCompanion/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-03-28%20at%2022.20.55.png" width="300" alt="Feature screen 1" />
<img src="LifeCompanion/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-03-28%20at%2022.21.03.png" width="300" alt="Feature screen 2" />
<img src="LifeCompanion/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-03-28%20at%2022.31.54.png" width="300" alt="Feature screen 3" />
<img src="LifeCompanion/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-03-28%20at%2022.32.09.png" width="300" alt="Feature screen 4" />

## Contributing

Contributions are welcome.

- Open an issue for bugs or feature ideas.
- Create a branch for your change.
- Submit a pull request with a clear description.

## License

This project is licensed under the MIT License.


