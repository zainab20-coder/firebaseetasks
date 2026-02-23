import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_details_page.dart';

class DoctorsPage extends StatelessWidget {
  const DoctorsPage({super.key});

  Stream<QuerySnapshot> getDoctors() {
    return FirebaseFirestore.instance.collection('doctors').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("قائمة الأطباء")),
      body: StreamBuilder<QuerySnapshot>(
        stream: getDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ أثناء تحميل الأطباء"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا يوجد أطباء حاليًا"));
          }

          final doctors = snapshot.data!.docs.where((doc) {
            if (doc.id == '__schema__') return false;
            final data = doc.data() as Map<String, dynamic>;
            return data['hidden'] != true;
          }).toList();

          if (doctors.isEmpty) {
            return const Center(child: Text("لا يوجد أطباء حاليًا"));
          }

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              var doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DoctorDetailsPage(doctorId: doctor.id),
                      ),
                    );
                  },
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(doctor['name']),
                  subtitle: Text("التخصص: ${doctor['specialization']}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
