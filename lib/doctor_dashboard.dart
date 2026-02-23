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

  String _readText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  Future<Map<String, String>> _resolveAppointmentDisplayData({
    required Map<String, dynamic> appointment,
    required bool showDoctorName,
  }) async {
    String patientName = _readText(appointment['patientName']);
    String patientPhone = _readText(appointment['patientPhone']);
    String doctorName = _readText(appointment['doctorName']);
    final String patientId = _readText(appointment['patientId']);
    final String doctorId = _readText(appointment['doctorId']);

    if ((patientName.isEmpty || patientPhone.isEmpty) && patientId.isNotEmpty) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> patientDoc =
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(patientId)
                .get();
        final Map<String, dynamic>? patientData = patientDoc.data();
        patientName = patientName.isEmpty
            ? _readText(patientData?['name'])
            : patientName;
        patientPhone = patientPhone.isEmpty
            ? _readText(patientData?['phone'])
            : patientPhone;
      } catch (_) {}
    }

    if (showDoctorName && doctorName.isEmpty && doctorId.isNotEmpty) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> doctorDoc =
            await FirebaseFirestore.instance
                .collection('doctors')
                .doc(doctorId)
                .get();
        final Map<String, dynamic>? doctorData = doctorDoc.data();
        doctorName = _readText(doctorData?['name']);
      } catch (_) {}
    }

    return {
      'patientName': patientName.isEmpty ? 'مريض' : patientName,
      'patientPhone': patientPhone.isEmpty ? 'غير متوفر' : patientPhone,
      'doctorName': doctorName.isEmpty ? 'طبيب' : doctorName,
    };
  }

  Widget _appointmentCard({
    required Map<String, dynamic> appointment,
    bool showDoctorName = false,
  }) {
    final Timestamp? dateTs = appointment['date'] as Timestamp?;
    final DateTime date = dateTs?.toDate() ?? DateTime.now();
    final String time = _readText(appointment['time']);

    return FutureBuilder<Map<String, String>>(
      future: _resolveAppointmentDisplayData(
        appointment: appointment,
        showDoctorName: showDoctorName,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(title: Text('جاري تحميل بيانات الموعد...')),
          );
        }

        final String patientName = snapshot.data!['patientName']!;
        final String patientPhone = snapshot.data!['patientPhone']!;
        final String doctorName = snapshot.data!['doctorName']!;

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.blue,
            ),
            title: Text(patientName),
            subtitle: Text(
              '${showDoctorName ? 'الطبيب: د. $doctorName\n' : ''}'
              'الهاتف: $patientPhone\n'
              'التاريخ: ${_formatDateTime(date)}\n'
              'الوقت: ${time.isEmpty ? 'غير محدد' : time}',
            ),
          ),
        );
      },
    );
  }

  Widget _appointmentsStream({
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required bool showDoctorName,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, appointmentsSnapshot) {
        if (!appointmentsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (appointmentsSnapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء تحميل المواعيد'));
        }

        final appointments = [...appointmentsSnapshot.data!.docs]
          ..sort((a, b) {
            final Timestamp? aTs = a.data()['date'] as Timestamp?;
            final Timestamp? bTs = b.data()['date'] as Timestamp?;
            final DateTime aDate = aTs?.toDate() ?? DateTime(1970);
            final DateTime bDate = bTs?.toDate() ?? DateTime(1970);
            return aDate.compareTo(bDate);
          });
        if (appointments.isEmpty) {
          return const Center(child: Text('لا يوجد'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return _appointmentCard(
              appointment: appointments[index].data(),
              showDoctorName: showDoctorName,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? doctorEmail = FirebaseAuth.instance.currentUser?.email;

    if (doctorEmail == null || doctorEmail.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة المواعيد')),
        body: const Center(
          child: Text('يرجى تسجيل الدخول كطبيب لعرض المواعيد'),
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

          return _appointmentsStream(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctorId', isEqualTo: doctorDocId)
                .snapshots(),
            showDoctorName: false,
          );
        },
      ),
    );
  }
}
