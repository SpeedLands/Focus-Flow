import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_flow/data/models/task_model.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';
import 'package:focus_flow/data/services/firestore_service.dart';

class TaskProvider {
  final FirestoreService _firestoreService;
  final AuthProviderApp _authProviderApp;

  TaskProvider(this._firestoreService, this._authProviderApp);

  String get _projectsCollection => "projects";
  String get _tasksSubcollection => "tasks";

  Future<bool> _isUserMember(String userId, ProjectModel project) {
    return Future.value(
      project.userRoles.any((role) => role.startsWith('$userId:')),
    );
  }

  Future<ProjectModel?> _getProject(String projectId) async {
    final doc = await _firestoreService.getDocument(
      _projectsCollection,
      projectId,
    );
    if (doc != null && doc.exists) {
      return ProjectModel.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    return null;
  }

  Future<String?> addTask(String projectId, TaskModel task) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null || projectId.isEmpty) return null;

    final project = await _getProject(projectId);
    if (project == null || !(await _isUserMember(currentUser.uid, project))) {
      throw Exception("No autorizado");
    }

    final taskData = task.copyWith(
      projectId: projectId,
      createdBy: currentUser.uid,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    return await _firestoreService.addDocumentToSubcollection(
      parentCollectionName: _projectsCollection,
      subCollectionName: _tasksSubcollection,
      documentId: projectId,
      data: taskData.toJson(),
    );
  }

  Stream<List<TaskModel>> getTasksStream(String projectId) {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null || projectId.isEmpty) return Stream.value([]);

    return _firestoreService
        .listenToCollectionFiltered(
          '$_projectsCollection/$projectId/$_tasksSubcollection',
          orderByField: 'createdAt',
        )
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TaskModel.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  Future<int> getPendingTasksCount(String projectId) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null || projectId.isEmpty) return 0;

    // Usamos .count() para una consulta eficiente sin descargar los documentos
    final aggregateQuery = await _firestoreService
        .getCollectionReference(
          '$_projectsCollection/$projectId/$_tasksSubcollection',
        )
        .where('isCompleted', isEqualTo: false)
        .count()
        .get();

    return aggregateQuery.count ?? 0;
  }

  Future<void> updateTaskDetails(TaskModel task) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null || task.id == null) return;

    final project = await _getProject(task.projectId);
    if (project == null || project.adminUserId != currentUser.uid) {
      throw Exception("Solo el admin puede editar detalles");
    }

    final updated = task.copyWith(updatedAt: Timestamp.now());

    await _firestoreService.updateDocument(
      '$_projectsCollection/${task.projectId}/$_tasksSubcollection',
      task.id!,
      updated.toJson(),
    );
  }

  Future<void> toggleTaskCompletion(
    String projectId,
    String taskId,
    bool isCompleted,
  ) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return;

    final project = await _getProject(projectId);
    if (project == null || !(await _isUserMember(currentUser.uid, project))) {
      throw Exception("No autorizado");
    }

    final updateData = {
      'isCompleted': isCompleted,
      'updatedAt': Timestamp.now(),
      'completedBy': isCompleted ? currentUser.uid : FieldValue.delete(),
      'completedAt': isCompleted ? Timestamp.now() : FieldValue.delete(),
    };

    await _firestoreService.updateDocument(
      '$_projectsCollection/$projectId/$_tasksSubcollection',
      taskId,
      updateData,
    );
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return;

    final project = await _getProject(projectId);
    if (project == null || project.adminUserId != currentUser.uid) {
      throw Exception("No autorizado");
    }

    await _firestoreService.deleteDocument(
      '$_projectsCollection/$projectId/$_tasksSubcollection',
      taskId,
    );
  }

  Future<void> deleteAllTasksForProject(String projectId) async {
    final snapshot = await _firestoreService.getDocumentsWhere(
      collectionName: '$_projectsCollection/$projectId/$_tasksSubcollection',
      field: 'projectId',
      isEqualToValue: projectId,
    );

    if (snapshot == null || snapshot.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteAllTasksFromProjectWithBatch(
    String projectId,
    WriteBatch batch,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('projects/$projectId/tasks')
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
  }

  Future<TaskModel?> getTaskById(String projectId, String taskId) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return null;

    final project = await _getProject(projectId);
    if (project == null || !(await _isUserMember(currentUser.uid, project))) {
      return null;
    }

    final doc = await _firestoreService.getDocument(
      '$_projectsCollection/$projectId/$_tasksSubcollection',
      taskId,
    );
    if (doc != null && doc.exists) {
      return TaskModel.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    return null;
  }
}
