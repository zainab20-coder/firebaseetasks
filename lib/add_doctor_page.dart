import 'package:firebaseetasks/doctor_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDoctorPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  AddDoctorPage({super.key});

  // دالة إضافة الدكتور إلى Firebase
  Future<void> addDoctor() async {
    await FirebaseFirestore.instance.collection('doctors').add({
      'name': nameController.text,
      'specialization': specializationController.text,
      'experience': experienceController.text.trim(),
      'phone': phoneController.text, // مثال على رقم الهاتف
      'email': emailController.text, // مثال على البريد الإلكتروني
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Doctor")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Doctor Name"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: specializationController,
              decoration: const InputDecoration(labelText: "Specialization"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: experienceController,
              decoration: const InputDecoration(labelText: "Experience"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "phone"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                String name = nameController.text.trim();
                String specialization = specializationController.text.trim();

                if (name.isNotEmpty && specialization.isNotEmpty) {
                  await addDoctor();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Doctor Added Successfully ✅"),
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorDashboard()),
                  );
                }
              },
              child: const Text("Add Doctor"),
            ),
          ],
        ),
      ),
    );
  }
}
