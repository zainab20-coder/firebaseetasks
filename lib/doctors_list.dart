import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_doctor_page.dart'; // تأكدي مسار الصفحة صحيح

class DoctorsPage extends StatelessWidget {
  const DoctorsPage({super.key});

  Stream<QuerySnapshot> getDoctors() {
    return FirebaseFirestore.instance.collection('doctors').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctors List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddDoctorPage()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading doctors ❌"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No doctors found 🩺"));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              var doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(doctor['name']),
                  subtitle: Text("Specialization: ${doctor['specialization']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
