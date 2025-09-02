import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctors_list.dart'; // الصفحة اللي يروح عليها المريض بعد تسجيل الدخول
import 'register_patient.dart'; // للتسجيل كمريض

class LoginPatientPage extends StatefulWidget {
  const LoginPatientPage({super.key});

  @override
  State<LoginPatientPage> createState() => _LoginPatientPageState();
}

class _LoginPatientPageState extends State<LoginPatientPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _loginPatient() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // إذا نجح تسجيل الدخول
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DoctorsPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "حدث خطأ، حاول مرة أخرى";
      if (e.code == 'user-not-found') {
        message = "الحساب غير موجود";
      } else if (e.code == 'wrong-password') {
        message = "كلمة المرور غير صحيحة";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل دخول - مريض")),
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
                    onPressed: _loginPatient,
                    child: const Text("تسجيل دخول"),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterPatientPage()),
                );
              },
              child: const Text("إنشاء حساب جديد كمريض"),
            ),
          ],
        ),
      ),
    );
  }
}
