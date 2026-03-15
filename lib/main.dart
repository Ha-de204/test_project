import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';

import 'constants.dart';
import 'screens/expense_tracker_screen.dart';
import 'utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Quản lý Chi tiêu',
      theme: ThemeData(
        scaffoldBackgroundColor: kLightPinkBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryPink).copyWith(
          secondary: kPrimaryPink,
        ),
        useMaterial3: true,
      ),

      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),

      home: const ExpenseTrackerScreen(),
    );
  }
}