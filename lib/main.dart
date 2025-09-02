import 'package:firebaseetasks/AppointmentsPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// صفحات التطبيق
import 'welcome_page.dart';
import 'login_page.dart';
import 'register_patient.dart';
import 'register_doctor.dart';
import 'doctor_dashboard.dart';
import 'home_screen.dart'; // صفحة المريض

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocNow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/welcome', // البداية بالـ WelcomePage
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register_patient': (context) => const RegisterPatientPage(),
        '/register_doctor': (context) => const RegisterDoctorPage(),
        '/home': (context) => const HomeScreen(), // للمريض
        '/doctor_dashboard': (context) => const DoctorDashboard(), // للطبيب
        '/appointments': (context) => const AppointmentsPage(
          patientId: 'GQrwiHFpBFb3vD2o8uRj',
        ), // صفحة المواعيد
      },
    );
  }
}
