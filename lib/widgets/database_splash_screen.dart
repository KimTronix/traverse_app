import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/icon_standards.dart';

class DatabaseSplashScreen extends StatefulWidget {
  final Widget child;

  const DatabaseSplashScreen({super.key, required this.child});

  @override
  State<DatabaseSplashScreen> createState() => _DatabaseSplashScreenState();
}

class _DatabaseSplashScreenState extends State<DatabaseSplashScreen> {
  bool _isLoading = true;
  bool _connectionSuccess = false;
  String _statusMessage = 'Testing database connection...';

  @override
  void initState() {
    super.initState();
    _testDatabaseConnection();
  }

  Future<void> _testDatabaseConnection() async {
    try {
      // Wait a moment to show the splash
      await Future.delayed(const Duration(milliseconds: 500));

      final isConnected = await SupabaseService.testConnection();

      setState(() {
        _connectionSuccess = isConnected;
        _statusMessage = isConnected
            ? 'The Globe is now in your hands!'
            : 'Sorry!! The Globe is too far';
      });

      // Show result for 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _statusMessage = 'Connection error: $e';
      });

      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E3A8A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // App Name
              const Text(
                'Traverse',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),

              // Status message
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),

              // Connection status indicator
              if (_statusMessage != 'Getting you connected to the Globe...')
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _connectionSuccess ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _connectionSuccess
                            ? IconStandards.getUIIcon('success')
                            : IconStandards.getUIIcon('error'),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connectionSuccess ? 'Connected' : 'wait',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
