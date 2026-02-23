import 'package:flutter/material.dart';

class AddSlotsPage extends StatelessWidget {
  const AddSlotsPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController dateController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("إضافة مواعيد متاحة")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: "التاريخ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: "الوقت",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تمت إضافة الموعد بنجاح")),
                );
              },
              child: const Text("إضافة موعد"),
            ),
          ],
        ),
      ),
    );
  }
}
