import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { baja, media, alta }

class TaskModel {
  final String? id;
  final String projectId;
  final String name;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final Timestamp? dueDate;
  final String createdBy;
  final Timestamp createdAt;
  final String? completedBy;
  final Timestamp? completedAt;
  final Timestamp updatedAt;

  TaskModel({
    this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.isCompleted = false,
    this.priority = TaskPriority.media,
    this.dueDate,
    required this.createdBy,
    required this.createdAt,
    this.completedBy,
    this.completedAt,
    required this.updatedAt,
  });

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    Timestamp? dueDate,
    bool setDueDateToNull = false,
    String? createdBy,
    Timestamp? createdAt,
    String? completedBy,
    bool setCompletedByToNull = false,
    Timestamp? completedAt,
    bool setCompletedAtToNull = false,
    Timestamp? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: setDueDateToNull ? null : (dueDate ?? this.dueDate),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      completedBy: setCompletedByToNull
          ? null
          : (completedBy ?? this.completedBy),
      completedAt: setCompletedAtToNull
          ? null
          : (completedAt ?? this.completedAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return TaskModel(
      id: snapshot.id,
      projectId: data['projectId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == data['priority'],
        orElse: () => TaskPriority.media,
      ),
      dueDate: data['dueDate'] as Timestamp?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      completedBy: data['completedBy'] as String?,
      completedAt: data['completedAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String?,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => TaskPriority.media,
      ),
      dueDate: json['dueDate'] as Timestamp?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      completedBy: json['completedBy'] as String?,
      completedAt: json['completedAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'name': name,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.toString(),
      'dueDate': dueDate,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'completedBy': completedBy,
      'completedAt': completedAt,
      'updatedAt': updatedAt,
    };
  }
}
