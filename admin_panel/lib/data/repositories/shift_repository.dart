import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

class ShiftRepository {
  final _shifts = FirebaseFirestore.instance.collection(FirestoreCollections.shifts);

  Stream<List<Shift>> streamAll() {
    return _shifts.orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => Shift.fromJson(d.id, d.data())).toList(),
        );
  }

  Future<void> create(Shift shift) async {
    await _shifts.add(shift.toJson());
  }

  Future<void> update(Shift shift) async {
    await _shifts.doc(shift.id).set(shift.toJson());
  }

  Future<void> setActive(String shiftId, bool isActive) async {
    await _shifts.doc(shiftId).update({'isActive': isActive});
  }
}
