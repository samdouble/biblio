import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tsunbooku/l10n/app_localizations.dart';
import 'package:newrelic_mobile/config.dart';
import 'package:newrelic_mobile/newrelic_mobile.dart';
import 'package:newrelic_mobile/newrelic_navigation_observer.dart';
import 'package:provider/provider.dart';
import 'screens/home_page.dart';
import 'widgets/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final newRelicToken = _resolveNewRelicToken();
  if (newRelicToken.isNotEmpty && !kIsWeb) {
    await NewrelicMobile.instance.startAgent(
      Config(
        accessToken: newRelicToken,
        analyticsEventEnabled: true,
        crashReportingEnabled: true,
        networkRequestEnabled: true,
        networkErrorRequestEnabled: true,
        interactionTracingEnabled: true,
        distributedTracingEnabled: true,
      ),
    );
  }

  runApp(const MyApp());
}

String _resolveNewRelicToken() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return dotenv.env['NEW_RELIC_ANDROID_APP_TOKEN'] ?? '';
    case TargetPlatform.iOS:
      return dotenv.env['NEW_RELIC_IOS_APP_TOKEN'] ?? '';
    default:
      return '';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            locale: appState.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'Tsunbooku',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            navigatorObservers: [
              NewRelicNavigationObserver(),
            ],
            home: Navigation(),
          );
        },
      ),
    );
  }
}
