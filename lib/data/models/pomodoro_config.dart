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
      workTime: json['workTime'],
      shortBreak: json['shortBreak'],
      longBreak: json['longBreak'],
      rounds: json['rounds'],
      goal: json['goal'],
      name: json['name'],
    );
  }

  static PomodoroConfig fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => fromJson(doc.id, doc.data()!);
}
