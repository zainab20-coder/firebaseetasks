import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBootstrapService {
  static const String _schemaId = '__schema__';

  static Future<void> restoreBaseCollections({
    required String uid,
    required String email,
    required bool isDoctor,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await Future.wait([
      _ensureSchemaDocs(firestore),
      _ensureUserProfile(
        firestore: firestore,
        uid: uid,
        email: email,
        isDoctor: isDoctor,
      ),
    ]);
  }

  static Future<void> _ensureSchemaDocs(FirebaseFirestore firestore) async {
    final WriteBatch batch = firestore.batch();

    batch.set(firestore.collection('patients').doc(_schemaId), {
      'uid': _schemaId,
      'name': 'schema',
      'email': '',
      'phone': '',
      'hidden': true,
      'isSchema': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(firestore.collection('doctors').doc(_schemaId), {
      'name': 'schema',
      'specialization': 'schema',
      'email': '',
      'phone': '',
      'workingHoursStart': '09:00',
      'workingHoursEnd': '17:00',
      'slotDurationMinutes': 30,
      'hidden': true,
      'isSchema': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(firestore.collection('appointments').doc(_schemaId), {
      'doctorId': _schemaId,
      'patientId': _schemaId,
      'patientName': 'schema',
      'patientPhone': '',
      'date': Timestamp.fromDate(DateTime(2000, 1, 1)),
      'dateKey': '2000-01-01',
      'time': '00:00',
      'status': 'schema',
      'hidden': true,
      'isSchema': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(
      firestore
          .collection('doctors')
          .doc(_schemaId)
          .collection('slots')
          .doc(_schemaId),
      {
        'time': '00:00',
        'isBooked': false,
        'hidden': true,
        'isSchema': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static Future<void> _ensureUserProfile({
    required FirebaseFirestore firestore,
    required String uid,
    required String email,
    required bool isDoctor,
  }) async {
    if (isDoctor) {
      final QuerySnapshot<Map<String, dynamic>> doctorQuery = await firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (doctorQuery.docs.isEmpty) {
        await firestore.collection('doctors').doc(uid).set({
          'name': 'طبيب جديد',
          'specialization': 'عام',
          'email': email,
          'phone': '',
          'workingHoursStart': '09:00',
          'workingHoursEnd': '17:00',
          'slotDurationMinutes': 30,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return;
    }

    await firestore.collection('patients').doc(uid).set({
      'uid': uid,
      'name': 'مريض',
      'email': email,
      'phone': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
