import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsPage extends StatelessWidget {
  final String patientId; // ID الدكتور
  const AppointmentsPage({super.key, required this.patientId});

  Stream<QuerySnapshot> getAppointments() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: patientId)
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
      body: StreamBuilder<QuerySnapshot>(
        stream: getAppointments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading appointments ❌"));
          }

          final appointments = snapshot.data!.docs;
          if (appointments.isEmpty) {
            return const Center(child: Text("No appointments 🩺"));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var appointment = appointments[index];
              DateTime date = (appointment['date'] as Timestamp).toDate();
              String patientId = appointment['patientId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(patientId)
                    .get(),
                builder: (context, docSnapshot) {
                  if (!docSnapshot.hasData) {
                    return const ListTile(title: Text("Loading patient..."));
                  }

                  var patient = docSnapshot.data!;
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(patient['name']),
                      subtitle: Text(
                        "Phone: ${patient['phone']}\nDate: ${date.toLocal()}"
                            .split(' ')[0],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
