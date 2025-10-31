import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/account_balance_service.dart';
import 'services/local_storage_service.dart';
import 'services/migration_service.dart';
import 'services/sync_service.dart';
import 'utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Configure Firestore with longer timeouts for unreliable networks (like Jio)
  // This helps with networks that have intermittent connectivity or DNS issues
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      // Note: timeout settings are not directly configurable in Flutter Firestore
      // but enabling persistence helps with offline operations
    );
    DebugLogger.log('Firestore settings configured');
  } catch (e) {
    DebugLogger.logError('Error configuring Firestore settings: $e');
    // Continue even if settings fail
  }
  
  // Initialize Hive
  try {
    await Hive.initFlutter();
    await LocalStorageService.initialize();
    DebugLogger.log('Hive and LocalStorageService initialized');
  } catch (e) {
    DebugLogger.logError('Error initializing Hive: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CabStats',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasInitializedAccounts = false;
  bool _hasMigrated = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
          );
        }
        
              // If user is logged in, show home screen
              if (snapshot.hasData) {
                // Run migration and initialize accounts only once per session
                if (!_hasInitializedAccounts) {
                  _hasInitializedAccounts = true;
                  // Initialize immediately before showing UI
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    try {
                      // Initialize account balances FIRST (before migration) so UI has data immediately
                      await AccountBalanceService().initializeAllAccountBalances();
                      
                      // Check if local data exists, if not, migrate from Firebase
                      final hasLocalData = await LocalStorageService().hasLocalData();
                      if (!hasLocalData && !_hasMigrated) {
                        _hasMigrated = true;
                        DebugLogger.log('No local data found, starting migration...');
                        await MigrationService().migrateFromFirebase();
                        DebugLogger.logSuccess('Migration completed');
                      }
                      
                      // Background sync disabled - user will manually sync when needed
                      DebugLogger.log('Account initialization completed - use manual sync from drawer');
                    } catch (e) {
                      DebugLogger.logError('Error during initialization: $e');
                    }
                  });
                }
                return const HomeScreen();
              }
        
        // Reset initialization flag when user logs out
        if (_hasInitializedAccounts) {
          _hasInitializedAccounts = false;
          _hasMigrated = false;
        }
        
        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}