import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:typing_app/providers/sentence_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:typing_app/providers/typing_provider.dart';

import './providers/auth_provider.dart';
import './screens/auth_screen.dart';
import './screens/home_screen.dart';
import './screens/typing_screen.dart';
import './screens/leaderboard_screen.dart';
import './screens/profile_screen.dart'; // Import the ProfileScreen
import './screens/splash_screen.dart'; // A temporary screen for checking auth state

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        // SentenceProvider depends on AuthProvider for token, but not directly for instantiation
        // However, API calls within SentenceProvider might need the token.
        // If SentenceProvider needs to react to AuthProvider changes immediately upon creation,
        // use ChangeNotifierProxyProvider. For now, simple provider is fine.
        ChangeNotifierProvider(create: (ctx) => SentenceProvider()),
        ChangeNotifierProvider(create: (ctx) => TypingProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Typing Competition', // This title will be replaced by AppLocalizations if used on a specific widget like AppBar

          // Localization settings
          localizationsDelegates: const [
            AppLocalizations.delegate, // Add generated delegate
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
            Locale('fa', ''), // Farsi, no country code
          ],
          locale: const Locale('fa', ''), // Set Farsi as the default locale

          theme: ThemeData(
            brightness: Brightness.light, // Or Brightness.dark
            primaryColor: Colors.indigo, // A deep blue-purple
            colorScheme:
                ColorScheme.fromSwatch(
                  primarySwatch:
                      Colors.indigo, // Used for many Material components
                ).copyWith(
                  secondary: Colors.pinkAccent, // Accent color
                  // background: Colors.grey[100], // Optional: custom background
                ),
            scaffoldBackgroundColor:
                Colors.grey[100], // Light grey background for scaffolds

            // fontFamily: 'Lato', // Example: Using a custom font (ensure it's added to pubspec.yaml and assets)
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 72.0,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: TextStyle(
                fontSize: 24.0,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              // bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'), // Example of different font for body
              bodyMedium: TextStyle(fontSize: 14.0),
              labelLarge: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ), // For ElevatedButton text
            ),

            buttonTheme: ButtonThemeData(
              buttonColor: Colors.indigo, // Background color for buttons
              textTheme: ButtonTextTheme.primary, // Text color for buttons
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),

            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, // Button background
                foregroundColor: Colors.white, // Button text (and icon)
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    8.0,
                  ), // Slightly less rounded than global ButtonTheme
                ),
              ),
            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    Colors.pinkAccent, // Text color for text buttons
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.indigo),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.pinkAccent,
                  width: 2.0,
                ),
              ),
              labelStyle: const TextStyle(color: Colors.indigo),
            ),

            cardTheme: CardTheme(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              margin: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 5.0,
              ),
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white, // Text and icon color for AppBar
              elevation: 4,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // visualDensity: VisualDensity.adaptivePlatformDensity, // Optional
            // Adding a more modern page transition
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android:
                    CupertinoPageTransitionsBuilder(), // Example modern transition
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          // The home property will be updated later to use AppLocalizations for its title if needed
          home: auth.isAuthenticated
              ? const HomeScreen()
              : FutureBuilder(
                  // Used to wait for _tryAutoLogin in AuthProvider
                  future: Provider.of<AuthProvider>(
                    ctx,
                    listen: false,
                  )._tryAutoLogin(), // Check if already done by constructor
                  builder: (context, authResultSnapshot) {
                    if (authResultSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SplashScreen(); // Show splash screen while checking auth
                    }
                    // After tryAutoLogin, check isAuthenticated again
                    return auth.isAuthenticated
                        ? const HomeScreen()
                        : const AuthScreen();
                  },
                ),
          routes: {
            AuthScreen.routeName: (ctx) => const AuthScreen(),
            HomeScreen.routeName: (ctx) => const HomeScreen(),
            TypingScreen.routeName: (ctx) => const TypingScreen(),
            LeaderboardScreen.routeName: (ctx) => const LeaderboardScreen(),
            ProfileScreen.routeName: (ctx) =>
                const ProfileScreen(),
            // No need for SplashScreen.routeName if only used in home decision logic
          },
          // Example of using locale in builder if needed for dynamic locale changes, though not strictly required by this step
          // builder: (context, child) {
          //   return MediaQuery(
          //     data: MediaQuery.of(context).copyWith(
          //       // You could override textScaleFactor here based on locale if desired
          //     ),
          //     child: child!,
          //   );
          // },
        ),
      ),
    );
  }
}
