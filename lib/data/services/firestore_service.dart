import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentReference> addDocument(
    String collection, Map<String, dynamic> data,
  ) => _db.collection(collection).add(data);

  Future<void> setDocument(
    String collection, String docId, Map<String, dynamic> data,
  ) => _db.collection(collection).doc(docId).set(data);

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection, String docId,
  ) => _db.collection(collection).doc(docId).get();

  Future<QuerySnapshot<Map<String, dynamic>>> queryWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
    String? orderBy,
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> q =
        _db.collection(collection).where(field, isEqualTo: isEqualTo);
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit   != null) q = q.limit(limit);
    return q.get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
    String? orderBy,
    bool descending = true,
  }) {
    Query<Map<String, dynamic>> q =
        _db.collection(collection).where(field, isEqualTo: isEqualTo);
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    return q.snapshots();
  }

  Future<void> updateDocument(
    String collection, String docId, Map<String, dynamic> data,
  ) => _db.collection(collection).doc(docId).update(data);

  Future<void> deleteDocument(String collection, String docId) =>
      _db.collection(collection).doc(docId).delete();

  Future<int> countWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
  }) async {
    final snap = await _db
        .collection(collection)
        .where(field, isEqualTo: isEqualTo)
        .count()
        .get();
    return snap.count ?? 0;
  }
}