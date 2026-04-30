import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';

class SqlReflectedModifier<T> with FunctionalityMixin<void> {
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;
  final List<T> content;
  final List<String>? fieldsToModify;
  final List<ColumnCondition>? conditions;

  const SqlReflectedModifier({required this.engine, required this.reflectedStructure, required this.content, this.conditions, this.fieldsToModify});

  @override
  FutureResult<void> runInternalFuncionality() async {
    if (content.isEmpty) {
      return voidResult;
    }

    if (reflectedStructure.editableFields.isEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'No editable fields found for entity %1', textParts: [reflectedStructure.reflectedEntity.name]),
      );
    }

    final fieldsToModify = this.fieldsToModify ?? reflectedStructure.editableFields.map((e) => e.name).toList();

    if (conditions == null && !reflectedStructure.reflectedEntity.itHasPrimaryKey) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The entity %1 does not have a primary key, so conditions must be provided to modify it', textParts: [reflectedStructure.reflectedEntity.name]),
      );
    }

    if (conditions == null) {
      final isZeroID = content.selectItem((x) => reflectedStructure.reflectedEntity.getPrimaryKey(item: x).content == 0);
      if (isZeroID != null) {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'Some items have a primary key value of 0, so conditions must be provided to modify them', textParts: [reflectedStructure.reflectedEntity.name]),
        );
      }
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

      late final List<ColumnCondition> conditionList;
      if (conditions == null) {
        final primaryKeyFieldResult = reflectedStructure.reflectedEntity.getPrimaryKeyField();
        if (primaryKeyFieldResult.itsFailure) {
          return NegativeResult.controller(
            code: ErrorCode.implementationFailure,
            message: FlexibleOration(message: 'The entity %1 does not have a primary key, so conditions must be provided to modify it', textParts: [reflectedStructure.reflectedEntity.name]),
          );
        }

        conditionList = [ColumnCompareValue(columnName: primaryKeyFieldResult.content.name, conditionator: CompareSelectedValue.equal(id))];
      } else {
        conditionList = conditions!;
      }

      final values = <String, dynamic>{};
      for (final field in reflectedStructure.editableFields) {
        if (fieldsToModify.contains(field.name)) {
          final valueResult = field.obtainValue(instance: item, manager: reflectedStructure.reflectionLibrary);
          if (valueResult.itsFailure) {
            return NegativeResult.changeText(
              message: FlexibleOration(message: 'Failed to get value of field %1 for item with id %2', textParts: [field.name, id]),
              other: valueResult,
            );
          }
          values[field.name] = valueResult.content;
        }
      }

      final command = SqlUpdateCommand(tableName: reflectedStructure.tableName, values: values, conditions: conditionList);
      final updateResult = await engine.buildDataConnector().executeUpdate(command);
      if (updateResult.itsFailure) {
        return NegativeResult.changeText(
          message: FlexibleOration(message: 'Failed to update item with id %1 on database', textParts: [id]),
          other: updateResult,
        );
      }

      i += 1;
    }
    return voidResult;
  }
}
