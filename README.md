# xSAT

A comprehensive SAT practice quiz application built with Flutter, designed to help students prepare for the SAT with an intuitive interface and advanced filtering capabilities.

## 🌐 Live Demo

**Try the app now**: [https://xaffan.github.io/xsat/](https://xaffan.github.io/xsat/)

*The web version is fully functional and includes all features available except the sharing functionality in the native app.*

## Features

### 🎯 Quiz Functionality
- **English & Math Questions**: Practice with real SAT questions for both English and Math sections
- **Interactive Question Display**: Rich HTML content rendering with support for mathematical expressions, tables, and SVG graphics
- **Answer Selection & Submission**: Select answers and get immediate feedback with detailed explanations
- **Question Pool Management**: Efficient question loading and caching for smooth user experience

### 🔍 Advanced Filtering
- **Category-Based Filtering**: Filter questions by skill categories and difficulty levels
- **Persistent Filter State**: Your filter preferences are saved and restored between sessions
- **Real-time Updates**: Question pool updates instantly when filters are applied
- **Smart No-Results Handling**: Clear feedback when no questions match selected filters

### 🎨 User Experience
- **Adaptive Theming**: Light, dark, and OLED dark mode support
- **System Theme Integration**: Automatically adapts to your device's theme preference
- **Material Design 3**: Modern, accessible UI components following Material Design principles
- **Responsive Layout**: Optimized for various screen sizes and orientations

### 📊 Question Management
- **Question Metadata**: View detailed information about each question including skill codes and difficulty
- **Progress Tracking**: Keep track of remaining questions in your filtered set
- **Question Navigation**: Seamless navigation between questions with state preservation

### 📤 Sharing & Export
- **Question Sharing**: Share questions as PDF files
- **Cross-platform Sharing**: Native sharing integration for all supported platforms

### ⚙️ Settings & Customization
- **Content Type Selection**: Choose between English, Math, or combined question sets
- **Theme Preferences**: Customize appearance with multiple theme options
- **Filter Management**: Easy-to-use interface for managing question filters
- **Persistent Settings**: All preferences are automatically saved

## Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile application framework
- **Material Design 3**: Modern UI components and design system
- **Provider**: State management for reactive UI updates

### Packages & Dependencies
- **flutter_html**: Rich HTML content rendering with math and table support
- **google_fonts**: Custom typography using Google Fonts
- **shared_preferences**: Local data persistence
- **provider**: State management solution
- **http**: Network requests and API communication
- **pdf**: PDF generation capabilities
- **share_plus**: Native sharing functionality
- **path_provider**: File system access for caching

### Architecture
- **Provider Pattern**: Clean separation of business logic and UI
- **Service Layer**: Dedicated services for API calls, caching, and sharing
- **Model-View-ViewModel**: Structured architecture for maintainability

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
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── question.dart         # Question data structure
│   ├── question_identifier.dart
│   └── question_metadata.dart
├── providers/                # State management
│   ├── quiz_provider.dart    # Quiz state and logic
│   ├── settings_provider.dart # App settings
│   └── filter_provider.dart  # Question filtering
├── screens/                  # UI screens
│   ├── quiz_screen.dart      # Main quiz interface
│   └── settings_screen.dart  # Settings configuration
├── services/                 # Business logic services
│   ├── api_service.dart      # API communication
│   ├── cache_service.dart    # Local caching
│   └── share_service.dart    # Sharing functionality
├── utils/                    # Utility functions
│   ├── html_processor.dart   # HTML content processing
│   └── html_styles.dart      # HTML styling
└── widgets/                  # Reusable UI components
    ├── answer_option.dart    # Answer selection widget
    ├── filter_chip_bar.dart  # Filter management UI
    ├── no_results_widget.dart # Empty state handling
    └── themed_button.dart    # Custom button component
```

## Usage

### Starting a Quiz
1. Launch the app to see the main quiz screen
2. Use the settings button to configure your preferences
3. Select question types (English, Math, or Both)
4. Apply filters if you want to focus on specific topics
5. Start answering questions!

### Filtering Questions
1. Go to Settings → Quiz Content
2. Select your preferred question type
3. Navigate to the filter section
4. Choose categories you want to practice
5. Questions will automatically update based on your selection

### Customizing Appearance
1. Go to Settings → Appearance
2. Choose your preferred theme (System, Light, Dark)
3. Enable OLED mode for true black backgrounds on compatible displays
4. Changes apply immediately

### Sharing Questions
1. While viewing a question, tap the share icon
2. Use your device's native sharing options

## Testing

The app includes comprehensive testing coverage:

### Test Categories
- **Unit Tests**: Individual component testing
- **Integration Tests**: Feature workflow testing
- **Widget Tests**: UI component testing
- **Provider Tests**: State management testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/providers/quiz_provider_test.dart
flutter test test/integration/filtering_workflow_integration_test.dart
```

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Ensure all tests pass
5. Submit a pull request

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent formatting

### Testing Requirements
- Add tests for new features
- Ensure existing tests continue to pass
- Include integration tests for user workflows

## Performance Optimizations

### Caching Strategy
- **Local Question Cache**: Accessed questions are cached locally to prevent them from reappearing

### Memory Management
- **Efficient State Updates**: Minimal rebuilds using Provider's fine-grained updates
- **Resource Cleanup**: Proper disposal of resources and listeners
- **Lazy Loading**: Questions are loaded on-demand to reduce memory usage

### Network Optimization
- **Error Handling**: Robust error handling with user-friendly messages

## Deployment

### Android Release
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Release
```bash
flutter build ios --release
```

### Windows Deployment
```bash
flutter build windows --release
```

### macOS Deployment
```bash
flutter build macos --release
```

### Linux Deployment
```bash
flutter build linux --release
```

### Web Deployment
```bash
flutter build web --release
```

## License

This project is licensed under the GNU V3 License - see the LICENSE file for details.

## Support

For support, bug reports, or feature requests:
- Open an issue on GitHub
- Contact me: affanquddus1122@gmail.com
