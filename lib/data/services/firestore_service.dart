import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

enum FilterOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      debugPrint("Error agregando documento: $e");
      return null;
    }
  }

  Future<void> setDocument(
    String documentId,
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(data);
    } catch (e) {
      debugPrint("Error estableciendo documento: $e");
      return;
    }
  }

  Future<DocumentSnapshot?> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      debugPrint("Error obteniendo documento: $e");
      return null;
    }
  }

  Future<bool> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
      return true;
    } catch (e) {
      debugPrint("Error actualizando documento: $e");
      return false;
    }
  }

  Future<bool> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint("Error eliminando documento: $e");
      return false;
    }
  }

  Stream<QuerySnapshot> listenToCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  Stream<QuerySnapshot> listenToCollectionFiltered(
    String collectionPath, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collectionPath);

    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        switch (filter.operator) {
          case FilterOperator.isEqualTo:
            query = query.where(filter.field, isEqualTo: filter.value);
            break;
          case FilterOperator.isNotEqualTo:
            query = query.where(filter.field, isNotEqualTo: filter.value);
            break;
          case FilterOperator.isLessThan:
            query = query.where(filter.field, isLessThan: filter.value);
            break;
          case FilterOperator.isLessThanOrEqualTo:
            query = query.where(
              filter.field,
              isLessThanOrEqualTo: filter.value,
            );
            break;
          case FilterOperator.isGreaterThan:
            query = query.where(filter.field, isGreaterThan: filter.value);
            break;
          case FilterOperator.isGreaterThanOrEqualTo:
            query = query.where(
              filter.field,
              isGreaterThanOrEqualTo: filter.value,
            );
            break;
          case FilterOperator.arrayContains:
            query = query.where(filter.field, arrayContains: filter.value);
            break;
          case FilterOperator.arrayContainsAny:
            if (filter.value is List && (filter.value as List).isNotEmpty) {
              if ((filter.value as List).length <= 30) {
                query = query.where(
                  filter.field,
                  arrayContainsAny: filter.value,
                );
              } else {
                debugPrint(
                  "Advertencia: 'arrayContainsAny' para el campo '${filter.field}' excede el límite de 30 elementos. El filtro podría no funcionar como se espera o Firestore podría rechazar la consulta.",
                );
              }
            } else {
              debugPrint(
                "Advertencia: 'arrayContainsAny' espera una Lista no vacía como valor para el campo '${filter.field}'.",
              );
            }
            break;
          case FilterOperator.whereIn:
            if (filter.value is List && (filter.value as List).isNotEmpty) {
              if ((filter.value as List).length <= 30) {
                query = query.where(filter.field, whereIn: filter.value);
              } else {
                debugPrint(
                  "Advertencia: 'whereIn' para el campo '${filter.field}' excede el límite de 30 elementos. El filtro podría no funcionar como se espera o Firestore podría rechazar la consulta.",
                );
              }
            } else {
              debugPrint(
                "Advertencia: 'whereIn' espera una Lista no vacía como valor para el campo '${filter.field}'.",
              );
            }
            break;
          case FilterOperator.whereNotIn:
            if (filter.value is List && (filter.value as List).isNotEmpty) {
              if ((filter.value as List).length <= 10) {
                query = query.where(filter.field, whereNotIn: filter.value);
              } else {
                debugPrint(
                  "Advertencia: 'whereNotIn' para el campo '${filter.field}' excede el límite de 10 elementos. El filtro podría no funcionar como se espera o Firestore podría rechazar la consulta.",
                );
              }
            } else {
              debugPrint(
                "Advertencia: 'whereNotIn' espera una Lista no vacía como valor para el campo '${filter.field}'.",
              );
            }
            break;
        }
      }
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }
}
