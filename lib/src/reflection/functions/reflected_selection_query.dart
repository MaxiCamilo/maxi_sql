import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';

class ReflectedSelectionQuery<T> with FunctionalityMixin<List<T>> {
  final SqlQueryCommand queryCommand;
  final SqlEngine engine;
  final SqlReflectedClassStructure<T> reflectedStructure;

  final bool identifierRequired;
  final bool zeroIdentifiersAreAccepted;
  final bool requiredFieldEnable;

  const ReflectedSelectionQuery({
    required this.queryCommand,
    required this.engine,
    required this.reflectedStructure,
    this.identifierRequired = false,
    this.zeroIdentifiersAreAccepted = true,
    this.requiredFieldEnable = true,
  });

  @override
  FutureResult<List<T>> runInternalFuncionality() async {
    SqlQueryCommand query = queryCommand;

    if (!query.tables.any((x) => x.tableName == reflectedStructure.tableName)) {
      query = SqlQueryCommand.clone(query);
      query.tables.add(TableSelection(reflectedStructure.tableName));
    }

    final queryResult = await engine.buildDataConnector().executeQuery(query);
    if (queryResult.itsFailure) {
      return queryResult.cast();
    }

    final table = queryResult.content;
    final result = <T>[];

    final interpreter = reflectedStructure.reflectedEntity.buildMapInterpreter(identifierRequired: identifierRequired, zeroIdentifiersAreAccepted: zeroIdentifiersAreAccepted, requiredFieldEnable: requiredFieldEnable);

    int i = 1;

    for (final rawMap in table) {
      late final int id;
      if (reflectedStructure.reflectedEntity.itHasPrimaryKey) {
        final idResult = reflectedStructure.reflectedEntity.getPrimaryKey(item: rawMap);
        id = idResult.itsCorrect ? idResult.content : i;
      } else {
        id = i;
      }

      final newItemResult = interpreter.interpretValue(values: rawMap, manager: reflectedStructure.reflectionLibrary);
      if (newItemResult.itsFailure) {
        return NegativeResult.changeText(
          message: FlexibleOration(message: 'Invalid item at index %1 on database', textParts: [id]),
          other: newItemResult,
        );
      }
      result.add(newItemResult.content);

      i += 1;
    }

    return result.asResultValue();
  }
}
