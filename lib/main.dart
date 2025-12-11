import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/services/auth_service.dart';
import 'package:trip_bud/services/trip_data_service.dart';
import 'package:trip_bud/screens/auth/login_screen.dart';
import 'package:trip_bud/screens/auth/register_screen.dart';
import 'package:trip_bud/screens/auth/reset_password_screen.dart';
import 'package:trip_bud/screens/trips/trips_overview_screen.dart';
import 'package:trip_bud/screens/trips/create_trip_screen.dart';
import 'package:trip_bud/screens/trip_detail/trip_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => FirebaseAuthService()),
        Provider<TripDataService>(create: (_) => FirestoreTripDataService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trip Bud',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 255, 153),
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/trips': (context) => const TripsOverviewScreen(),
          '/create-trip': (context) => const CreateTripScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/trip-detail') {
            final tripId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => TripDetailScreen(tripId: tripId),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isLoggedIn();

    if (isLoggedIn) {
      return const TripsOverviewScreen();
    } else {
      return const LoginScreen();
    }
  }
}
