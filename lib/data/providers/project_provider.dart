import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_flow/data/models/project_model.dart';
import 'package:focus_flow/data/services/firestore_service.dart';
import 'package:focus_flow/data/providers/auth_app_provider.dart';

class ProjectProvider {
  final FirestoreService _firestoreService;
  final AuthProviderApp _authProviderApp;

  final String _collectionName = 'projects';

  ProjectProvider(this._firestoreService, this._authProviderApp);

  String _userRoleString(String userId, String role) => '$userId:$role';

  Future<String?> addProject(ProjectModel project) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return null;

    final now = Timestamp.now();
    final newProject = project.copyWith(
      adminUserId: currentUser.uid,
      userRoles: [_userRoleString(currentUser.uid, 'admin')],
      createdAt: now,
      updatedAt: now,
    );
    return await _firestoreService.addDocument(
      _collectionName,
      newProject.toJson(),
    );
  }

  Future<bool> updateProject(ProjectModel project) async {
    if (project.id == null) return false;

    final updatedProject = project.copyWith(updatedAt: Timestamp.now());
    return await _firestoreService.updateDocument(
      _collectionName,
      project.id!,
      updatedProject.toJson(),
    );
  }

  Future<ProjectModel?> getProjectById(String projectId) async {
    final doc = await _firestoreService.getDocument(_collectionName, projectId);
    if (doc != null && doc.exists) {
      return ProjectModel.fromFirestore(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    return null;
  }

  Future<bool> deleteProject(String projectId) async {
    return await _firestoreService.deleteDocument(_collectionName, projectId);
  }

  Stream<List<ProjectModel>> getProjectsStream() {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return const Stream.empty();

    final adminRole = _userRoleString(currentUser.uid, 'admin');
    final memberRole = _userRoleString(currentUser.uid, 'member');

    return _firestoreService
        .listenToCollectionFiltered(
          _collectionName,
          filters: [
            QueryFilter(
              field: 'userRoles',
              operator: FilterOperator.arrayContainsAny,
              value: [adminRole, memberRole],
            ),
          ],
          orderByField: 'createdAt',
          descending: true,
        )
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProjectModel.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  Future<String> generateAccessCode(String projectId) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return '';

    final doc = await getProjectById(projectId);
    if (doc == null || doc.adminUserId != currentUser.uid) {
      throw Exception('No tienes permisos para generar código.');
    }

    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random.secure();
    const int codeLength = 6;
    final String code = List.generate(
      codeLength,
      (_) => chars[random.nextInt(chars.length)],
    ).join();

    await _firestoreService.updateDocument(_collectionName, projectId, {
      'accessCode': code,
      'updatedAt': Timestamp.now(),
    });

    return code;
  }

  Future<ProjectModel?> joinProjectWithCode(String accessCode) async {
    final currentUser = _authProviderApp.currentUser;

    if (currentUser == null) {
      throw Exception('Usuario no autenticado. Inicia sesión para unirte.');
    }
    if (accessCode.trim().isEmpty) {
      throw Exception('Por favor, ingresa un código de acceso.');
    }

    final results = await _firestoreService.getDocumentsWhere(
      collectionName: _collectionName,
      field: 'accessCode',
      isEqualToValue: accessCode.trim().toUpperCase(),
      limit: 1,
    );

    if (results == null || results.isEmpty) {
      throw Exception('Código de acceso inválido o el proyecto no existe.');
    }

    final doc = results.first;
    final ProjectModel project = ProjectModel.fromFirestore(
      doc as DocumentSnapshot<Map<String, dynamic>>,
    );

    final userRoleToAdd = _userRoleString(currentUser.uid, 'member');

    if (project.adminUserId == currentUser.uid) {
      return project;
    }

    if (project.userRoles.any(
      (role) => role.startsWith('${currentUser.uid}:'),
    )) {
      return project;
    }

    final bool updateSuccess = await _firestoreService.updateDocument(
      _collectionName,
      project.id!,
      {
        'userRoles': FieldValue.arrayUnion([userRoleToAdd]),
        'updatedAt': Timestamp.now(),
      },
    );

    if (updateSuccess) {
      final List<String> updatedUserRoles = List<String>.from(
        project.userRoles,
      );
      updatedUserRoles.add(userRoleToAdd);
      return project.copyWith(userRoles: updatedUserRoles);
    } else {
      throw Exception('No se pudo unir al proyecto. Inténtalo de nuevo.');
    }
  }

  Future<void> leaveProject(String projectId) async {
    final currentUser = _authProviderApp.currentUser;
    if (currentUser == null) return;

    final doc = await getProjectById(projectId);
    if (doc == null) return;

    final currentRole = doc.userRoles.firstWhere(
      (r) => r.startsWith('${currentUser.uid}:'),
      orElse: () => '',
    );
    if (currentRole.isEmpty) throw Exception('No eres miembro.');

    final uniqueMembers = doc.userRoles.map((e) => e.split(':').first).toSet();

    if (doc.adminUserId == currentUser.uid && uniqueMembers.length > 1) {
      throw Exception('Transfiere la administración antes de salir.');
    }

    if (doc.adminUserId == currentUser.uid && uniqueMembers.length == 1) {
      await deleteProject(projectId);
      return;
    }

    await _firestoreService.updateDocument(_collectionName, projectId, {
      'userRoles': FieldValue.arrayRemove([currentRole]),
      'updatedAt': Timestamp.now(),
    });
  }
}
