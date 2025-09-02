import 'package:firebaseetasks/add_doctor_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_dashboard.dart';

class RegisterDoctorPage extends StatefulWidget {
  const RegisterDoctorPage({super.key});

  @override
  State<RegisterDoctorPage> createState() => _RegisterDoctorPageState();
}

class _RegisterDoctorPageState extends State<RegisterDoctorPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _registerDoctor() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),

      );
      

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  AddDoctorPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "حدث خطأ أثناء التسجيل";
      if (e.code == 'weak-password') {
        message = "كلمة المرور ضعيفة";
      } else if (e.code == 'email-already-in-use') {
        message = "البريد مستخدم مسبقاً";
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
      appBar: AppBar(title: const Text("تسجيل كطبيب")),
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
                    onPressed: _registerDoctor,
                    child: const Text("تسجيل"),
                  ),
          ],
        ),
      ),
    );
  }
}
