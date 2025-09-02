import 'package:flutter/material.dart';
import 'login_patient.dart';
import 'login_doctor.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // أيقونة أو صورة
              const Icon(Icons.info_outline, size: 40, color: Colors.blue),

              const SizedBox(height: 20),

              const Text(
                "DocNow",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // أيقونة الطبيب
              const Icon(Icons.medical_services_outlined,
                  size: 100, color: Colors.orange),

              const SizedBox(height: 20),

              const Text(
                "أهلاً بك في DocNow",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "احجز المواعيد",
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 40),

              // زر المريض
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPatientPage()),
                    );
                  },
                  child: const Text(
                    "أنا مريض\nإدارة المواعيد",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // زر الطبيب
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginDoctorPage()),
                    );
                  },
                  child: const Text(
                    "أنا طبيب\nإدارة المواعيد",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const Spacer(),

              // رابط تسجيل الدخول
              GestureDetector(
                onTap: () {
                  // هنا ممكن توديه لصفحة اختيار تسجيل الدخول
                },
                child: const Text(
                  "لديك سجل دخول",
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            
            ],
          ),
        ),
      ),
    );
  }
}
