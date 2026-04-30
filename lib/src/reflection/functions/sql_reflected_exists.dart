import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sql/src/reflection/sql_reflected_class_structure.dart';

class SqlReflectedExists<T> with FunctionalityMixin<Map<int, bool>> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;
  final List<int> identifiers;

  const SqlReflectedExists({required this.engine, required this.reflectedStructure, required this.identifiers});

  @override
  FutureResult<Map<int, bool>> runInternalFuncionality() async {
    if (identifiers.isEmpty) {
      return const ResultValue(content: {});
    }

    if (!reflectedStructure.reflectedEntity.itHasPrimaryKey) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The entity %1 does not have a primary key', textParts: [reflectedStructure.reflectedEntity.name]),
      );
    }

    final content = <int, bool>{};

    final primaryKeyName = reflectedStructure.reflectedEntity.getPrimaryKeyField().content.name;
    for (final part in identifiers.toSet().splitByPart(500)) {
      final command = SqlQueryCommand(
        tables: [TableSelection(reflectedStructure.tableName)],
        columns: [ColumnSelection(columnName: primaryKeyName)],
        conditions: [ColumnCompareValue(columnName: primaryKeyName, conditionator: CompareIncludeValues(primaryKeyName, part))],
      );

      final queryResult = await engine.buildDataConnector().executeQuery(command);
      if (queryResult.itsFailure) {
        return NegativeResult.changeText(
          message: FlexibleOration(message: 'Failed to execute existence query for entity %1', textParts: [reflectedStructure.reflectedEntity.name]),
          other: queryResult,
        );
      }

      final existents = queryResult.content.obtainFirstColumn();
      for (final id in part) {
        existents.contains(id) ? content[id] = true : content[id] = false;
      }
    }
    return ResultValue(content: content);
  }
}
