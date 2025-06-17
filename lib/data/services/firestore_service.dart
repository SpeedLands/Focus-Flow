import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

// Enum para los operadores de consulta comunes
enum FilterOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny, // Para cuando el valor es una lista y quieres documentos donde el campo (que es un array) contenga CUALQUIERA de los valores de la lista.
  whereIn, // Para cuando el valor es una lista y quieres documentos donde el campo coincida con CUALQUIERA de los valores de la lista.
  whereNotIn, // Para cuando el valor es una lista y quieres documentos donde el campo NO coincida con NINGUNO de los valores de la lista.
  // isNull se maneja con isEqualTo: null o isNotEqualTo: null
}

// Clase para representar una condición de filtro
class QueryFilter {
  final String field; // El campo del documento por el cual filtrar
  final FilterOperator operator; // El operador de comparación
  final dynamic
  value; // El valor a comparar. Puede ser null para isEqualTo: null

  QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Agregar documento a cualquier colección
  Future<String?> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      debugPrint("Error agregando documento: $e"); // Es bueno loguear el error
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

  // Obtener documento por ID de cualquier colección
  Future<DocumentSnapshot?> getDocument(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      debugPrint("Error obteniendo documento: $e");
      return null;
    }
  }

  // Actualizar documento en cualquier colección
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

  // Eliminar documento en cualquier colección
  Future<bool> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint("Error eliminando documento: $e");
      return false;
    }
  }

  // Escuchar cambios en cualquier colección (sin filtros)
  Stream<QuerySnapshot> listenToCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // NUEVO MÉTODO: Escuchar cambios en cualquier colección CON FILTROS
  Stream<QuerySnapshot> listenToCollectionFiltered(
    String collectionPath, {
    List<QueryFilter>? filters, // Lista de filtros a aplicar (opcional)
    String? orderByField, // Campo por el cual ordenar (opcional)
    bool descending = false, // Dirección de ordenamiento (opcional)
    int? limit, // Limitar el número de documentos (opcional)
  }) {
    Query query = _firestore.collection(collectionPath);

    // Aplicar filtros si existen
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
            // Asegurarse que el valor es una lista y no está vacía
            if (filter.value is List && (filter.value as List).isNotEmpty) {
              // Firestore 'array-contains-any' soporta hasta 30 valores en la lista
              if ((filter.value as List).length <= 30) {
                query = query.where(
                  filter.field,
                  arrayContainsAny: filter.value,
                );
              } else {
                debugPrint(
                  "Advertencia: 'arrayContainsAny' para el campo '${filter.field}' excede el límite de 30 elementos. El filtro podría no funcionar como se espera o Firestore podría rechazar la consulta.",
                );
                // Aquí podrías optar por no aplicar el filtro o lanzar una excepción
              }
            } else {
              debugPrint(
                "Advertencia: 'arrayContainsAny' espera una Lista no vacía como valor para el campo '${filter.field}'.",
              );
            }
            break;
          case FilterOperator.whereIn:
            // Asegurarse que el valor es una lista y no está vacía
            if (filter.value is List && (filter.value as List).isNotEmpty) {
              // Firestore 'in' soporta hasta 30 valores en la lista
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
            // Asegurarse que el valor es una lista y no está vacía
            if (filter.value is List && (filter.value as List).isNotEmpty) {
              // Firestore 'not-in' soporta hasta 10 valores en la lista
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

    // Aplicar ordenamiento si se especifica
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    // Aplicar límite si se especifica
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }
}
