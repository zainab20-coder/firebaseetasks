import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingPage extends StatefulWidget {
  final String patientId; // ID المريض
  const BookingPage({super.key, required this.patientId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String? selectedDoctorId;
  DateTime? selectedDate;

  Future<void> addAppointment() async {
    if (selectedDoctorId != null && selectedDate != null) {
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'doctorId': selectedDoctorId,
        'date': selectedDate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment booked ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select doctor and date")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // قائمة الدكاترة
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var doctors = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: selectedDoctorId,
                  hint: const Text("Select Doctor"),
                  items: doctors.map((doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor.id,
                      child: Text(doctor['name'] + " (" + doctor['specialization'] + ")"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDoctorId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // اختيار التاريخ
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text(selectedDate == null
                  ? "Select Date"
                  : "Selected: ${selectedDate!.toLocal()}".split(' ')[0]),
            ),
            const SizedBox(height: 30),

            // زر حجز
            ElevatedButton(
              onPressed: addAppointment,
              child: const Text("Book Appointment"),
            ),
          ],
        ),
      ),
    );
  }
}
