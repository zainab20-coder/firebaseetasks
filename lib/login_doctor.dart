import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_dashboard.dart';
import 'register_doctor.dart';

class LoginDoctorPage extends StatefulWidget {
  const LoginDoctorPage({super.key});

  @override
  State<LoginDoctorPage> createState() => _LoginDoctorPageState();
}

class _LoginDoctorPageState extends State<LoginDoctorPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _loginDoctor() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DoctorDashboard() ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "فشل تسجيل الدخول";
      if (e.code == 'user-not-found') {
        message = "الحساب غير موجود";
      } else if (e.code == 'wrong-password') {
        message = "كلمة المرور غير صحيحة";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل دخول - طبيب")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "البريد الإلكتروني"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "كلمة المرور"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loginDoctor,
                    child: const Text("تسجيل دخول"),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterDoctorPage()),
                );
              },
              child: const Text("إنشاء حساب جديد كطبيب"),
            ),
          ],
        ),
      ),
    );
  }
}
