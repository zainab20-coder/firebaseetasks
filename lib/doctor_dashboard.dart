import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  String _formatDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}/$month/$day - $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final String? doctorEmail = FirebaseAuth.instance.currentUser?.email;

    if (doctorEmail == null || doctorEmail.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة المواعيد')),
        body: const Center(
          child: Text('تعذر تحديد حساب الطبيب، يرجى تسجيل الدخول مرة أخرى'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المواعيد')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('doctors')
            .where('email', isEqualTo: doctorEmail)
            .limit(1)
            .get(),
        builder: (context, doctorSnapshot) {
          if (!doctorSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (doctorSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('لا يوجد ملف طبيب مرتبط بهذا الحساب'),
            );
          }

          final String doctorDocId = doctorSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctorId', isEqualTo: doctorDocId)
                .orderBy('date')
                .snapshots(),
            builder: (context, appointmentsSnapshot) {
              if (!appointmentsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (appointmentsSnapshot.hasError) {
                return const Center(
                  child: Text('حدث خطأ أثناء تحميل المواعيد'),
                );
              }

              final appointments = appointmentsSnapshot.data!.docs;
              if (appointments.isEmpty) {
                return const Center(child: Text('لا توجد مواعيد حاليًا'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index].data();
                  final String patientId = (appointment['patientId'] ?? '')
                      .toString();
                  final Timestamp? dateTs = appointment['date'] as Timestamp?;
                  final DateTime date = dateTs?.toDate() ?? DateTime.now();
                  final String time = (appointment['time'] ?? '').toString();

                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('patients')
                        .doc(patientId)
                        .get(),
                    builder: (context, patientSnapshot) {
                      if (!patientSnapshot.hasData) {
                        return const Card(
                          child: ListTile(
                            title: Text('جاري تحميل بيانات المريض...'),
                          ),
                        );
                      }

                      final Map<String, dynamic>? patientData = patientSnapshot
                          .data!
                          .data();
                      final String patientName =
                          (patientData?['name'] ?? 'مريض').toString();
                      final String patientPhone =
                          (patientData?['phone'] ?? 'غير متوفر').toString();

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.blue,
                          ),
                          title: Text(patientName),
                          subtitle: Text(
                            'الهاتف: $patientPhone\n'
                            'التاريخ: ${_formatDateTime(date)}\n'
                            'الوقت: ${time.isEmpty ? 'غير محدد' : time}',
                          ),
                        ),
                      );
                    },
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
