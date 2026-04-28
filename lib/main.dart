// FocusPal — A Tamagotchi-style screen-time companion.
// Entry point: initialises storage, sets up Provider state,
// and routes to SplashScreen.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'state/chibi_state.dart';
import 'state/focus_state.dart';
import 'state/settings_state.dart';
import 'state/environment_state.dart';
import 'screens/splash_screen.dart';

/// Phone aspect ratio used to constrain the app's render area on web.
/// The whole UI was designed against ~411 × 870 dp (Pixel-class) — letting
/// it stretch across a desktop browser window broke the Home backdrop's
/// "ground line" alignment with the Chibi position. We frame the web build
/// in an AspectRatio so it always reads as a mobile app preview.
const double _phoneAspectRatio = 411 / 870;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise local storage (SharedPreferences + SQLite)
  await StorageService.init();

  runApp(const FocusPalApp());
}

class FocusPalApp extends StatelessWidget {
  const FocusPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final settings = SettingsState();
          settings.loadFromStorage();
          return settings;
        }),
        ChangeNotifierProvider(create: (_) => EnvironmentState()),
        ChangeNotifierProvider(create: (ctx) {
          final chibiState = ChibiState();
          // Wire up settings reference for mood thresholds
          final settings = ctx.read<SettingsState>();
          chibiState.setSettings(settings);
          return chibiState;
        }),
        ChangeNotifierProvider(create: (_) => FocusState()),
      ],
      child: MaterialApp(
        title: 'FocusPal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        builder: (context, child) {
          if (!kIsWeb || child == null) return child ?? const SizedBox();
          // Letterbox the app inside a phone-aspect rectangle on the web
          // so a desktop browser sees a mobile-app preview frame, with
          // the same internal layout the on-device build was tuned for.
          return ColoredBox(
            color: const Color(0xFF0D1535),
            child: Center(
              child: AspectRatio(
                aspectRatio: _phoneAspectRatio,
                child: ClipRect(child: child),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
