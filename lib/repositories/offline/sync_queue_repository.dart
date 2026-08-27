import 'package:hive/hive.dart';

import '../../models/sync_operation_model.dart';

class SyncQueueRepository {
  static const String _boxName = 'sync_queue';

  Future<Box> _getBox() async {
    return Hive.box(_boxName);
  }

  Future<void> addOperation(
    SyncOperationModel operation,
  ) async {
    final box = await _getBox();

    await box.put(
      operation.id,
      operation.toMap(),
    );
  }

  Future<List<SyncOperationModel>> getOperations() async {
    final box = await _getBox();

    return box.values
        .map(
          (item) => SyncOperationModel.fromMap(
            Map<dynamic, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> removeOperation(String id) async {
    final box = await _getBox();

    await box.delete(id);
  }
}