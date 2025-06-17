import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<TaskModel> _tasksCollection(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .withConverter<TaskModel>(
          fromFirestore: (snapshots, _) => TaskModel.fromFirestore(snapshots),
          toFirestore: (task, _) => task.toJson(),
        );
  }

  String? get _currentUserId => _auth.currentUser?.uid;

  bool _isUserMember(ProjectModel project, String userId) {
    return project.userRoles.any(
      (roleEntry) => roleEntry.startsWith('$userId:'),
    );
  }

  Future<ProjectModel?> _getProjectModel(String projectId) async {
    final projectDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .withConverter<ProjectModel>(
          fromFirestore: (snap, _) => ProjectModel.fromFirestore(snap),
          toFirestore: (proj, _) => proj.toJson(),
        )
        .get();
    return projectDoc.data();
  }

  Future<void> deleteAllTasksForProject(String projectId) async {
    try {
      final QuerySnapshot tasksSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        debugPrint("No hay tareas que eliminar para el proyecto $projectId.");
        return;
      }

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint(
        "Todas las tareas del proyecto $projectId eliminadas exitosamente.",
      );
    } catch (e) {
      debugPrint("Error eliminando tareas del proyecto $projectId: $e");
      throw Exception("Error al eliminar tareas del proyecto: $e");
    }
  }

  Future<DocumentReference<TaskModel>?> addTask(
    String projectId,
    TaskModel taskDataFromController,
  ) async {
    final createdById = _currentUserId;
    if (createdById == null) {
      throw Exception("Usuario no autenticado para añadir tarea.");
    }
    if (projectId.isEmpty) {
      throw Exception("El ID del proyecto no puede estar vacío.");
    }

    final project = await _getProjectModel(projectId);
    if (project == null || !_isUserMember(project, createdById)) {
      throw Exception(
        "No eres miembro de este proyecto o el proyecto no existe.",
      );
    }

    final taskToAdd = taskDataFromController.copyWith(
      projectId: projectId,
      createdBy: createdById,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
    return _tasksCollection(projectId).add(taskToAdd);
  }

  Stream<List<TaskModel>> getTasksStream(String projectId) {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint(
        "TaskService: Usuario no autenticado, devolviendo stream de tareas vacío.",
      );
      return Stream.value([]);
    }
    if (projectId.isEmpty) {
      debugPrint("Advertencia: Se solicitó un stream de tareas sin projectId.");
      return Stream.value([]);
    }
    return _tasksCollection(projectId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          debugPrint(
            "Error en getTasksStream para proyecto $projectId: $error",
          );
          return <TaskModel>[];
        });
  }

  Future<void> updateTaskDetails(TaskModel task) async {
    final editorId = _currentUserId;
    if (editorId == null) throw Exception("Usuario no autenticado.");
    if (task.projectId.isEmpty || task.id == null) {
      throw Exception("ID de proyecto o tarea inválido.");
    }

    final project = await _getProjectModel(task.projectId);
    if (project == null || project.adminUserId != editorId) {
      throw Exception(
        "No tienes permisos (admin) para editar detalles de esta tarea.",
      );
    }

    final taskToUpdate = task.copyWith(updatedAt: Timestamp.now());
    return _tasksCollection(
      task.projectId,
    ).doc(task.id).update(taskToUpdate.toJson());
  }

  Future<void> toggleTaskCompletion(
    String projectId,
    String taskId,
    bool isCompleted,
  ) async {
    final completerId = _currentUserId;
    if (completerId == null) throw Exception("Usuario no autenticado.");
    if (projectId.isEmpty || taskId.isEmpty) {
      throw Exception("ID de proyecto o tarea inválido.");
    }

    final project = await _getProjectModel(projectId);
    if (project == null || !_isUserMember(project, completerId)) {
      throw Exception(
        "No eres miembro de este proyecto o el proyecto no existe.",
      );
    }

    final Map<String, dynamic> updateData = {
      'isCompleted': isCompleted,
      'updatedAt': Timestamp.now(),
    };
    if (isCompleted) {
      updateData['completedBy'] = completerId;
      updateData['completedAt'] = Timestamp.now();
    } else {
      updateData['completedBy'] = FieldValue.delete();
      updateData['completedAt'] = FieldValue.delete();
    }

    return _tasksCollection(projectId).doc(taskId).update(updateData);
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    final adminCandidateId = _currentUserId;
    if (adminCandidateId == null) throw Exception("Usuario no autenticado.");
    if (projectId.isEmpty || taskId.isEmpty) {
      throw Exception("ID de proyecto o tarea inválido.");
    }

    final project = await _getProjectModel(projectId);
    if (project == null || project.adminUserId != adminCandidateId) {
      throw Exception("No tienes permisos (admin) para eliminar esta tarea.");
    }

    return _tasksCollection(projectId).doc(taskId).delete();
  }

  Future<void> deleteAllTasksFromProjectWithBatch(
    String projectId,
    WriteBatch batch,
  ) async {
    if (projectId.isEmpty) {
      throw Exception(
        "El ID del proyecto no puede estar vacío para deleteAllTasksFromProjectWithBatch.",
      );
    }
    final tasksSnapshot = await _tasksCollection(projectId).get();
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    debugPrint(
      "TaskService: ${tasksSnapshot.docs.length} operaciones de eliminación de tareas añadidas al batch para proyecto $projectId.",
    );
  }

  Future<TaskModel?> getTaskById(String projectId, String taskId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    if (projectId.isEmpty || taskId.isEmpty) {
      throw Exception("ID de proyecto o tarea inválido.");
    }

    final project = await _getProjectModel(projectId);
    if (project == null || !_isUserMember(project, userId)) {
      debugPrint(
        "Usuario $userId no es miembro del proyecto $projectId o el proyecto no existe.",
      );
      return null;
    }

    final doc = await _tasksCollection(projectId).doc(taskId).get();
    return doc.data();
  }
}
