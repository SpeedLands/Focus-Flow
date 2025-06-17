import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/data/services/firestore_service.dart';

class ProjectProvider {
  final FirestoreService _firestoreService;
  final String _collectionName = "projects";

  ProjectProvider(this._firestoreService);

  Future<String?> addProject(ProjectModel project) async {
    try {
      final now = Timestamp.now();
      final projectData = project.copyWith(updatedAt: now).toJson();

      return await _firestoreService.addDocument(_collectionName, projectData);
    } catch (e) {
      debugPrint("Error agregando proyecto: $e");
      return null;
    }
  }

  Future<bool> updateProject(ProjectModel project) async {
    if (project.id == null) {
      debugPrint("Error: ID del proyecto no puede ser nulo para actualizar.");
      return false;
    }
    try {
      final projectData = project.copyWith(updatedAt: Timestamp.now()).toJson();
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

  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      final doc = await _firestoreService.getDocument(
        _collectionName,
        projectId,
      );
      if (doc != null && doc.exists) {
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

  Future<bool> deleteProject(String projectId) async {
    try {
      return await _firestoreService.deleteDocument(_collectionName, projectId);
    } catch (e) {
      debugPrint("Error eliminando proyecto $projectId: $e");
      return false;
    }
  }

  Stream<List<ProjectModel>> getProjectsByUserStream(
    String userId, {
    String orderByField = 'createdAt',
    bool descending = true,
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
            return ProjectModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
        })
        .handleError((error) {
          debugPrint(
            "Error en stream de proyectos para usuario $userId: $error",
          );
          return <ProjectModel>[];
        });
  }

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
