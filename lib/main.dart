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

/// Design-size dimensions used to constrain the app's render area on web.
/// The UI was tuned against ~411 × 870 dp (Pixel-class). On the web
/// `MaterialApp.builder` we render the full design canvas and scale it
/// uniformly to whatever space the viewport gives us (FittedBox /
/// BoxFit.contain), so the layout never reflows and no off-screen content
/// is hidden — small browser windows just see a smaller phone frame.
const double _phoneDesignWidth = 411;
const double _phoneDesignHeight = 870;

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
          // Force-fit on the web: always render the full 411×870 design
          // canvas and uniformly scale it to whatever space the viewport
          // gives us. Internal logical pixels stay at 411×870 so the
          // layout never reflows; the only thing that changes between
          // viewports is the visual scale factor. No scrolling, no
          // truncated CTAs — at the cost of small browser windows
          // showing a slightly smaller phone frame.
          return ColoredBox(
            color: const Color(0xFF0D1535),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _phoneDesignWidth,
                  height: _phoneDesignHeight,
                  child: ClipRect(child: child),
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
