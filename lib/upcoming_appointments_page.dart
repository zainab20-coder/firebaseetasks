import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpcomingAppointmentsPage extends StatelessWidget {
  final String patientId; // ID المريض
  const UpcomingAppointmentsPage({super.key, required this.patientId});

  Stream<QuerySnapshot> getAppointments() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المواعيد القادمة")),
      body: StreamBuilder<QuerySnapshot>(
        stream: getAppointments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ أثناء تحميل المواعيد"));
          }

          final appointments = snapshot.data!.docs;
          if (appointments.isEmpty) {
            return const Center(child: Text("لا توجد مواعيد قادمة"));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var appointment = appointments[index];
              DateTime date = (appointment['date'] as Timestamp).toDate();
              String doctorId = appointment['doctorId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(doctorId)
                    .get(),
                builder: (context, docSnapshot) {
                  if (!docSnapshot.hasData) {
                    return const ListTile(
                      title: Text("جاري تحميل بيانات الطبيب..."),
                    );
                  }

                  var doctor = docSnapshot.data!;
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      title: Text("د. ${doctor['name']}"),
                      subtitle: Text(
                        "التخصص: ${doctor['specialization']}\nالتاريخ: ${date.toLocal()}"
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
