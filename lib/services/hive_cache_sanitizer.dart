import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts Firestore-specific values into types that Hive can store
/// natively. [Timestamp] becomes [DateTime]; nested maps and lists are
/// converted recursively so cached documents never contain values Hive
/// cannot serialize.
Object? sanitizeForHive(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), sanitizeForHive(item)),
    );
  }
  if (value is Iterable) {
    return value.map(sanitizeForHive).toList();
  }
  return value;
}

/// Sanitizes a Firestore document data map for Hive storage.
Map<String, dynamic> sanitizeMapForHive(Map<String, dynamic> data) {
  return sanitizeForHive(data) as Map<String, dynamic>;
}
