import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppointmentsPage extends StatelessWidget {
  final String? patientId;
  const AppointmentsPage({super.key, this.patientId});

  Stream<QuerySnapshot<Map<String, dynamic>>> _getAppointments(String uid) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: uid)
        .orderBy('date')
        .snapshots();
  }

  String _formatDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}/$month/$day - $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = patientId ?? FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("مواعيدي")),
        body: const Center(child: Text("يرجى تسجيل الدخول لعرض المواعيد")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("مواعيدي")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getAppointments(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ أثناء تحميل المواعيد"));
          }

          final appointments = snapshot.data!.docs;
          if (appointments.isEmpty) {
            return const Center(child: Text("لا توجد مواعيد"));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data();
              final String doctorId = (data['doctorId'] ?? '').toString();
              final Timestamp? dateTs = data['date'] as Timestamp?;
              final DateTime date = dateTs?.toDate() ?? DateTime.now();
              final String time = (data['time'] ?? '').toString().isNotEmpty
                  ? data['time'].toString()
                  : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(doctorId)
                    .get(),
                builder: (context, doctorSnapshot) {
                  if (!doctorSnapshot.hasData) {
                    return const ListTile(
                      title: Text("جاري تحميل بيانات الطبيب..."),
                    );
                  }

                  final Map<String, dynamic>? doctorData = doctorSnapshot.data!
                      .data();
                  final String doctorName = (doctorData?['name'] ?? 'طبيب')
                      .toString();
                  final String specialization =
                      (doctorData?['specialization'] ?? 'غير محدد').toString();

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.green,
                      ),
                      title: Text('د. $doctorName'),
                      subtitle: Text(
                        'التخصص: $specialization\n'
                        'التاريخ: ${_formatDateTime(date)}\n'
                        'الوقت: $time',
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
