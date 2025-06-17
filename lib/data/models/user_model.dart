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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      invitedProjectIds: data['invitedProjectIds'] != null
          ? List<String>.from(data['invitedProjectIds'])
          : null,
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
