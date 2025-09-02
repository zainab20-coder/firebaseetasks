import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebaseetasks/doctor_details_page.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<QuerySnapshot> getDoctors() {
    return FirebaseFirestore.instance.collection('doctors').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon doctor (بديل الصورة)
              Icon(
                Icons.medical_services_outlined,
                size: 100,
                color: Colors.blueAccent,
              ),

              const SizedBox(height: 24),

              // Welcome Text
              const Text(
                'Welcome to DocNow',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // My Appointment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/appointments');
                  },
                  child: const Text('My Appointment'),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getDoctors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error loading doctors ❌"),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No doctors found 🩺"));
                    }

                    final doctors = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        var doctor = doctors[index];
                        return InkWell(
                          onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailsPage(doctorId: doctor.id)));
                          },
                          child: Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                              title: Text(doctor['name']),
                              subtitle: Text(
                                "Specialization: ${doctor['specialization']}",
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
