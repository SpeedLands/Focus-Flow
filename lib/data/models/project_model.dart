import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProjectModel {
  final String? id; // ID del documento en Firestore
  final String name;
  final String? description;
  final String colorHex;
  final String iconName;
  final String adminUserId; // UID del administrador del proyecto
  // MODIFICADO: De Map<String, String> members a List<String> userRoles
  final List<String> userRoles; // Lista de roles: ["userId:role"]
  final String? accessCode; // Código de acceso opcional
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ProjectModel({
    this.id,
    required this.name,
    this.description,
    required this.colorHex,
    required this.iconName,
    required this.adminUserId,
    // MODIFICADO: Cambiar members por userRoles
    required this.userRoles,
    this.accessCode,
    required this.createdAt,
    this.updatedAt,
  });

  Color get projectColor =>
      Color(int.parse(colorHex.replaceFirst('#', '0xff')));

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
  }

  factory ProjectModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    // MODIFICADO: Manejo de 'userRoles' como una lista de strings
    List<String> userRolesList = [];
    if (data['userRoles'] != null && data['userRoles'] is List) {
      // Asegurarse de que los elementos de la lista son strings
      userRolesList = List<String>.from(
        (data['userRoles'] as List).whereType<String>(),
      );
    }

    return ProjectModel(
      id: snapshot.id,
      name: data['name'] ?? 'Sin Nombre',
      description: data['description'],
      colorHex: data['colorHex'] ?? '#9E9E9E', // Color por defecto gris
      iconName: data['iconName'] ?? 'default_icon',
      adminUserId: data['adminUserId'] ?? '',
      userRoles: userRolesList,
      accessCode: data['accessCode'],
      createdAt:
          data['createdAt'] ??
          Timestamp.now(), // Proveer un valor por defecto si es nulo
      updatedAt: data['updatedAt'], // Puede ser nulo
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'colorHex': colorHex,
      'iconName': iconName,
      'adminUserId': adminUserId,
      'userRoles': userRoles,
      'accessCode': accessCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'colorHex': colorHex,
      'iconName': iconName,
      'updatedAt': Timestamp.now(),
    };
    return data;
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    String? iconName,
    String? adminUserId,
    // MODIFICADO: Cambiar Map<String, String>? members a List<String>? userRoles
    List<String>? userRoles,
    String? accessCode,
    bool setAccessCodeToNull = false,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool setUpdatedAtNull = false,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      adminUserId: adminUserId ?? this.adminUserId,
      // MODIFICADO: Usar userRoles
      userRoles: userRoles ?? this.userRoles,
      accessCode: setAccessCodeToNull ? null : (accessCode ?? this.accessCode),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: setUpdatedAtNull ? null : (updatedAt ?? this.updatedAt),
    );
  }
}

// La función getIconData no necesita cambios
IconData getIconData(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'work':
    case 'work_outline':
      return Icons.work_outline;
    case 'home':
    case 'home_outline':
      return Icons.home_outlined;
    case 'personal':
      return Icons.person_outline;
    case 'shopping_cart':
      return Icons.shopping_cart_outlined;
    case 'fitness_center':
      return Icons.fitness_center_outlined;
    case 'school':
      return Icons.school_outlined;
    // Agrega más mapeos según necesites
    case 'default_icon':
    default:
      return Icons.folder_special_outlined; // Un ícono por defecto
  }
}
