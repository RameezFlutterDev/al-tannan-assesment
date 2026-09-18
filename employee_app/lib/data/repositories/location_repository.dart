import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/shared.dart';

class LocationRepository {
  final _locations =
      FirebaseFirestore.instance.collection(FirestoreCollections.locations);

  Future<WorkLocation?> getById(String locationId) async {
    final doc = await _locations.doc(locationId).get();
    if (!doc.exists) return null;
    return WorkLocation.fromJson(doc.id, doc.data()!);
  }
}
