import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sql/src/reflection/sql_reflected_class_structure.dart';

class SqlReflectedDeterminateElimination<T> with FunctionalityMixin<void> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;
  final List<int> identifiers;

  const SqlReflectedDeterminateElimination({required this.engine, required this.reflectedStructure, required this.identifiers});

  @override
  FutureResult<void> runInternalFuncionality() async {
    if(identifiers.isEmpty) {
      return voidResult;
    }

    if (!reflectedStructure.reflectedEntity.itHasPrimaryKey) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The entity %1 does not have a primary key', textParts: [reflectedStructure.reflectedEntity.name]),
      );
    }

    final primaryKeyName = reflectedStructure.reflectedEntity.getPrimaryKeyField().content.name;

    for (final part in identifiers.splitByPart(250)) {
      final command = SqlDeleteCommand(
        tableName: reflectedStructure.tableName,
        conditions: [ColumnCompareValue(columnName: primaryKeyName, conditionator: CompareIncludeValues(primaryKeyName, part))],
      );
      await engine.buildDataConnector().executeDelete(command);
    }

    return voidResult;
  }
}
