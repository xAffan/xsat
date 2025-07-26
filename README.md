# xSAT

A comprehensive SAT practice quiz application built with Flutter, designed to help students prepare for the SAT with an intuitive interface, advanced filtering capabilities, and cloud synchronization.

## 🌐 Live Demo

**Try the app now**: [https://xaffan.github.io/xsat/](https://xaffan.github.io/xsat/)

*The web version is fully functional and includes all features except sharing.*

## Features

### 🎯 Quiz Functionality
- **English & Math Questions**: Practice with real SAT questions for both English and Math sections
- **Interactive Question Display**: Rich HTML content rendering with support for mathematical expressions, tables, and SVG graphics
- **Multiple Question Types**: Support for multiple choice questions (MCQ) and student-produced response (SPR) questions
- **Answer Selection & Submission**: Select answers and get immediate feedback with detailed explanations
- **Question Pool Management**: Efficient question loading and caching for smooth user experience
- **Sound Effects**: Audio feedback for correct and incorrect answers (can be toggled in settings)

### 🔍 Advanced Filtering
- **Category-Based Filtering**: Filter questions by skill categories for both English and Math sections
- **Difficulty-Based Filtering**: Filter questions by Easy, Medium, and Hard difficulty levels
- **Persistent Filter State**: Your filter preferences are saved and restored between sessions
- **Real-time Updates**: Question pool updates instantly when filters are applied
- **Smart No-Results Handling**: Clear feedback when no questions match selected filters
- **Filter Statistics**: See question counts for each filter category

### 🎨 User Experience
- **Adaptive Theming**: Light, dark, and OLED dark mode support
- **System Theme Integration**: Automatically adapts to your device's theme preference
- **Material Design 3**: Modern, accessible UI components following Material Design principles
- **Responsive Layout**: Optimized for various screen sizes and orientations
- **Smooth Animations**: Enhanced UI with slide transitions and fade effects
- **Onboarding Experience**: First-time user setup for preferences and sync

### 📊 Question Management & Progress Tracking
- **Question Metadata**: View detailed information about each question including skill codes, difficulty, and category
- **Progress Tracking**: Keep track of remaining questions in your filtered set
- **Question Navigation**: Seamless navigation between questions with state preservation
- **Answered Question Caching**: Prevent answered questions from reappearing (optional)
- **Question Count Display**: Real-time display of available questions and progress

### 🔄 Cloud Synchronization
- **Google Sign-In Integration**: Secure authentication with Google accounts
- **Real-time Sync**: Automatic synchronization of progress across devices
- **Conflict Resolution**: Smart handling of data conflicts between devices
- **Incremental Sync**: Efficient syncing of only changed data
- **Backup & Restore**: Full backup and restore capabilities for user data
- **Offline Support**: Full functionality when offline with sync when connection is restored

### 📈 Mistake Tracking & Analysis
- **Comprehensive Mistake History**: Track all incorrect answers with full question context
- **Detailed Mistake Records**: Store question content, user answers, correct answers, and explanations
- **Mistake Categories**: Organize mistakes by subject, category, and difficulty
- **Search & Filter Mistakes**: Find specific mistakes using search functionality
- **Mistake Restoration**: Restore mistake history from cloud backup
- **Visual Mistake Analysis**: Color-coded display of mistakes with timestamps

### 📤 Sharing & Export
- **Question Sharing**: Share questions as PDF files with proper formatting
- **Text Sharing**: Share question content as formatted text
- **Cross-platform Sharing**: Native sharing integration for all supported platforms
- **High-Quality PDF Generation**: Professional PDF output with proper formatting

### ⚙️ Settings & Customization
- **Content Type Selection**: Choose between English, Math, or combined question sets
- **Theme Preferences**: Customize appearance with multiple theme options
- **Filter Management**: Easy-to-use interface for managing question filters
- **Persistent Settings**: All preferences are automatically saved and synced
- **Cache Management**: Control question caching behavior
- **Sound Settings**: Toggle audio feedback on/off
- **Active Question Exclusion**: Option to exclude questions from official practice tests

## Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile application framework
- **Material Design 3**: Modern UI components and design system
- **Provider**: State management for reactive UI updates

### Backend & Cloud Services
- **Firebase Core**: Firebase platform integration
- **Firebase Auth**: User authentication with Google Sign-In
- **Cloud Firestore**: Real-time database for sync functionality
- **Google Sign-In**: Secure authentication provider

### Data Persistence
- **Hive**: Fast, lightweight local database for offline storage
- **Shared Preferences**: Simple key-value storage for settings
- **Cached Network Image**: Efficient image caching

### UI & Content Rendering
- **flutter_html**: Rich HTML content rendering with math and table support
- **flutter_html_math**: Mathematical expression rendering
- **flutter_html_svg**: SVG graphics support
- **flutter_html_table**: HTML table rendering support
- **google_fonts**: Custom typography using Google Fonts

### Functionality & Services
- **http**: Network requests and API communication
- **pdf**: PDF generation capabilities
- **syncfusion_flutter_pdf**: Advanced PDF generation
- **share_plus**: Native sharing functionality
- **path_provider**: File system access for caching
- **audioplayers**: Sound effects and audio feedback
- **device_info_plus**: Device information for sync

### Development & Testing
- **flutter_lints**: Code quality and style enforcement
- **mockito**: Testing framework for unit tests
- **build_runner**: Code generation for Hive adapters

### Architecture
- **Provider Pattern**: Clean separation of business logic and UI
- **Service Layer**: Dedicated services for API calls, caching, sharing, and sync
- **Model-View-ViewModel**: Structured architecture for maintainability
- **Repository Pattern**: Data access abstraction layer
- **Incremental Sync**: Efficient cloud synchronization strategy

## Installation

### Prerequisites
- Flutter SDK (3.6.0 or higher)
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- iOS development tools (for iOS deployment)

### Setup
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sat_quiz
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK: API level 21 (Android 5.0)
- Target SDK: Latest stable version
- Permissions: Internet access for question loading

#### iOS
- iOS 12.0 or higher
- Xcode 12 or higher for development

#### Windows
- Windows 10 or higher

#### macOS
- macOS 10.14 or higher

#### Linux
- GTK libraries and compatible desktop environment

#### Web
- Modern web browsers with JavaScript enabled
- Responsive design for desktop and mobile browsers

## Project Structure

```
lib/
├── main.dart                           # Application entry point with Firebase setup
├── firebase_options.dart              # Firebase configuration
├── models/                             # Data models
│   ├── question.dart                   # Question data structure
│   ├── question_identifier.dart        # Question identification
│   ├── question_metadata.dart          # Question metadata
│   ├── mistake.dart                    # Mistake tracking model
│   └── sync_data.dart                  # Cloud sync data models
├── providers/                          # State management
│   ├── quiz_provider.dart              # Quiz state and logic
│   ├── settings_provider.dart          # App settings and preferences
│   └── filter_provider.dart            # Question filtering logic
├── screens/                            # UI screens
│   ├── quiz_screen.dart                # Main quiz interface
│   ├── settings_screen.dart            # Settings configuration
│   ├── onboarding_screen.dart          # First-time user setup
│   ├── mistake_history_screen.dart     # Mistake tracking and analysis
│   └── sync_screen.dart                # Cloud sync management
├── services/                           # Business logic services
│   ├── api_service.dart                # API communication
│   ├── cache_service.dart              # Local caching
│   ├── share_service.dart              # PDF sharing functionality
│   ├── text_sharing_service.dart       # Text sharing functionality
│   ├── sound_service.dart              # Audio feedback
│   ├── mistake_service.dart            # Mistake tracking
│   ├── mistake_restoration_service.dart # Mistake restoration from cloud
│   └── firebase_sync_service.dart      # Cloud synchronization
├── utils/                              # Utility functions
│   ├── html_processor.dart             # HTML content processing
│   ├── html_styles.dart                # HTML styling
│   ├── sync_helper.dart                # Sync coordination utilities
│   └── logger.dart                     # Logging utilities
└── widgets/                            # Reusable UI components
    ├── answer_option.dart              # Answer selection widget
    ├── filter_chip_bar.dart            # Filter management UI
    ├── no_results_widget.dart          # Empty state handling
    ├── themed_button.dart              # Custom button component
    ├── question_count_widget.dart      # Progress display
    ├── collapsible_rationale_popup.dart # Answer explanation popup
    └── sync_dialog.dart                # Sync conflict resolution dialog
```

## Usage

### First-Time Setup (Onboarding)
1. Launch the app for the first time
2. Choose your preferred question type (English, Math, or Both)
3. Select your theme preference (System, Light, or Dark)
4. Optionally sign in with Google for cloud sync
5. Complete setup to start practicing

### Starting a Quiz
1. Launch the app to see the main quiz screen
2. Questions are automatically loaded based on your preferences
3. Answer questions by selecting options or typing responses
4. Get immediate feedback with detailed explanations
5. Continue to the next question or review mistakes

### Cloud Synchronization
1. Sign in with Google from the onboarding screen or sync screen
2. Your progress automatically syncs across devices
3. Handle sync conflicts by choosing to keep local data, use cloud data, or merge
4. Access sync status and data overview from the sync screen

### Filtering Questions
1. Go to Settings → Question Filters
2. Select categories for English and/or Math questions
3. Choose difficulty levels (Easy, Medium, Hard)
4. Questions update automatically based on your selection
5. Clear filters anytime to practice all questions

### Tracking Mistakes
1. Incorrect answers are automatically saved to mistake history
2. Access mistake history from the main screen
3. Search and filter mistakes by content, category, or difficulty
4. View detailed mistake information including explanations
5. Clear mistake history when needed

### Customizing Settings
1. **Appearance**: Choose theme (System, Light, Dark) and enable OLED mode
2. **Quiz Content**: Select question types and exclude active questions
3. **Data Management**: Control question caching and clear cached data
4. **Sound**: Toggle audio feedback for correct/incorrect answers

### Sharing Questions
1. While viewing a question, tap the share icon in the app bar
2. Choose between PDF or text sharing
3. Use your device's native sharing options to send to others

## Testing

The app includes comprehensive testing coverage:

### Test Categories
- **Unit Tests**: Individual component and service testing
- **Integration Tests**: Feature workflow testing including sync operations
- **Widget Tests**: UI component testing with provider integration
- **Provider Tests**: State management and data flow testing
- **Service Tests**: API, caching, and sync service testing
- **Model Tests**: Data model validation and serialization testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test categories
flutter test test/unit/
flutter test test/integration/
flutter test test/widgets/

# Run specific test files
flutter test test/providers/quiz_provider_test.dart
flutter test test/services/firebase_sync_service_test.dart
flutter test test/integration/sync_workflow_integration_test.dart

# Run tests with coverage
flutter test --coverage
```

### Test Setup
- **Mockito**: Mocking external dependencies and services
- **Firebase Testing**: Local Firebase emulator for sync testing
- **Provider Testing**: Testing state management with test providers
- **Widget Testing**: Comprehensive UI testing with pump and settle

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup
1. Fork the repository
2. Set up Firebase project for sync features (optional for basic development)
3. Create a feature branch from `main`
4. Make your changes with appropriate tests
5. Ensure all tests pass and code follows style guidelines
6. Submit a pull request with detailed description

### Code Style
- Follow Dart/Flutter conventions and use `flutter_lints`
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Maintain consistent formatting with `dart format`
- Follow Material Design 3 principles for UI components

### Testing Requirements
- Add unit tests for new services and utilities
- Include widget tests for new UI components
- Add integration tests for user workflows
- Test sync functionality with Firebase emulator
- Ensure existing tests continue to pass

## Cloud Sync Architecture

### Sync Strategy
- **Incremental Sync**: Only changed data is synchronized to minimize bandwidth
- **Real-time Updates**: Changes are synced immediately after each action
- **Conflict Resolution**: Smart handling of data conflicts between devices
- **Offline Support**: Full functionality when offline with sync when connection is restored

### Data Organization
- **Subcollection Structure**: Efficient Firestore subcollections for scalability
- **Metadata Tracking**: Sync timestamps and counts for optimization
- **Device Identification**: Track sync sources for conflict resolution

### Sync Components
- **Seen Questions**: Track answered questions across devices
- **Mistake History**: Comprehensive mistake tracking with full context
- **Settings & Filters**: Preference synchronization
- **Backup & Restore**: Full data backup and restoration capabilities

## Performance Optimizations

### Caching Strategy
- **Local Question Cache**: Hive database for fast offline access
- **Answered Question Tracking**: Prevent question repetition
- **Image Caching**: Cached network images for faster loading
- **Metadata Caching**: Local storage of question metadata

### Memory Management
- **Efficient State Updates**: Minimal rebuilds using Provider's fine-grained updates
- **Resource Cleanup**: Proper disposal of resources and listeners
- **Lazy Loading**: Questions are loaded on-demand to reduce memory usage
- **Animation Optimization**: Smooth transitions with proper controller management

### Network Optimization
- **Incremental API Calls**: Only fetch new or changed data
- **Error Handling**: Robust error handling with user-friendly messages
- **Retry Logic**: Automatic retry for failed network requests
- **Batch Operations**: Efficient batch processing for sync operations

## Deployment

### Automated Web Deployment
The app automatically deploys to GitHub Pages when changes are pushed to the main branch:
- **CI/CD Pipeline**: GitHub Actions workflow handles building and deployment
- **Live URL**: [https://xaffan.github.io/xsat/](https://xaffan.github.io/xsat/)
- **Build Process**: Flutter web build with proper base href configuration

### Manual Platform Builds

#### Android Release
```bash
flutter build apk --release
flutter build appbundle --release
```

#### iOS Release
```bash
flutter build ios --release
```

#### Desktop Platforms
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

#### Web Deployment
```bash
flutter build web --release --base-href=/xsat/
```

### Firebase Setup for Sync Features
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication with Google Sign-In provider
3. Enable Cloud Firestore database
4. Configure Firebase for your platforms using FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. Update `lib/firebase_options.dart` with your project configuration

## Privacy & Data

### Data Collection
- **Local Storage**: Question progress and mistakes stored locally using Hive
- **Cloud Sync**: Optional cloud storage of progress data with Google Sign-In
- **No Personal Data**: Only quiz progress and preferences are stored
- **User Control**: Users can clear all data anytime from settings

### Security
- **Firebase Security Rules**: Secure access to user data in Firestore
- **Google Authentication**: Secure sign-in with industry-standard OAuth
- **Data Encryption**: All data encrypted in transit and at rest
- **Privacy First**: No tracking or analytics beyond essential app functionality

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

For support, bug reports, or feature requests:
- **GitHub Issues**: [Open an issue](https://github.com/xaffan/xsat/issues) for bugs or feature requests
- **Email**: affanquddus1122@gmail.com
- **Discussions**: Use GitHub Discussions for questions and community support