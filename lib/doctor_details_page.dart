import 'package:firebaseetasks/AppointmentsPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDetailsPage extends StatelessWidget {
  final String doctorId; // ID الدكتور
  const DoctorDetailsPage({super.key, required this.doctorId});

  Future<DocumentSnapshot> getDoctorDetails() {
    return FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: getDoctorDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text("Error loading doctor details ❌"));

          var doctor = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person, size: 100, color: Colors.blue),
                const SizedBox(height: 20),
                Text("Name: ${doctor['name']}", style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text("Specialization: ${doctor['specialization']}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                // أي معلومات إضافية يمكن إضافتها هنا
                if (doctor['experience'] != null)
                  Text("Phone: ${doctor['phone']}", style: const TextStyle(fontSize: 18)),
                if (doctor['email'])
                  Text("Email: ${doctor['email']}", style: const TextStyle(fontSize: 18)),
                 ElevatedButton(
                  onPressed:() {
                     Navigator.push(
                 context,
                MaterialPageRoute(builder: (context) => AppointmentsPage(patientId: 'GQrwiHFpBFb3vD2o8uRj',)),
              );
                  }, child: const Text('Book Appointment')), 
              ],
            ),
          );
        },
      ),
    );
  }
}
