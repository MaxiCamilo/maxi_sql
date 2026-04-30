import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sql/src/reflection/functions/define_empty_primary_keys.dart';

class SqlReflectedAggregation<T> with FunctionalityMixin<void> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;
  final List<T> content;

  const SqlReflectedAggregation({required this.engine, required this.reflectedStructure, required this.content});

  @override
  FutureResult<void> runInternalFuncionality() async {
    if(content.isEmpty) {
      return voidResult;
    }

    if (reflectedStructure.editableFields.isEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'No editable fields found for entity %1', textParts: [reflectedStructure.reflectedEntity.name]),
      );
    }

    final checkZeroIDResult = await DefineEmptyPrimaryKeys<T>(engine: engine, reflectedStructure: reflectedStructure, content: content).execute();
    if (checkZeroIDResult.itsFailure) {
      return checkZeroIDResult.cast();
    }

    int i = 1;
    for (final item in content) {
      late final int id;
      if (reflectedStructure.reflectedEntity.itHasPrimaryKey) {
        final idResult = reflectedStructure.reflectedEntity.getPrimaryKey(item: item);
        id = idResult.itsCorrect ? idResult.content : i;
      } else {
        id = i;
      }

      final values = <String, dynamic>{};
      for (final field in reflectedStructure.editableFields) {
        final valueResult = field.obtainValue(instance: item, manager: reflectedStructure.reflectionLibrary);
        if (valueResult.itsFailure) {
          return NegativeResult.changeText(
            message: FlexibleOration(message: 'Failed to get value of field %1 for item with id %2', textParts: [field.name, id]),
            other: valueResult,
          );
        }
        values[field.name] = valueResult.content;
      }

      final command = SqlInsertCommand(tableName: reflectedStructure.tableName, values: values);
      final insertResult = await engine.buildDataConnector().executeInsert(command);
      if (insertResult.itsFailure) {
        return NegativeResult.changeText(
          message: FlexibleOration(message: 'Failed to insert item with id %1 into database', textParts: [id]),
          other: insertResult,
        );
      }

      i++;
    }
    return voidResult;
  }
}
