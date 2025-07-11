import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroConfig {
  final String id;
  final int workTime;
  final int shortBreak;
  final int? longBreak;
  final int rounds;
  final String? goal;
  final String name;

  PomodoroConfig({
    required this.id,
    required this.workTime,
    required this.shortBreak,
    this.longBreak,
    required this.rounds,
    this.goal,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'workTime': workTime,
    'shortBreak': shortBreak,
    if (longBreak != null) 'longBreak': longBreak,
    'rounds': rounds,
    if (goal != null) 'goal': goal,
    'name': name,
  };

  static PomodoroConfig fromJson(String id, Map<String, dynamic> json) {
    return PomodoroConfig(
      id: id,

      // Para números enteros (int)
      // Hacemos cast a 'num' primero que es más flexible (acepta int y double)
      // y luego lo convertimos a int.
      workTime:
          (json['workTime'] as num?)?.toInt() ??
          25, // Valor por defecto: 25 minutos
      shortBreak:
          (json['shortBreak'] as num?)?.toInt() ??
          5, // Valor por defecto: 5 minutos
      longBreak:
          (json['longBreak'] as num?)?.toInt() ??
          15, // Valor por defecto: 15 minutos
      rounds:
          (json['rounds'] as num?)?.toInt() ?? 4, // Valor por defecto: 4 rondas
      // Si 'goal' también es un int
      goal:
          (json['goal'] as String?)?.toString() ??
          '', // Valor por defecto: 1 meta
      // Para Strings
      name:
          (json['name'] as String?) ??
          'Configuración Pomodoro', // Valor por defecto
    );
  }

  static PomodoroConfig fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => fromJson(doc.id, doc.data()!);
}
