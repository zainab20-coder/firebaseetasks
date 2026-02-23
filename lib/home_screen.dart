import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebaseetasks/doctor_details_page.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> getDoctors() {
    return FirebaseFirestore.instance.collection('doctors').snapshots();
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.medical_services_outlined, size: 42),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'مرحبًا بك في DocNow\nاختر طبيبًا لحجز موعدك القادم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/appointments');
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('مواعيدي'),
            ),
            const SizedBox(height: 12),
            const Text(
              'الأطباء المتاحون',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = _normalize(value);
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن طبيب أو اختصاص',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: getDoctors(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('حدث خطأ أثناء تحميل الأطباء'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا يوجد أطباء حاليًا'));
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                  doctors = snapshot.data!.docs.where((doc) {
                    if (doc.id == '__schema__') return false;
                    final Map<String, dynamic> data = doc.data();
                    return data['hidden'] != true;
                  }).toList();

                  if (doctors.isEmpty) {
                    return const Center(child: Text('لا يوجد أطباء حاليًا'));
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                  filteredDoctors = doctors.where((doctor) {
                    final Map<String, dynamic> data = doctor.data();
                    final String doctorName = (data['name'] ?? '').toString();
                    final String specialization = (data['specialization'] ?? '')
                        .toString();

                    if (_searchQuery.isEmpty) {
                      return true;
                    }

                    return _normalize(doctorName).contains(_searchQuery) ||
                        _normalize(specialization).contains(_searchQuery);
                  }).toList();

                  if (filteredDoctors.isEmpty) {
                    return const Center(
                      child: Text('لا يوجد أطباء مطابقون للبحث'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final QueryDocumentSnapshot<Map<String, dynamic>> doctor =
                          filteredDoctors[index];
                      final Map<String, dynamic> data = doctor.data();
                      final String doctorName = (data['name'] ?? 'طبيب')
                          .toString();
                      final String specialization =
                          (data['specialization'] ?? 'غير محدد').toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DoctorDetailsPage(doctorId: doctor.id),
                            ),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.blue,
                            ),
                            title: Text(doctorName),
                            subtitle: Text('التخصص: $specialization'),
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
    );
  }
}
