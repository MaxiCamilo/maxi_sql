import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';

class SqlReflectedInstance<T> with DisposableMixin, InitializableMixin {
  final SqlReflectedTable<T> reflectedTable;
  final SqlEngine engine;

  SqlReflectedInstance({required this.reflectedTable, required this.engine});

  @override
  Result<void> performInitialization() {
    final initResult = reflectedTable.initialize();
    if (initResult.itsFailure) {
      return initResult.cast();
    }

    return voidResult;
  }

  FutureResult<void> createOrCheckTable() async => await initialize().onCorrectFuture((_) => reflectedTable.createOrCheckTable(engine));
  FutureResult<void> eliminateAll() async => initialize().onCorrectFuture((_) => reflectedTable.eliminateAll(engine));
  FutureResult<void> eliminateDeterminated({required List<int> ids}) async => initialize().onCorrectFuture((_) => reflectedTable.eliminateDeterminated(engine: engine, ids: ids));

  FutureResult<List<int>> aggregate({required List<T> items}) async => await initialize().onCorrectFuture((_) => reflectedTable.aggregate(engine: engine, items: items));

  FutureResult<void> modify({required List<T> items}) async => await initialize().onCorrectFuture((_) => reflectedTable.modify(engine: engine, items: items));

  FutureResult<Map<int, bool>> checkExisting({required List<int> ids}) async => await initialize().onCorrectFuture((_) => reflectedTable.checkExisting(engine: engine, ids: ids));

  FutureResult<List<T>> queryAll() async => await initialize().onCorrectFuture((_) => reflectedTable.queryAll(engine: engine));

  FutureResult<List<T>> queryIterator({int from = 0, required int amount}) async => await initialize().onCorrectFuture((_) => reflectedTable.queryIterator(engine: engine, from: from, amount: amount));

  FutureResult<List<int>> queryIdentifiers({required SqlEngine engine, List<ColumnCondition> conditions = const [], int? limits}) async =>
      await initialize().onCorrectFuture((_) => reflectedTable.queryIdentifiers(engine: engine, conditions: conditions, limits: limits));

  FutureResult<List<T>> queryIdentifiersIterator({required SqlEngine engine, int from = 0, required int amount}) async =>
      await initialize().onCorrectFuture((_) => reflectedTable.queryIterator(engine: engine, amount: amount, from: from));

  FutureResult<int> obtainMaximumKey() async => await initialize().onCorrectFuture((_) => reflectedTable.obtainMaximumKey(engine: engine));
  FutureResult<int> obtainMinimumKey() async => await initialize().onCorrectFuture((_) => reflectedTable.obtainMinimumKey(engine: engine));

  FutureResult<T?> selectValue({required int identifier}) async => await initialize().onCorrectFuture((_) => reflectedTable.selectValue(engine: engine, identifier: identifier));
  FutureResult<T> obtainValue({required int identifier}) async => await initialize().onCorrectFuture((_) => reflectedTable.obtainValue(engine: engine, identifier: identifier));
  FutureResult<T> obtainMaximum() async => await initialize().onCorrectFuture((_) => reflectedTable.obtainMaximum(engine: engine));
  FutureResult<T> obtainMinimum() async => await initialize().onCorrectFuture((_) => reflectedTable.obtainMinimum(engine: engine));

  FutureResult<int?> selectFirstID({List<ColumnCondition> conditions = const []}) => reflectedTable.selectFirstID(engine: engine, conditions: conditions);
  FutureResult<T?> selectFirst({List<ColumnCondition> conditions = const []}) => reflectedTable.selectFirst(engine: engine, conditions: conditions);

  FutureResult<List<T>> queryWhere({required List<ColumnCondition> conditions, int from = 0, int? limits}) => reflectedTable.queryWhere(engine: engine, conditions: conditions, from: from, limits: limits);

  @override
  void performObjectDiscard() {}
}
