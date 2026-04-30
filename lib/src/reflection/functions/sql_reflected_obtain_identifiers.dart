import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_reflection/maxi_reflection.dart';
import 'package:maxi_sql/maxi_sql.dart';

class SqlReflectedObtainIdentifiers<T> with FunctionalityMixin<List<int>> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;
  final List<ColumnCondition> conditions;
  final int? limits;

  SqlReflectedObtainIdentifiers({required this.engine, required this.reflectedStructure, this.conditions = const [], this.limits});

  @override
  FutureResult<List<int>> runInternalFuncionality() async {
    final primaryKeyResult = reflectedStructure.reflectedEntity.getPrimaryKeyField();
    if (primaryKeyResult.itsFailure) {
      return primaryKeyResult.cast();
    }

    final primaryKeyField = primaryKeyResult.content;

    final queryCommand = SqlQueryCommand(
      columns: [ColumnSelection(columnName: primaryKeyField.name)],
      tables: [TableSelection(reflectedStructure.tableName)],
      conditions: conditions,
      limit: limits,
      orders: [
        QueryOrder(fields: [primaryKeyField.name], isAscendent: true),
      ],
    );

    final queryResult = await engine.buildDataConnector().executeQuery(queryCommand);
    if (queryResult.itsFailure) {
      return queryResult.cast();
    }

    final table = queryResult.content;
    final idList = <int>[];

    for (final row in table) {
      if (row.isEmpty) {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'No columns were obtained when trying to obtain identifiers for %1', textParts: [reflectedStructure.reflectedEntity.name]),
        );
      }

      if (row.length > 1) {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'More than one column was obtained when trying to obtain identifiers for %1', textParts: [reflectedStructure.reflectedEntity.name]),
        );
      }

      final idResult = PrimitiveConverter.castInt(row.values.first);
      if (idResult.itsFailure) {
        return idResult.cast();
      }

      idList.add(idResult.content);
    }

    return idList.asResultValue();
  }
}
