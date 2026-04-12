import 'package:cloud_firestore/cloud_firestore.dart';
 
class FireStoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
 
  Future<DocumentReference> addDocument(
    String collection, Map<String, dynamic> data,
  ) => db.collection(collection).add(data);
 
  Future<void> setDocument(
    String collection, String docId, Map<String, dynamic> data,
  ) => db.collection(collection).doc(docId).set(data);
 
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection, String docId,
  ) => db.collection(collection).doc(docId).get();
 
  Future<QuerySnapshot<Map<String, dynamic>>> queryWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
    String? field2,
    dynamic isEqualTo2,
    String? orderBy,
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> q =
        db.collection(collection).where(field, isEqualTo: isEqualTo);
    if (field2 != null && isEqualTo2 != null) {
      q = q.where(field2, isEqualTo: isEqualTo2);
    }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit   != null) q = q.limit(limit);
    return q.get();
  }
 
  Stream<QuerySnapshot<Map<String, dynamic>>> streamWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
    String? field2,
    dynamic isEqualTo2,
    String? orderBy,
    bool descending = true,
  }) {
    Query<Map<String, dynamic>> q =
        db.collection(collection).where(field, isEqualTo: isEqualTo);
    if (field2 != null && isEqualTo2 != null) {
      q = q.where(field2, isEqualTo: isEqualTo2);
    }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    return q.snapshots();
  }
 
  Future<void> updateDocument(
    String collection, String docId, Map<String, dynamic> data,
  ) => db.collection(collection).doc(docId).update(data);
 
  Future<void> deleteDocument(String collection, String docId) =>
      db.collection(collection).doc(docId).delete();
 
  //Tăng/giảm một field số nguyên một cách atomic (an toàn khi nhiều user cùng lúc)
  //Dùng FieldValue.increment — không cần đọc giá trị hiện tại
  
  Future<void> incrementField(
    String collection,
    String docId, {
    required String field,
    required int delta,
  }) =>
      db.collection(collection).doc(docId).update({
        field: FieldValue.increment(delta),
      });
 
  Future<int> countWhere(
    String collection, {
    required String field,
    required dynamic isEqualTo,
    String? field2,
    dynamic isEqualTo2,
  }) async {
    Query<Map<String, dynamic>> q =
        db.collection(collection).where(field, isEqualTo: isEqualTo);
    if (field2 != null && isEqualTo2 != null) {
      q = q.where(field2, isEqualTo: isEqualTo2);
    }
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

   Stream<QuerySnapshot<Map<String, dynamic>>> streamArrayContains(
    String collection, {
    required String field,
    required dynamic value,
  }) {
    return db
        .collection(collection)
        .where(field, arrayContains: value)
        .snapshots();
  }
}