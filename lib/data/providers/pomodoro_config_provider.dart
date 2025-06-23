import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_flow/data/models/pomodoro_config.dart';
import 'package:focus_flow/data/services/firestore_service.dart';

class PomodoroProvider {
  final FirestoreService _fs;

  static const parent = 'users';
  static const sub = 'pomodoro_configs';

  PomodoroProvider(this._fs);

  Stream<List<PomodoroConfig>> streamConfigs(String uid) {
    return _fs
        .listenToCollectionFiltered('$parent/$uid/$sub', orderByField: 'name')
        .map((snap) {
          return snap.docs
              .map(
                (d) => PomodoroConfig.fromFirestore(
                  d as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
        });
  }

  Future<String?> addConfig(PomodoroConfig cfg, String uid) async {
    try {
      return await _fs.addDocumentToSubcollection(
        parentCollectionName: parent,
        subCollectionName: sub,
        documentId: uid,
        data: cfg.toJson(),
      );
    } catch (e) {
      print('Error adding config: $e');
      return null;
    }
  }

  Future<bool> updateConfig(PomodoroConfig cfg, String uid) async {
    try {
      await _fs.setDocument(
        cfg.id,
        '$parent/$uid/$sub',
        cfg.toJson(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      print('Error updating config: $e');
      return false;
    }
  }

  Future<bool> deleteConfig(String cfgId, String uid) async {
    try {
      await _fs.deleteDocument('$parent/$uid/$sub', cfgId);
      return true;
    } catch (e) {
      print('Error deleting config: $e');
      return false;
    }
  }
}
