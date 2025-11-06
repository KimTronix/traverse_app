import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'utils/logger.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/travel_plan_screen.dart';
import 'screens/my_trip_plans_screen.dart';
import 'screens/trip_posts_feed_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/hotel_booking_screen.dart';
import 'screens/flight_booking_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/activity_booking_screen.dart';
import 'screens/car_rental_screen.dart';
import 'screens/booking_management_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/business_dashboard_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/chat_test_screen.dart';
import 'widgets/auth_guard.dart';
import 'widgets/database_splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/travel_provider.dart';
import 'screens/traverse_ai_screen.dart';
import 'screens/create_post_screen.dart';
import 'pages/real_time_demo_page.dart';
import 'providers/ui_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/status_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/statistics_provider.dart';
import 'services/supabase_service.dart';
import 'services/openai_service.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'utils/icon_standards.dart';
import 'utils/page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize OpenAI Service with environment variable
  final openaiApiKey = dotenv.env['OPENAI_API_KEY'];
  if (openaiApiKey == null || openaiApiKey.isEmpty) {
    Logger.warning('OpenAI API key not found in environment variables');
  }
  if (openaiApiKey != null && openaiApiKey.isNotEmpty) {
    OpenAIService.instance.initialize(openaiApiKey);
  } else {
    Logger.warning('OpenAI API key not found in environment variables');
  }
  
  await SharedPreferences.getInstance();
  runApp(const TraverseApp());
}

class TraverseApp extends StatelessWidget {
  const TraverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TravelProvider()),
        ChangeNotifierProvider(create: (_) => UIProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: MaterialApp.router(
        title: 'Traverse',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        builder: (context, child) {
          // Wrap the entire app with the database splash screen
          return DatabaseSplashScreen(child: child ?? Container());
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const LandingScreen(),
        transitionType: PageTransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/signin',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const SignInScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const SignUpScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/explore',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const ExploreScreen(),
        transitionType: PageTransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/travel-plan',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const TravelPlanScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/my-trip-plans',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const MyTripPlansScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/trip-posts/:destination',
      pageBuilder: (context, state) {
        final destination = Uri.decodeComponent(state.pathParameters['destination']!);
        return TraverseTransitionPage(
          key: state.pageKey,
          child: TripPostsFeedScreen(destination: destination),
          transitionType: PageTransitionType.fadeScale,
        );
      },
    ),
    GoRoute(
      path: '/messages',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const MessagesScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/wallet',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const WalletScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => TraverseTransitionPage(
        key: state.pageKey,
        child: const ProfileScreen(),
        transitionType: PageTransitionType.fadeScale,
      ),
    ),
    GoRoute(
      path: '/hotel-booking',
      builder: (context, state) {
        final hotel = state.extra as Map<String, dynamic>;
        return HotelBookingScreen(hotel: hotel);
      },
    ),
    GoRoute(
      path: '/flight-booking',
      builder: (context, state) {
        final flight = state.extra as Map<String, dynamic>;
        return FlightBookingScreen(flight: flight);
      },
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return PaymentScreen(
          bookingDetails: data['bookingDetails'],
          totalAmount: data['totalAmount'],
          currency: data['currency'],
        );
      },
    ),
    GoRoute(
      path: '/activity-booking',
      builder: (context, state) {
        final activity = state.extra as Map<String, dynamic>;
        return ActivityBookingScreen(activity: activity);
      },
    ),
    GoRoute(
            path: '/car-rental-booking',
            builder: (context, state) {
              final car = state.extra as Map<String, dynamic>;
              return CarRentalScreen(car: car);
            },
          ),
          GoRoute(
            path: '/booking-management',
            builder: (context, state) => const BookingManagementScreen(),
          ),
          GoRoute(
            path: '/booking-confirmation',
            builder: (context, state) {
              final booking = state.extra as Map<String, dynamic>;
              return BookingConfirmationScreen(booking: booking);
            },
          ),
          GoRoute(
            path: '/booking-confirmation/:bookingId',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId']!;
              // Create a dummy booking object for now
              final booking = {'id': bookingId, 'status': 'confirmed'};
              return BookingConfirmationScreen(booking: booking);
            },
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingManagementScreen(),
          ),
          GoRoute(
            path: '/destination-detail',
            builder: (context, state) {
              return const ExploreScreen();
            },
          ),
          GoRoute(
            path: '/post-detail',
            builder: (context, state) {
              return const HomeScreen();
            },
          ),
          GoRoute(
            path: '/real-time-demo',
            builder: (context, state) => const RealTimeDemoPage(),
          ),
          GoRoute(
            path: '/user-profile',
            builder: (context, state) {
              return const ProfileScreen();
            },
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) {
              return const ExploreScreen();
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/admin-login',
            builder: (context, state) => const AdminLoginScreen(),
          ),
          GoRoute(
            path: '/traverse-ai',
            builder: (context, state) => const TraverseAiScreen(),
          ),
          GoRoute(
            path: '/create-post',
            builder: (context, state) => const CreatePostScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminGuard(
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminGuard(
              child: AdminUserManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/business-dashboard',
            pageBuilder: (context, state) => TraverseTransitionPage(
              key: state.pageKey,
              child: const BusinessDashboardScreen(),
              transitionType: PageTransitionType.fadeScale,
            ),
          ),
          GoRoute(
            path: '/terms-conditions',
            pageBuilder: (context, state) => TraverseTransitionPage(
              key: state.pageKey,
              child: const TermsConditionsScreen(),
              transitionType: PageTransitionType.slideUp,
            ),
          ),
          GoRoute(
            path: '/chat-test',
            pageBuilder: (context, state) => TraverseTransitionPage(
              key: state.pageKey,
              child: const ChatTestScreen(),
              transitionType: PageTransitionType.slideLeft,
            ),
          ),
  ],
);

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/logo.png',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Traverse App',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'App is working!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go to Explore'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
