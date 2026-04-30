import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';

class SqlReflectedTotalElimination<T> with FunctionalityMixin<void> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;

  const SqlReflectedTotalElimination({required this.engine, required this.reflectedStructure});

  @override
  FutureResult<void> runInternalFuncionality() {
    final command = SqlDeleteCommand(tableName: reflectedStructure.tableName);
    return engine.buildDataConnector().executeDelete(command);
  }
}
