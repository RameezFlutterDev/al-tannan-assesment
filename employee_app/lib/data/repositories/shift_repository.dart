import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

class ShiftRepository {
  final _shifts = FirebaseFirestore.instance.collection(FirestoreCollections.shifts);

  Future<Shift?> getById(String shiftId) async {
    final doc = await _shifts.doc(shiftId).get();
    if (!doc.exists) return null;
    return Shift.fromJson(doc.id, doc.data()!);
  }
}
