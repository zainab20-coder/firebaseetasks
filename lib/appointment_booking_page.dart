import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentBookingPage extends StatefulWidget {
  final String doctorId;

  const AppointmentBookingPage({super.key, required this.doctorId});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  String? selectedSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("حجز موعد")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .collection('slots')
            .where('isBooked', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var slots = snapshot.data!.docs;
          if (slots.isEmpty) {
            return const Center(child: Text('لا توجد مواعيد متاحة حاليًا'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    var slot = slots[index];
                    return ListTile(
                      title: Text("الوقت: ${slot['time']}"),
                      trailing: Radio<String>(
                        value: slot.id,
                        groupValue: selectedSlot,
                        onChanged: (value) {
                          setState(() {
                            selectedSlot = value;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedSlot != null) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .add({
                            'doctorId': widget.doctorId,
                            'patientId': user.uid,
                            'slotId': selectedSlot,
                            'status': 'upcoming',
                          });

                      await FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(widget.doctorId)
                          .collection('slots')
                          .doc(selectedSlot)
                          .update({'isBooked': true});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم حجز الموعد بنجاح")),
                      );

                      Navigator.pop(context);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("يرجى اختيار موعد أولاً")),
                    );
                  }
                },
                child: const Text("تأكيد الحجز"),
              ),
            ],
          );
        },
      ),
    );
  }
}
