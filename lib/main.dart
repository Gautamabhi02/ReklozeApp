import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:rekloze/screens/EditContractTimelinePdfPage.dart';
import 'package:rekloze/screens/calendar_page.dart';
import 'package:rekloze/screens/home_page.dart';
import 'package:rekloze/screens/upload_contract_page.dart';
import 'package:rekloze/service/notification_service.dart';
import 'package:rekloze/service/user_session_service.dart';
import 'package:rekloze/utils/background_processor.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await BackgroundTaskManager.initialize();

  // Initialize Riverpod and session
  String? token;
  try {
    await UserSessionService().initialize();

    token = UserSessionService().token;
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    ProviderScope(
      child: MyApp(initialRoute: (token != null) ? '/contract' : '/loginPage'),
    ),
  );
}

class MyApp extends ConsumerWidget { // Changed to ConsumerWidget
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    NotificationService.navigatorKey = GlobalKey<NavigatorState>();

    return MaterialApp(
      title: 'Rekloze App',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },
      initialRoute: initialRoute,
      routes: {
        '/loginPage': (context) => const LoginPage(),
        '/homePage': (context) => const HomePage(),
        '/contract': (context) => const UploadContractPage(),
        '/editContractTimeline': (context) => EditContractTimelinePdfPage(),
        '/calender':(context)=> const CalendarPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(

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
