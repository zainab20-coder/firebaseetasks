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
      appBar: AppBar(title: const Text("إضافة طبيب")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 50),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "اسم الطبيب",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specializationController,
                      decoration: const InputDecoration(labelText: "التخصص"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: experienceController,
                      decoration: const InputDecoration(
                        labelText: "سنوات الخبرة",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "رقم الهاتف",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "البريد الإلكتروني",
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final String name = nameController.text.trim();
                        final String specialization = specializationController
                            .text
                            .trim();

                        if (name.isNotEmpty && specialization.isNotEmpty) {
                          await addDoctor();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تمت إضافة الطبيب بنجاح"),
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DoctorDashboard(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("يرجى إدخال الاسم والتخصص"),
                            ),
                          );
                        }
                      },
                      child: const Text("إضافة الطبيب"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
