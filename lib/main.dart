import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/services/messaging_service.dart';
import 'package:focus_flow/data/services/notifications_service.dart';
import 'package:focus_flow/firebase_options.dart';
import 'package:focus_flow/routes/app_pages.dart';
import 'package:focus_flow/routes/app_routes.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Intl.defaultLocale = 'es_ES';

  timeago.setLocaleMessages('es', timeago.EsMessages());

  // Solicita permisos FCM antes de lanzar la app
  final messagingService = MessagingService();
  await messagingService.requestPermission();
  messagingService.setupMessageHandlers();

  await NotificationsService().initializeNotifications();

  runApp(
    GetMaterialApp(
      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'MX'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'MX')],
    ),
  );
}
