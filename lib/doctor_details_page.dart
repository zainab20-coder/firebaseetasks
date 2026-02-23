import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'appointment_booking_page.dart';

class DoctorDetailsPage extends StatelessWidget {
  final String doctorId;
  const DoctorDetailsPage({super.key, required this.doctorId});

  Future<DocumentSnapshot> getDoctorDetails() {
    return FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بيانات الطبيب")),
      body: FutureBuilder<DocumentSnapshot>(
        future: getDoctorDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("حدث خطأ أثناء تحميل بيانات الطبيب"),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("بيانات الطبيب غير متاحة"));
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(Icons.person, size: 100, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                Text(
                  "الاسم: ${data['name'] ?? 'غير متاح'}",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  "التخصص: ${data['specialization'] ?? 'غير متاح'}",
                  style: const TextStyle(fontSize: 18),
                ),
                if ((data['experience'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "الخبرة: ${data['experience']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
                if ((data['phone'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "الهاتف: ${data['phone']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
                if ((data['email'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "البريد الإلكتروني: ${data['email']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AppointmentBookingPage(doctorId: doctorId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('حجز موعد'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
