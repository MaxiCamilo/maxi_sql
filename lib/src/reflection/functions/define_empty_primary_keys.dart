import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_reflection/maxi_reflection.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sql/src/reflection/sql_reflected_class_structure.dart';

class DefineEmptyPrimaryKeys<T> with FunctionalityMixin<void> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;
  final List<T> content;

  const DefineEmptyPrimaryKeys({required this.engine, required this.reflectedStructure, required this.content});

  @override
  FutureResult<void> runInternalFuncionality() async {
    if (!reflectedStructure.reflectedEntity.itHasPrimaryKey || !reflectedStructure.editableFields.any((x) => x.name == reflectedStructure.reflectedEntity.getPrimaryKeyField().content.name)) {
      return voidResult;
    }

    final itemWithZeroID = content.where((x) => reflectedStructure.reflectedEntity.getPrimaryKey(item: x).content == 0).toList();
    if (itemWithZeroID.isEmpty) {
      return voidResult;
    }

    final queryID = SqlQueryCommand(
      tables: [TableSelection(reflectedStructure.tableName)],
      columns: [ColumnSelection(columnName: reflectedStructure.reflectedEntity.getPrimaryKeyField().content.name, function: ColumnSelectionFunction.maximum)],
    );

    final queryResult = await engine.buildDataConnector().executeQuery(queryID);
    if (queryResult.itsFailure) {
      return queryResult.cast();
    }

    final maxRawID = queryResult.content.first.values.first as Object? ?? 0;
    final newIDResult = PrimitiveConverter.castInt(maxRawID);
    if (newIDResult.itsFailure) {
      return NegativeResult.changeText(
        message: FlexibleOration(message: 'Invalid primary key value on database, expected an integer but got %1', textParts: [maxRawID]),
        other: newIDResult,
      );
    }

    int newID = newIDResult.content + 1;
    for (final item in itemWithZeroID) {
      final setPropertyResult = reflectedStructure.reflectedEntity.changePrimaryKey(item: item, newID: newID);
      if (setPropertyResult.itsFailure) {
        return setPropertyResult.cast();
      }
      newID++;
    }

    return voidResult;
  }
}
