import 'package:hive/hive.dart';
import '../models/mistake.dart';
import '../utils/sync_helper.dart';

class MistakeService {
  static const String _boxName = 'mistakes';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MistakeAnswerOptionAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MistakeAdapter());
    }
    await Hive.openBox<Mistake>(_boxName);
  }

  Future<void> addMistake(Mistake mistake) async {
    final box = Hive.box<Mistake>(_boxName);
    await box.add(mistake);

    // Sync to cloud immediately (non-blocking)
    SyncHelper.syncMistake(mistake);
  }

  List<Mistake> getMistakes() {
    final box = Hive.box<Mistake>(_boxName);
    return box.values.toList();
  }

  Future<void> clearMistakes() async {
    final box = Hive.box<Mistake>(_boxName);
    await box.clear();
  }
}
