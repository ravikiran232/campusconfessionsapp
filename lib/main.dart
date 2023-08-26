import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled2/confession_home_page.dart';
import 'package:untitled2/login_page.dart';
import 'package:provider/provider.dart';
import 'package:untitled2/notification_services.dart';
import 'package:untitled2/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

NotificationServices notificationServices = NotificationServices();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] == 'confession' ||
      message.data['type'] == 'viewedConfession' ||
      message.data['type'] == 'admin approval' ||
      message.data['type'] == 'toSpecificIndividual') {
    await notificationServices.showNotification(message);
  } else {
    await FirebaseDatabase.instance
        .ref(
            'buyandsellmessages/${message.data['chatRoomID']}/latsmessage/${message.data["id"]}/')
        .update({"status": "delivered"});
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: StreamBuilder(
          stream: _auth.authStateChanges(),
          builder: (context, AsyncSnapshot<User?> snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                if (!_auth.currentUser!.emailVerified) {
                  return LoginPage();
                }
                return ConfessionHomePage();
              }
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return LoginPage();
          },
        ),
      ),
    );
  }
}
