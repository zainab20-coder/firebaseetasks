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
        .snapshots();
  }

  String _formatDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}/$month/$day - $hour:$minute';
  }

  bool _canCancelAppointment(DateTime appointmentDate, {DateTime? now}) {
    final DateTime referenceNow = now ?? DateTime.now();
    return appointmentDate.difference(referenceNow) >= const Duration(hours: 6);
  }

  Future<void> _cancelAppointment({
    required BuildContext context,
    required DocumentReference<Map<String, dynamic>> appointmentRef,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(appointmentRef);

        if (!snapshot.exists) {
          throw StateError('APPOINTMENT_NOT_FOUND');
        }

        final Timestamp? dateTs = snapshot.data()?['date'] as Timestamp?;
        final DateTime? appointmentDate = dateTs?.toDate();
        if (appointmentDate == null) {
          throw StateError('INVALID_APPOINTMENT_DATE');
        }

        if (!_canCancelAppointment(appointmentDate)) {
          throw StateError('CANCEL_WINDOW_CLOSED');
        }

        transaction.delete(appointmentRef);
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح')));
    } catch (e) {
      if (!context.mounted) return;
      final String error = e.toString();
      String message = 'تعذر إلغاء الحجز، حاول مرة أخرى';

      if (error.contains('CANCEL_WINDOW_CLOSED')) {
        message = 'لا يمكن إلغاء الموعد قبل أقل من 6 ساعات من وقت الموعد';
      } else if (error.contains('APPOINTMENT_NOT_FOUND')) {
        message = 'الموعد غير موجود أو تم التعامل معه مسبقًا';
      } else if (error.contains('INVALID_APPOINTMENT_DATE')) {
        message = 'بيانات الموعد غير صالحة';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _onCancelPressed({
    required BuildContext context,
    required DocumentReference<Map<String, dynamic>> appointmentRef,
    required DateTime appointmentDate,
  }) async {
    if (!_canCancelAppointment(appointmentDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن إلغاء الموعد قبل أقل من 6 ساعات من وقت الموعد',
          ),
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الإلغاء'),
          content: const Text('هل تريد إلغاء هذا الموعد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إلغاء الحجز'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    if (!context.mounted) return;
    await _cancelAppointment(context: context, appointmentRef: appointmentRef);
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = patientId ?? FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('مواعيدي')),
        body: const Center(child: Text('يرجى تسجيل الدخول لعرض المواعيد')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('مواعيدي')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getAppointments(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء تحميل المواعيد'));
          }

          final appointments = [...snapshot.data!.docs]
            ..sort((a, b) {
              final Timestamp? aTs = a.data()['date'] as Timestamp?;
              final Timestamp? bTs = b.data()['date'] as Timestamp?;
              final DateTime aDate = aTs?.toDate() ?? DateTime(1970);
              final DateTime bDate = bTs?.toDate() ?? DateTime(1970);
              return aDate.compareTo(bDate);
            });

          if (appointments.isEmpty) {
            return const Center(child: Text('لا توجد مواعيد'));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data();
              final String doctorId = (data['doctorId'] ?? '').toString();
              final Timestamp? dateTs = data['date'] as Timestamp?;
              final DateTime date = dateTs?.toDate() ?? DateTime.now();
              final bool canCancel = _canCancelAppointment(date);
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
                      title: Text('جاري تحميل بيانات الطبيب...'),
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
                        'الوقت: $time\n'
                        '${canCancel ? 'متاح الإلغاء (قبل الموعد بـ 6 ساعات على الأقل)' : 'الإلغاء غير متاح: تبقّى أقل من 6 ساعات'}',
                      ),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: canCancel
                            ? () => _onCancelPressed(
                                context: context,
                                appointmentRef: appointment.reference,
                                appointmentDate: date,
                              )
                            : null,
                        child: const Text('إلغاء'),
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
