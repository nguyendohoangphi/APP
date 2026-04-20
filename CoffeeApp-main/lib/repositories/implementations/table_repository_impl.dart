import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeeapp/models/tablestatus.dart';
import 'package:coffeeapp/repositories/table_repository.dart';
import 'package:coffeeapp/services/table_in_database.dart';

class TableRepositoryImpl implements ITableRepository {
  final CollectionReference _tableRef = FirebaseFirestore.instance.collection(
    TableInDatabase.TableStatusTable,
  );

  @override
  Future<List<TableStatus>> getTablesByBookingStatus(bool isBooked) async {
    final snapshot = await _tableRef
        .where('isBooked', isEqualTo: isBooked)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TableStatus.fromJson(data);
    }).toList();
  }

  @override
  Future<void> updateBookingStatus(String tableId, bool isBooked) async {
    await _tableRef.doc(tableId).update({'isBooked': isBooked});
  }
}
