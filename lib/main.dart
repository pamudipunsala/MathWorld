import 'dart:convert';

import 'package:flutter/material.dart';
// Add imports for the puzzle page and BLoC provider
import 'presentation/pages/puzzle_page.dart';
import 'presentation/pages/calculation_type_selection_page.dart';
import 'presentation/pages/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// TODO: Set this to your backend base URL, e.g. "https://api.example.com"
/// Set to empty string to disable sending
const String kAdjustTestBaseUrl = 'https://www.youtube.com';

/// Sends the current Adjust attribution values (stored in SharedPreferences)
/// to `POST $kAdjustTestBaseUrl/adjust-debug` as JSON for debugging.
/// Also opens the URL in browser with query parameters.
Future<void> sendAdjustAttributesToBackend() async {
  // Check if base URL is set (not empty and not placeholder)
  if (kAdjustTestBaseUrl.isEmpty ||
      kAdjustTestBaseUrl == 'https://YOUR_BASE_URL_HERE') {
    debugPrint('⚠️ kAdjustTestBaseUrl is not set; skipping Adjust debug send.');
    return;
  }

  debugPrint('🌐 Base URL configured: $kAdjustTestBaseUrl');

  // Wait for attribution data using method channel (reads directly from native SharedPreferences)
  bool hasValues = false;
  int attempts = 0;
  const maxAttempts = 30; // 30 attempts * 500ms = 15 seconds

  debugPrint('⏳ Waiting for Adjust attribution data...');

  String source = '';
  String campaign = '';
  String adgroup = '';
  String creative = '';
  String trackerName = '';
  String trackerToken = '';
  String adjustDeviceId = '';

  final adjustChannel = MethodChannel('com.example.mathworld/adjust');

  while (!hasValues && attempts < maxAttempts) {
    await Future.delayed(const Duration(milliseconds: 500));

    // Read directly from native SharedPreferences via method channel
    try {
      final result = await adjustChannel.invokeMethod('getAdjustAttribution');
      if (result is Map) {
        source = result['source'] as String? ?? '';
        campaign = result['campaign'] as String? ?? '';
        adgroup = result['adgroup'] as String? ?? '';
        creative = result['creative'] as String? ?? '';
        trackerName = result['trackerName'] as String? ?? '';
        trackerToken = result['trackerToken'] as String? ?? '';
        adjustDeviceId = result['adjustDeviceId'] as String? ?? '';

        hasValues =
            source.isNotEmpty ||
            campaign.isNotEmpty ||
            adgroup.isNotEmpty ||
            creative.isNotEmpty ||
            trackerName.isNotEmpty ||
            trackerToken.isNotEmpty ||
            adjustDeviceId.isNotEmpty;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading attribution: $e');
    }

    if (hasValues) {
      debugPrint(
        '✅ Adjust attribution data received after ${attempts * 500}ms',
      );
    } else if (attempts % 4 == 0) {
      // Log every 2 seconds
      debugPrint('⏳ Still waiting... (${attempts * 500}ms elapsed)');
    }

    attempts++;
  }

  if (!hasValues) {
    debugPrint(
      '⚠️ Timeout: No attribution data received after ${maxAttempts * 500}ms',
    );
    debugPrint('   Trying one more time with native method channel...');
    // Try one more time
    try {
      final result = await adjustChannel.invokeMethod('getAdjustAttribution');
      if (result is Map) {
        source = result['source'] as String? ?? '';
        campaign = result['campaign'] as String? ?? '';
        adgroup = result['adgroup'] as String? ?? '';
        creative = result['creative'] as String? ?? '';
        trackerName = result['trackerName'] as String? ?? '';
        trackerToken = result['trackerToken'] as String? ?? '';
        adjustDeviceId = result['adjustDeviceId'] as String? ?? '';

        hasValues =
            source.isNotEmpty ||
            campaign.isNotEmpty ||
            adgroup.isNotEmpty ||
            creative.isNotEmpty ||
            trackerName.isNotEmpty ||
            trackerToken.isNotEmpty ||
            adjustDeviceId.isNotEmpty;
      }
    } catch (e) {
      debugPrint('⚠️ Final attempt failed: $e');
    }
  }

  final payload = <String, dynamic>{
    'source': source,
    'campaign': campaign,
    'adgroup': adgroup,
    'creative': creative,
    'trackerName': trackerName,
    'trackerToken': trackerToken,
    'adjustDeviceId': adjustDeviceId,
  };

  // Print all values to console
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('📤 Adjust Debug - Reading from SharedPreferences:');
  debugPrint('   source: "$source"');
  debugPrint('   campaign: "$campaign"');
  debugPrint('   adgroup: "$adgroup"');
  debugPrint('   creative: "$creative"');
  debugPrint('   trackerName: "$trackerName"');
  debugPrint('   trackerToken: "$trackerToken"');
  debugPrint('   adjustDeviceId: "$adjustDeviceId"');
  debugPrint('═══════════════════════════════════════════════════════');

  // Check if any values are populated (reuse the hasValues from polling loop)
  if (!hasValues) {
    debugPrint('⚠️ WARNING: All Adjust attributes are empty!');
    debugPrint(
      '   This means Adjust SDK may not be initialized or attribution not received yet.',
    );
    debugPrint(
      '   Check logcat for "AdjustAttribution" logs: adb logcat | grep AdjustAttribution',
    );
    debugPrint(
      '   Make sure adjustAppToken is set in android/local.properties',
    );
  }

  // Get Android device ID
  String deviceId = '';
  try {
    final androidIdResult = await adjustChannel.invokeMethod('getAndroidId');
    deviceId = androidIdResult as String? ?? '';
    debugPrint('📱 Android Device ID: $deviceId');
  } catch (e) {
    debugPrint('⚠️ Could not get Android ID: $e');
  }

  // Build URL with query parameters for easy viewing
  final queryParams = <String, String>{
    'source': source,
    'campaign': campaign,
    'adgroup': adgroup,
    'creative': creative,
    'trackerName': trackerName,
    'trackerToken': trackerToken,
    'adjustDeviceId': adjustDeviceId,
    'deviceId': deviceId,
    'eventType': '2', // Static value
  };

  final uri = Uri.parse(
    kAdjustTestBaseUrl,
  ).replace(queryParameters: queryParams);

  debugPrint('🌐 Opening URL in browser: $uri');
  debugPrint('   Full URL with params: ${uri.toString()}');

  // Open URL in browser using platform channel
  try {
    final methodChannel = MethodChannel('com.example.mathworld/url_launcher');
    debugPrint('📞 Calling method channel to open URL...');
    final result = await methodChannel.invokeMethod('launchUrl', {
      'url': uri.toString(),
    });
    debugPrint('✅ Method channel result: $result');
    debugPrint('✅ URL should have opened in browser');
  } catch (e, stackTrace) {
    debugPrint('❌ Error opening URL: $e');
    debugPrint('   Stack trace: $stackTrace');
    debugPrint('   URL: $uri');
    debugPrint('   You can manually open this URL in a browser');
  }

  // Also send HTTP POST request (if you have a backend endpoint)
  try {
    final postUri = Uri.parse('$kAdjustTestBaseUrl/adjust-debug');
    debugPrint('📤 Also sending POST request to $postUri');

    final response = await http.post(
      postUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    debugPrint(
      '✅ POST response: ${response.statusCode} ${response.reasonPhrase}',
    );
  } catch (e) {
    debugPrint(
      'ℹ️ POST request failed (this is OK if endpoint doesn\'t exist): $e',
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Puzzle',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // TODO: Use app_constants for theme if available
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
