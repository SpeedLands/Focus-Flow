import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String email;
  final String? name;
  final List<String> fcmTokens;
  final List<String>? invitedProjectIds;

  UserData({
    required this.uid,
    required this.email,
    this.name,
    this.fcmTokens = const [],
    this.invitedProjectIds,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    // Es una buena práctica castear el DocumentSnapshot al tipo correcto si es posible
    final data = doc.data() as Map<String, dynamic>?;

    // Guarda de seguridad
    if (data == null) {
      throw StateError('El documento de usuario ${doc.id} no tiene datos.');
    }

    // Lógica segura para las listas
    final fcmTokensList = (data['fcmTokens'] is List)
        ? List<String>.from((data['fcmTokens'] as List).whereType<String>())
        : <String>[]; // Devuelve una lista vacía si el campo no es una lista

    final invitedProjectIdsList = (data['invitedProjectIds'] is List)
        ? List<String>.from(
            (data['invitedProjectIds'] as List).whereType<String>(),
          )
        : null; // Devuelve null si el campo no es una lista, lo cual es válido

    return UserData(
      uid: doc.id,

      // Campo String requerido
      email: (data['email'] as String?) ?? '',

      // Campo String nulable
      name: data['name'] as String?,

      // Listas manejadas de forma segura arriba
      fcmTokens: fcmTokensList,
      invitedProjectIds: invitedProjectIdsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'fcmTokens': fcmTokens,
      if (invitedProjectIds != null) 'invitedProjectIds': invitedProjectIds,
    };
  }

  UserData copyWith({
    String? uid,
    String? email,
    String? name,
    List<String>? fcmTokens,
    List<String>? invitedProjectIds,
    bool setInvitedProjectIdsToNull = false,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      invitedProjectIds: setInvitedProjectIdsToNull
          ? null
          : (invitedProjectIds ?? this.invitedProjectIds),
    );
  }
}
