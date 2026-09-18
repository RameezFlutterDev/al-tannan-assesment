import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

class LocationRepository {
  final _locations =
      FirebaseFirestore.instance.collection(FirestoreCollections.locations);

  Stream<List<WorkLocation>> streamAll() {
    return _locations.orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => WorkLocation.fromJson(d.id, d.data())).toList(),
        );
  }

  Future<void> create(WorkLocation location) async {
    await _locations.add(location.toJson());
  }

  Future<void> update(WorkLocation location) async {
    await _locations.doc(location.id).set(location.toJson());
  }

  Future<void> setActive(String locationId, bool isActive) async {
    await _locations.doc(locationId).update({'isActive': isActive});
  }
}
