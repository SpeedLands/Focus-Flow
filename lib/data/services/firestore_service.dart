import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      debugPrint('Error agregando documento: $e');
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>> getCollectionReference(
    String collectionName,
  ) {
    return _firestore.collection(collectionName);
  }

  Future<String?> addDocumentToSubcollection({
    required String parentCollectionName,
    required String subCollectionName,
    required Map<String, dynamic> data,
    required String documentId,
  }) async {
    if (parentCollectionName.isEmpty ||
        subCollectionName.isEmpty ||
        documentId.isEmpty) {
      debugPrint(
        'Error: Nombres de colección/subcolección o ID de documento no pueden estar vacíos.',
      );
      return null;
    }
    if (data.isEmpty) {
      debugPrint('Error: Los datos para el documento no pueden estar vacíos.');
      return null;
    }

    try {
      final CollectionReference subCollectionRef = FirebaseFirestore.instance
          .collection(parentCollectionName)
          .doc(documentId)
          .collection(subCollectionName);

      final DocumentReference docRef = await subCollectionRef.add(data);

      debugPrint(
        "Documento añadido con ID: ${docRef.id} a la subcolección '$parentCollectionName/$documentId/$subCollectionName'",
      );
      return docRef.id;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        "Error de Firebase al agregar documento a '$parentCollectionName/$documentId/$subCollectionName': ${e.message} (Código: ${e.code})\nStackTrace: $stackTrace",
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        "Error inesperado al agregar documento a '$parentCollectionName/$documentId/$subCollectionName': $e\nStackTrace: $stackTrace",
      );
      return null;
    }
  }

  Future<void> setDocument(
    String documentId,
    String collection,
    Map<String, dynamic> data,
    SetOptions? options,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, options);
    } catch (e) {
      debugPrint('Error estableciendo documento: $e');
      return;
    }
  }

  Future<DocumentSnapshot?> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      debugPrint('Error obteniendo documento: $e');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>?> getDocumentsWhere({
    required String collectionName,
    required String field,
    required dynamic isEqualToValue,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(collectionName)
          .where(field, isEqualTo: isEqualToValue);
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      final querySnapshot = await query.get();
      return querySnapshot.docs;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'FirebaseException en getDocumentsWhere ($collectionName where $field == $isEqualToValue): ${e.message} (Code: ${e.code})\nStackTrace: $stackTrace',
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        'Error inesperado en getDocumentsWhere ($collectionName where $field == $isEqualToValue): $e\nStackTrace: $stackTrace',
      );
      return null;
    }
  }

  Future<int> getCount({
    required String collectionName,
    required String subCollectionName,
    required String id,
  }) async {
    final query = await _firestore
        .collection(collectionName)
        .doc(id)
        .collection(subCollectionName)
        .count()
        .get();
    return query.count ?? 0;
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
      debugPrint('Error actualizando documento: $e');
      return false;
    }
  }

  Future<bool> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint('Error eliminando documento: $e');
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
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

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
            // Hacemos el cast a una variable local.
            final valueList = filter.value as List?;
            if (valueList != null && valueList.isNotEmpty) {
              if (valueList.length <= 30) {
                // Ahora pasamos la variable local fuertemente tipada.
                query = query.where(filter.field, arrayContainsAny: valueList);
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
            final valueList = filter.value as List?;
            if (valueList != null && valueList.isNotEmpty) {
              if (valueList.length <= 30) {
                query = query.where(filter.field, whereIn: valueList);
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
            final valueList = filter.value as List?;
            if (valueList != null && valueList.isNotEmpty) {
              if (valueList.length <= 10) {
                query = query.where(filter.field, whereNotIn: valueList);
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
