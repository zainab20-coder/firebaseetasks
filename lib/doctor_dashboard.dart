import 'package:firebaseetasks/doctors_list.dart';
import 'package:flutter/material.dart';
import 'upcoming_appointments_page.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("لوحة تحكم الطبيب")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorsPage()),
                );
              },
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text("عرض قائمة الأطباء"),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const UpcomingAppointmentsPage(patientId: ''),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: const Text("عرض المواعيد"),
            ),
          ],
        ),
      ),
    );
  }
}
