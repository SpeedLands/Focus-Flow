// lib/providers/project_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/data/services/firestore_service.dart';

class ProjectProvider {
  final FirestoreService _firestoreService;
  final String _collectionName =
      "projects"; // Nombre de la colección en Firestore

  ProjectProvider(this._firestoreService);

  /// Agrega un nuevo proyecto y devuelve su ID.
  /// createdAt y updatedAt se manejan aquí para asegurar que estén presentes.
  Future<String?> addProject(ProjectModel project) async {
    try {
      final now = Timestamp.now();
      // Aseguramos que createdAt y updatedAt se establezcan/actualicen
      // El modelo ya tiene createdAt como required.
      // Aquí actualizamos updatedAt al momento de la creación/modificación.
      final projectData = project
          .copyWith(
            // createdAt es required en el modelo, así que ya debería estar.
            // Si quieres forzarlo aquí, puedes hacerlo:
            // createdAt: project.createdAt, // o now si es un nuevo proyecto
            updatedAt: now,
          )
          .toJson();

      // El ID se genera automáticamente por Firestore al usar addDocument
      // y el modelo no lo incluye en toJson, lo cual es correcto.
      return await _firestoreService.addDocument(_collectionName, projectData);
    } catch (e) {
      debugPrint("Error agregando proyecto: $e");
      return null;
    }
  }

  /// Actualiza un proyecto existente.
  Future<bool> updateProject(ProjectModel project) async {
    if (project.id == null) {
      debugPrint("Error: ID del proyecto no puede ser nulo para actualizar.");
      return false;
    }
    try {
      final projectData = project.copyWith(updatedAt: Timestamp.now()).toJson();
      // toJson no incluye el ID, lo cual es correcto para los datos del documento.
      return await _firestoreService.updateDocument(
        _collectionName,
        project.id!,
        projectData,
      );
    } catch (e) {
      debugPrint("Error actualizando proyecto ${project.id}: $e");
      return false;
    }
  }

  /// Obtiene un proyecto por su ID.
  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      final doc = await _firestoreService.getDocument(
        _collectionName,
        projectId,
      );
      if (doc != null && doc.exists) {
        // Aseguramos el cast correcto para el factory constructor
        return ProjectModel.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
      }
      return null;
    } catch (e) {
      debugPrint("Error obteniendo proyecto $projectId: $e");
      return null;
    }
  }

  /// Elimina un proyecto por su ID.
  Future<bool> deleteProject(String projectId) async {
    try {
      return await _firestoreService.deleteDocument(_collectionName, projectId);
    } catch (e) {
      debugPrint("Error eliminando proyecto $projectId: $e");
      return false;
    }
  }

  /// Escucha todos los proyectos de un usuario específico, ordenados opcionalmente.
  Stream<List<ProjectModel>> getProjectsByUserStream(
    String userId, {
    String orderByField = 'createdAt', // Campo por defecto para ordenar
    bool descending =
        true, // Orden descendente por defecto (más nuevos primero)
  }) {
    return _firestoreService
        .listenToCollectionFiltered(
          _collectionName,
          filters: [
            QueryFilter(
              field: 'userId',
              operator: FilterOperator.isEqualTo,
              value: userId,
            ),
          ],
          orderByField: orderByField,
          descending: descending,
        )
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Aseguramos el cast correcto para el factory constructor
            return ProjectModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
        })
        .handleError((error) {
          // Es buena práctica manejar errores en el stream
          debugPrint(
            "Error en stream de proyectos para usuario $userId: $error",
          );
          return <
            ProjectModel
          >[]; // Devuelve lista vacía en caso de error o maneja de otra forma
        });
  }

  /// Obtiene todos los proyectos (sin filtro de usuario, útil para admin o tests).
  /// Cuidado con el volumen de datos si tienes muchos proyectos.
  Stream<List<ProjectModel>> getAllProjectsStream({
    String orderByField = 'createdAt',
    bool descending = true,
  }) {
    return _firestoreService
        .listenToCollectionFiltered(
          _collectionName,
          orderByField: orderByField,
          descending: descending,
        )
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProjectModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
        })
        .handleError((error) {
          debugPrint("Error en stream de todos los proyectos: $error");
          return <ProjectModel>[];
        });
  }
}
