import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trip_bud/models/hive_models.dart';
import 'package:trip_bud/services/auth_service.dart';
import 'package:trip_bud/services/trip_data_service.dart';
import 'package:trip_bud/screens/auth/login_screen.dart';
import 'package:trip_bud/screens/auth/register_screen.dart';
import 'package:trip_bud/screens/auth/reset_password_screen.dart';
import 'package:trip_bud/screens/trips/trips_overview_screen.dart';
import 'package:trip_bud/screens/trips/create_trip_screen.dart';
import 'package:trip_bud/screens/trip_detail/trip_detail_screen.dart';
import 'package:trip_bud/screens/user_profile_screen.dart';
import 'package:trip_bud/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(HiveTripAdapter());
  Hive.registerAdapter(HivePlaceAdapter());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = FirebaseAuthService();
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      final languageCode = await _authService.getUserLanguage(currentUser.id);
      if (mounted) {
        setLocale(Locale(languageCode ?? 'en'));
      }
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color.fromARGB(255, 0, 200, 120);

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => FirebaseAuthService()),
        Provider<TripDataService>(create: (_) => FirestoreTripDataService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trip Bud',
        locale: _locale,
        supportedLocales: const [Locale('en'), Locale('es'), Locale('pl')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: accentColor),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: AuthWrapper(onLocaleChange: setLocale),
        routes: {
          '/login': (context) => LoginScreen(onLocaleChange: setLocale),
          '/register': (context) => RegisterScreen(onLocaleChange: setLocale),
          '/reset-password': (context) =>
              ResetPasswordScreen(onLocaleChange: setLocale),
          '/trips': (context) => TripsOverviewScreen(onLocaleChange: setLocale),
          '/create-trip': (context) => const CreateTripScreen(),
          '/profile': (context) => UserProfileScreen(onLocaleChange: setLocale),
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
  final Function(Locale) onLocaleChange;

  const AuthWrapper({super.key, required this.onLocaleChange});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isLoggedIn();

    if (isLoggedIn) {
      return TripsOverviewScreen(onLocaleChange: onLocaleChange);
    } else {
      return LoginScreen(onLocaleChange: onLocaleChange);
    }
  }
}
