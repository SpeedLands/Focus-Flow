import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProjectModel {
  final String? id;
  final String name;
  final String? description;
  final String colorHex;
  final String iconName;
  final String adminUserId;
  final List<String> userRoles;
  final String? accessCode;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ProjectModel({
    this.id,
    required this.name,
    this.description,
    required this.colorHex,
    required this.iconName,
    required this.adminUserId,
    required this.userRoles,
    this.accessCode,
    required this.createdAt,
    this.updatedAt,
  });

  Color get projectColor =>
      Color(int.parse(colorHex.replaceFirst('#', '0xff')));

  static String colorToHex(Color color) {
    // Obtenemos el valor entero (0-255) de cada componente usando la fórmula del linter.
    final int rInt = (color.r * 255.0).round() & 0xff;
    final int gInt = (color.g * 255.0).round() & 0xff;
    final int bInt = (color.b * 255.0).round() & 0xff;

    // Convertimos cada entero a su representación hexadecimal.
    final r = rInt.toRadixString(16).padLeft(2, '0');
    final g = gInt.toRadixString(16).padLeft(2, '0');
    final b = bInt.toRadixString(16).padLeft(2, '0');

    // Los unimos en el formato #RRGGBB.
    return '#$r$g$b';
  }

  factory ProjectModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    // Guarda de seguridad
    if (data == null) {
      throw StateError(
        'El documento del proyecto ${snapshot.id} no tiene datos.',
      );
    }

    // Lógica segura para userRoles (la que tenías es muy buena)
    List<String> userRolesList = [];
    if (data['userRoles'] != null && data['userRoles'] is List) {
      // Usamos List.from para crear una nueva lista y whereType para filtrar solo los Strings.
      userRolesList = List<String>.from(
        (data['userRoles'] as List).whereType<String>(),
      );
    }

    return ProjectModel(
      id: snapshot.id,

      // Campos String requeridos
      name: (data['name'] as String?) ?? 'Sin Nombre',
      colorHex: (data['colorHex'] as String?) ?? '#9E9E9E',
      iconName: (data['iconName'] as String?) ?? 'default_icon',
      adminUserId: (data['adminUserId'] as String?) ?? '',

      // Lista de Strings (ya manejada de forma segura arriba)
      userRoles: userRolesList,

      // Campos String que pueden ser nulos en el modelo
      description: data['description'] as String?,
      accessCode: data['accessCode'] as String?,

      // Campos Timestamp
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt:
          data['updatedAt']
              as Timestamp?, // Este es nulable, así que no necesita valor por defecto
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
      userRoles: userRoles ?? this.userRoles,
      accessCode: setAccessCodeToNull ? null : (accessCode ?? this.accessCode),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: setUpdatedAtNull ? null : (updatedAt ?? this.updatedAt),
    );
  }
}

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
    case 'default_icon':
    default:
      return Icons.folder_special_outlined;
  }
}
