import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/icon_standards.dart';
import '../screens/landing_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAdmin;
  final String? redirectRoute;

  const AuthGuard({
    super.key,
    required this.child,
    this.requireAdmin = false,
    this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading indicator while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          return const LandingScreen();
        }

        // Check admin access if required
        if (requireAdmin && !authProvider.isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconStandards.getUIIcon('lock'),
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You do not have permission to access this page.\nAdmin privileges are required.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                        authProvider.getHomeRoute(),
                      );
                    },
                    child: const Text('Go to Home'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      authProvider.signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated and has required permissions
        return child;
      },
    );
  }
}

// Convenience widget for admin-only routes
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      requireAdmin: true,
      child: child,
    );
  }
}

// Route guard for checking authentication before navigation
class RouteGuard {
  static bool canAccess(BuildContext context, {bool requireAdmin = false}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      return false;
    }
    
    if (requireAdmin && !authProvider.isAdmin) {
      return false;
    }
    
    return true;
  }
  
  static void navigateWithGuard(
    BuildContext context,
    String routeName, {
    bool requireAdmin = false,
    Object? arguments,
  }) {
    if (canAccess(context, requireAdmin: requireAdmin)) {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    } else {
      // Show access denied dialog or redirect to login
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Access Denied'),
          content: Text(
            requireAdmin
                ? 'Admin privileges are required to access this page.'
                : 'Please sign in to access this page.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}