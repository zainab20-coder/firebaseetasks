import 'package:flutter/material.dart';

class AddSlotsPage extends StatelessWidget {
  const AddSlotsPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController dateController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Available Slots"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: "Date",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: "Time",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Slot Added Successfully")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text("Add Slot"),
            ),
          ],
        ),
      ),
    );
  }
}
