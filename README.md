# Traverse-Visit Flutter App

A beautiful and modern Flutter travel application with similar UI quality to the original Next.js app, featuring travel planning, social sharing, and destination exploration.

## 🚀 Features

### Core Features
- **Landing Page**: Beautiful gradient design with user type selection and demo access
- **Home Feed**: Instagram-style feed with stories, posts, and travel content
- **Travel Planning**: Destination selection, date pickers, and itinerary generation
- **Social Features**: Like, comment, share, and save travel posts
- **User Authentication**: Demo login system with different user types
- **Responsive Design**: Works on mobile, tablet, and desktop

### UI/UX Highlights
- **Modern Design**: Clean, minimalist interface with beautiful gradients
- **Smooth Animations**: Fluid transitions and micro-interactions
- **Consistent Theming**: Unified color scheme and typography
- **Material Design 3**: Latest Material Design principles
- **Custom Components**: Reusable widgets with consistent styling

## 📱 Screenshots

The app includes the following main screens:
- **Landing Screen**: Welcome page with user type selection
- **Home Screen**: Social feed with stories and travel posts
- **Travel Plan Screen**: Destination planning and booking interface
- **Messages Screen**: Chat interface (placeholder)
- **Wallet Screen**: Payment and currency management (placeholder)
- **Profile Screen**: User profile and settings (placeholder)

## 🛠️ Technology Stack

- **Framework**: Flutter 3.32.7
- **Language**: Dart
- **State Management**: Provider
- **Navigation**: Go Router
- **UI Components**: Custom widgets with Material Design 3
- **Typography**: Google Fonts (Inter)
- **Icons**: Material Icons
- **Storage**: Shared Preferences

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  provider: ^6.1.2
  go_router: ^14.2.7
  intl: ^0.19.0
  uuid: ^4.5.1
  lottie: ^3.1.2
  shared_preferences: ^2.2.3
  http: ^1.2.1
  image_picker: ^1.1.2
  table_calendar: ^3.0.9
  flutter_staggered_grid_view: ^0.7.0
  carousel_slider: ^4.2.1
  photo_view: ^0.14.0
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # Screen widgets
│   ├── landing_screen.dart
│   ├── home_screen.dart
│   ├── travel_plan_screen.dart
│   ├── messages_screen.dart
│   ├── wallet_screen.dart
│   └── profile_screen.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── travel_provider.dart
│   └── ui_provider.dart
├── widgets/                  # Reusable components
│   ├── custom_button.dart
│   ├── custom_card.dart
│   ├── bottom_navigation.dart
│   ├── story_widget.dart
│   └── post_widget.dart
├── utils/                    # Utilities and constants
│   ├── theme.dart
│   └── constants.dart
└── models/                   # Data models (future)
```

## 🎨 Design System

### Colors
- **Primary Blue**: #2563EB
- **Primary Green**: #10B981
- **Primary Purple**: #8B5CF6
- **Primary Orange**: #F59E0B
- **Primary Red**: #EF4444

### Typography
- **Font Family**: Inter (Google Fonts)
- **Weights**: Regular, Medium, SemiBold, Bold
- **Sizes**: 12px to 32px

### Spacing
- **XS**: 4px
- **SM**: 8px
- **MD**: 16px
- **LG**: 24px
- **XL**: 32px
- **XXL**: 48px

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.32.7 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / VS Code
- Chrome browser (for web development)

### Installation

1. **Clone the repository**
   ```bash
   cd traverseApp/traverse_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # For iOS simulator
   flutter run -d ios
   
   # For Android emulator
   flutter run -d android
   ```

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 📱 Demo Access

The app includes demo credentials for different user types:

- **Traveler**: traveler@demo.com / demo123
- **Business Owner**: business@demo.com / demo123
- **Tour Guide**: guide@demo.com / demo123
- **Administrator**: admin@demo.com / demo123

## 🔧 Customization

### Adding New Screens
1. Create a new screen in `lib/screens/`
2. Add the route in `lib/main.dart`
3. Update navigation in `lib/widgets/bottom_navigation.dart`

### Modifying Theme
1. Edit `lib/utils/theme.dart`
2. Update colors, typography, or component styles
3. The changes will apply globally

### Adding New Features
1. Create providers in `lib/providers/`
2. Add widgets in `lib/widgets/`
3. Update constants in `lib/utils/constants.dart`

## 🌟 Key Features Implementation

### State Management
- **Provider Pattern**: Centralized state management
- **AuthProvider**: User authentication and session management
- **TravelProvider**: Travel data and user interactions
- **UIProvider**: UI state and theme management

### Navigation
- **Go Router**: Declarative routing with deep linking support
- **Bottom Navigation**: Persistent navigation bar
- **Route Guards**: Authentication-based route protection

### UI Components
- **CustomButton**: Reusable button with multiple variants
- **CustomCard**: Consistent card styling with shadows
- **StoryWidget**: Instagram-style story circles
- **PostWidget**: Social media post layout

## 📈 Performance

- **Optimized Images**: Asset-based images for fast loading
- **Efficient State Management**: Minimal rebuilds with Provider
- **Lazy Loading**: ListView.builder for large lists
- **Memory Management**: Proper disposal of controllers

## 🔮 Future Enhancements

- [ ] Real API integration
- [ ] Push notifications
- [ ] Offline support
- [ ] Dark mode toggle
- [ ] Multi-language support
- [ ] Advanced search filters
- [ ] Booking system
- [ ] Payment integration
- [ ] Social sharing
- [ ] Photo uploads

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is part of the Traverse-Visit application suite.

## 🙏 Acknowledgments

- Inspired by the original Next.js Traverse-Visit app
- Built with Flutter and Material Design 3
- Uses Google Fonts for typography
- Icons from Material Icons

---

**Note**: This is a demo application with sample data. For production use, integrate with real APIs and implement proper authentication and data persistence.
# traverse_app
