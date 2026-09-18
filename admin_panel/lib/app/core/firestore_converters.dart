import 'package:cloud_firestore/cloud_firestore.dart';


Map<String, dynamic> withDateTimes(Map<String, dynamic> data) {
  return data.map((key, value) => MapEntry(key, _convert(value)));
}

dynamic _convert(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is Map<String, dynamic>) return withDateTimes(value);
  if (value is List) return value.map(_convert).toList();
  return value;
}
