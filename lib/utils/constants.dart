class AppConstants {
  // App Info
  static const String appName = 'Traverse';
  static const String appDescription = 'Plan, Share, and Explore the World Together';
  static const String appVersion = '1.0.0';
  
  // API Endpoints (for future use)
  static const String baseUrl = 'https://api.traverse-visit.com';
  static const String apiVersion = '/v1';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Spacing
  static const double xsSpacing = 4.0;
  static const double smSpacing = 8.0;
  static const double mdSpacing = 16.0;
  static const double lgSpacing = 24.0;
  static const double xlSpacing = 32.0;
  static const double xxlSpacing = 48.0;
  
  // Border Radius
  static const double smRadius = 4.0;
  static const double mdRadius = 8.0;
  static const double lgRadius = 12.0;
  static const double xlRadius = 16.0;
  static const double xxlRadius = 24.0;
  
  // Sample Data
  static const List<Map<String, dynamic>> sampleDestinations = [
    {
      'id': 1,
      'name': 'Treehouse Lodge, Costa Rica',
      'image': 'assets/images/treehouse-waterfall.png',
      'rating': 4.9,
      'budget': '\$2,400',
      'description': 'Unique eco-luxury treehouse with waterfall views',
      'activities': ['Canopy tours', 'Wildlife watching', 'Waterfall hiking', 'Spa treatments'],
      'location': 'Costa Rica',
    },
    {
      'id': 2,
      'name': 'Kalahari Safari, Botswana',
      'image': 'assets/images/meerkat-safari.png',
      'rating': 4.8,
      'budget': '\$1,800',
      'description': 'Desert safari with incredible wildlife encounters',
      'activities': ['Game drives', 'Meerkat encounters', 'Desert walks', 'Star gazing'],
      'location': 'Botswana',
    },
    {
      'id': 3,
      'name': 'Marrakech Riad, Morocco',
      'image': 'assets/images/moroccan-luxury.png',
      'rating': 4.7,
      'budget': '\$900',
      'description': 'Traditional luxury palace with authentic Moroccan architecture',
      'activities': ['Medina tours', 'Cooking classes', 'Hammam spa', 'Souk shopping'],
      'location': 'Morocco',
    },
    {
      'id': 4,
      'name': 'Great Wall, China',
      'image': 'assets/images/ancient-walls.png',
      'rating': 4.6,
      'budget': '\$1,200',
      'description': 'Ancient wonder with breathtaking views and rich history',
      'activities': ['Hiking', 'Cultural tours', 'Photography', 'Local cuisine'],
      'location': 'China',
    },
  ];
  
  static const List<Map<String, dynamic>> samplePosts = [
    {
      'id': 1,
      'user': {
        'name': 'Sarah Johnson',
        'avatar': 'assets/images/travel-app-mockup.png',
        'username': '@sarahj',
      },
      'location': 'Treehouse Lodge, Costa Rica',
      'budget': '\$2,400',
      'image': 'assets/images/treehouse-waterfall.png',
      'caption': 'Most incredible treehouse experience ever! Waking up to the sound of waterfalls and being surrounded by nature. This unique eco-lodge cost \$2,400 for a week but every moment was magical! 🌿',
      'likes': 456,
      'comments': 32,
      'timeAgo': '1h',
    },
    {
      'id': 2,
      'user': {
        'name': 'Mike Chen',
        'avatar': 'assets/images/travel-app-mockup.png',
        'username': '@mikec',
      },
      'location': 'Kalahari Desert, Botswana',
      'budget': '\$1,800',
      'image': 'assets/images/meerkat-safari.png',
      'caption': 'Safari life at its finest! These meerkats were so curious about us. The desert safari experience was unforgettable - \$1,800 for 10 days including all meals and game drives! 🦁',
      'likes': 289,
      'comments': 45,
      'timeAgo': '3h',
    },
    {
      'id': 3,
      'user': {
        'name': 'Emma Wilson',
        'avatar': 'assets/images/travel-app-mockup.png',
        'username': '@emmaw',
      },
      'location': 'Marrakech, Morocco',
      'budget': '\$900',
      'image': 'assets/images/moroccan-luxury.png',
      'caption': 'The intricate architecture and luxury of Moroccan riads is breathtaking! This traditional palace hotel was surprisingly affordable at \$900 for 6 days. The craftsmanship is incredible! ✨',
      'likes': 378,
      'comments': 28,
      'timeAgo': '5h',
    },
    {
      'id': 4,
      'user': {
        'name': 'James Rodriguez',
        'avatar': 'assets/images/travel-app-mockup.png',
        'username': '@jamesr',
      },
      'location': 'Victoria Falls, Zimbabwe',
      'budget': '\$1,200',
      'image': 'assets/images/waterfall-tourists.png',
      'caption': 'Standing at the edge of one of the world\'s largest waterfalls! The mist and roar are incredible. \$1,200 for 5 days including helicopter rides and white water rafting! 🌊',
      'likes': 445,
      'comments': 67,
      'timeAgo': '8h',
    },
    {
      'id': 5,
      'user': {
        'name': 'Sophie Turner',
        'avatar': 'assets/images/travel-app-mockup.png',
        'username': '@sophiet',
      },
      'location': 'Cape Town, South Africa',
      'budget': '\$950',
      'image': 'assets/images/african-sunset-phone.png',
      'caption': 'Sunset from Table Mountain never gets old! The city lights starting to twinkle below. \$950 for 7 days including wine tours and penguin watching! 🐧',
      'likes': 523,
      'comments': 89,
      'timeAgo': '12h',
    },
    {
      'id': 6,
      'user': {
        'name': 'Carlos Mendez',
        'avatar': 'assets/images/travel-app-mockup.png',
        'username': '@carlosm',
      },
      'location': 'Hwange National Park, Zimbabwe',
      'budget': '\$2,100',
      'image': 'assets/images/wildlife-encounter.png',
      'caption': 'Close encounter with the Big Five! This elephant family was so peaceful. \$2,100 for 12 days luxury safari with all game drives and conservation activities! 🐘',
      'likes': 612,
      'comments': 134,
      'timeAgo': '1d',
    },
  ];
  
  static const List<Map<String, dynamic>> sampleStories = [
    {
      'id': 1,
      'user': 'You',
      'avatar': 'assets/images/travel-app-mockup.png',
      'hasStory': false,
      'isAdd': true,
    },
    {
      'id': 2,
      'user': 'Alex',
      'avatar': 'assets/images/travel-app-mockup.png',
      'hasStory': true,
      'isAdd': false,
    },
    {
      'id': 3,
      'user': 'Maria',
      'avatar': 'assets/images/travel-app-mockup.png',
      'hasStory': true,
      'isAdd': false,
    },
    {
      'id': 4,
      'user': 'David',
      'avatar': 'assets/images/travel-app-mockup.png',
      'hasStory': true,
      'isAdd': false,
    },
    {
      'id': 5,
      'user': 'Lisa',
      'avatar': 'assets/images/travel-app-mockup.png',
      'hasStory': true,
      'isAdd': false,
    },
  ];
  
  static const List<Map<String, dynamic>> userTypes = [
    {
      'value': 'traveler',
      'label': 'Traveler',
      'icon': 'camera',
      'description': 'Explore and share travel experiences',
      'credentials': {'email': 'innocentmafusire@gmail.com', 'password': 'demo123'},
    },
    {
      'value': 'business',
      'label': 'Business Owner',
      'icon': 'briefcase',
      'description': 'Manage accommodations and services',
      'credentials': {'email': 'business@demo.com', 'password': 'demo123'},
    },
    {
      'value': 'guide',
      'label': 'Tour Guide',
      'icon': 'star',
      'description': 'Offer guided tours and experiences',
      'credentials': {'email': 'guide@demo.com', 'password': 'demo123'},
    },
    {
      'value': 'admin',
      'label': 'Administrator',
      'icon': 'shield',
      'description': 'Manage platform and users',
      'credentials': {'email': 'admin@demo.com', 'password': 'demo123'},
    },
  ];
}