import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sql/src/reflection/sql_reflected_class_structure.dart';

class CreateOrCheckReflectedTable<T> with FunctionalityMixin<void> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;

  const CreateOrCheckReflectedTable({required this.engine, required this.reflectedStructure});

  @override
  FutureResult<void> runInternalFuncionality() async {
    final structCommand = engine.buildStructureManager();

    final existsResult = await structCommand.checkTableExists(tableName: reflectedStructure.tableName);
    if (existsResult.itsFailure) {
      return existsResult.cast();
    }

    final command = SqlTableCreator(
      name: reflectedStructure.tableName,
      columns: reflectedStructure.fieldColumnMap.values.toList(),
      primaryKeyGroups: reflectedStructure.primaryKeyGroups,
      uniqueKeyGroups: reflectedStructure.uniqueKeyGroups,
      foreignKeys: reflectedStructure.foreignKeys,
    );

    if (existsResult.content) {
      final checkResult = await structCommand.validateTableSchema(command: command);
      if (checkResult.itsFailure) {
        return checkResult.cast();
      }
    } else {
      final createResult = await structCommand.createTable(command: command);
      if (createResult.itsFailure) {
        return createResult.cast();
      }
    }

    return voidResult;
  }
}
