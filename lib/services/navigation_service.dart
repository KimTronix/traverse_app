import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Navigation methods
  static void navigateToHome(BuildContext context) {
    context.go('/home');
  }

  static void navigateToExplore(BuildContext context) {
    context.go('/explore');
  }

  static void navigateToMessages(BuildContext context) {
    context.go('/messages');
  }

  static void navigateToProfile(BuildContext context) {
    context.go('/profile');
  }

  static void navigateToWallet(BuildContext context) {
    context.go('/wallet');
  }

  static void navigateToBookings(BuildContext context) {
    context.go('/bookings');
  }

  static void navigateToTravelPlan(BuildContext context) {
    context.go('/travel-plan');
  }

  static void navigateToTravelPlanWithSuggestion(BuildContext context, Map<String, dynamic> suggestedTrip) {
    context.push('/travel-plan', extra: suggestedTrip);
  }

  static void navigateToHotelBooking(BuildContext context, Map<String, dynamic> hotel) {
    context.push('/hotel-booking', extra: hotel);
  }

  static void navigateToFlightBooking(BuildContext context, Map<String, dynamic> flight) {
    context.push('/flight-booking', extra: flight);
  }

  static void navigateToActivityBooking(BuildContext context, Map<String, dynamic> activity) {
    context.push('/activity-booking', extra: activity);
  }

  static void navigateToCarRental(BuildContext context, Map<String, dynamic> car) {
    context.push('/car-rental', extra: car);
  }

  static void navigateToPayment(BuildContext context, Map<String, dynamic> bookingData) {
    context.push('/payment', extra: bookingData);
  }

  static void navigateToBookingConfirmation(BuildContext context, String bookingId) {
    context.push('/booking-confirmation/$bookingId');
  }

  static void navigateToDestinationDetail(BuildContext context, Map<String, dynamic> destination) {
    context.push('/destination-detail', extra: destination);
  }

  static void navigateToPostDetail(BuildContext context, Map<String, dynamic> post) {
    context.push('/post-detail', extra: post);
  }

  static void navigateToUserProfile(BuildContext context, Map<String, dynamic> user) {
    context.push('/user-profile', extra: user);
  }

  static void navigateToSettings(BuildContext context) {
    context.push('/settings');
  }

  static void navigateToNotifications(BuildContext context) {
    context.push('/notifications');
  }

  static void navigateToSearch(BuildContext context, {String? query}) {
    if (query != null) {
      context.push('/search?q=$query');
    } else {
      context.push('/search');
    }
  }

  static void navigateToCreatePost(BuildContext context) {
    context.push('/create-post');
  }

  static void navigateToEditProfile(BuildContext context) {
    context.push('/edit-profile');
  }

  static void navigateToHelp(BuildContext context) {
    context.push('/help');
  }

  static void navigateToAbout(BuildContext context) {
    context.push('/about');
  }

  static void navigateToPrivacyPolicy(BuildContext context) {
    context.push('/privacy-policy');
  }

  static void navigateToTermsOfService(BuildContext context) {
    context.push('/terms-of-service');
  }

  // Back navigation
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  // Replace current route
  static void replaceWith(BuildContext context, String route) {
    context.pushReplacement(route);
  }

  // Clear stack and navigate
  static void navigateAndClearStack(BuildContext context, String route) {
    context.go(route);
  }

  // Show modal bottom sheet
  static void showBottomSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }

  // Show dialog
  static void showCustomDialog(BuildContext context, Widget child) {
    showDialog(
      context: context,
      builder: (context) => child,
    );
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show success message
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  // Show error message
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  // Show info message
  static void showInfo(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.blue);
  }

  // Handle deep links
  static void handleDeepLink(BuildContext context, String link) {
    // Parse and navigate based on deep link
    if (link.contains('/hotel/')) {
      final hotelId = link.split('/hotel/').last;
      // Navigate to hotel detail with ID
      context.push('/hotel-detail/$hotelId');
    } else if (link.contains('/destination/')) {
      final destinationId = link.split('/destination/').last;
      // Navigate to destination detail with ID
      context.push('/destination-detail/$destinationId');
    } else if (link.contains('/post/')) {
      final postId = link.split('/post/').last;
      // Navigate to post detail with ID
      context.push('/post-detail/$postId');
    } else {
      // Default navigation
      context.go(link);
    }
  }

  // Check if route exists
  static bool canNavigateTo(String route) {
    // Add route validation logic here
    final validRoutes = [
      '/home',
      '/explore',
      '/messages',
      '/profile',
      '/wallet',
      '/bookings',
      '/travel-plan',
      '/settings',
      '/notifications',
      '/search',
    ];
    return validRoutes.contains(route);
  }

  // Get current route
  static String? getCurrentRoute(BuildContext context) {
    return GoRouterState.of(context).uri.toString();
  }

  // Navigation with animation
  static void navigateWithSlideTransition(BuildContext context, Widget destination) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // Navigation with fade transition
  static void navigateWithFadeTransition(BuildContext context, Widget destination) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}