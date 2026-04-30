import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_reflection/maxi_reflection.dart';
import 'package:maxi_sql/maxi_sql.dart';

class SqlReflectedObtainMaximumKey<T> with FunctionalityMixin<int> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;

  const SqlReflectedObtainMaximumKey({required this.engine, required this.reflectedStructure});

  @override
  FutureResult<int> runInternalFuncionality() async {
    final primaryKeyResult = reflectedStructure.reflectedEntity.getPrimaryKeyField();
    if (primaryKeyResult.itsFailure) {
      return primaryKeyResult.cast();
    }

    final primaryKeyField = primaryKeyResult.content;
    final query = SqlQueryCommand(
      columns: [ColumnSelection(columnName: primaryKeyField.name, function: ColumnSelectionFunction.maximum)],
      tables: [TableSelection(reflectedStructure.tableName)],
      limit: 1,
    );

    final queryResult = await engine.buildDataConnector().executeQuery(query);
    if (queryResult.itsFailure) {
      return queryResult.cast();
    }

    final table = queryResult.content;
    if (table.isEmpty || table.first.isEmpty || table.first.values.first == null) {
      return 0.asResultValue();
    }

    return PrimitiveConverter.castInt(table.first.values.first);
  }
}
