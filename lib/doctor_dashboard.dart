import 'package:firebaseetasks/doctors_list.dart';
import 'package:flutter/material.dart';
import 'add_slots_page.dart';
import 'appointment_booking_page.dart';
import 'upcoming_appointments_page.dart';
import 'doctor_details_page.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const UpcomingAppointmentsPage(patientId: ''),
                  ),
                );
              },
              child: const Text("View Appointments"),
            ),
          ],
        ),
      ),
    );
  }
}
