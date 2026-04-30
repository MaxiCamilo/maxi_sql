import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_reflection/maxi_reflection.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sql/src/reflection/functions/create_or_check_reflected_table.dart';
import 'package:maxi_sql/src/reflection/functions/reflected_selection_query.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_aggregation.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_determinate_elimination.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_exists.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_modifier.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_obtain_identifiers.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_obtain_maximum_key.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_obtain_minimum_key.dart';
import 'package:maxi_sql/src/reflection/functions/sql_reflected_total_elimination.dart';

class SqlReflectedTable<T> with DisposableMixin, InitializableMixin {
  final SqlReflectedClassStructure<T>? initialStructure;

  final ReflectionLibrary _reflectionLibrary;

  final String tableName;
  final List<ForeignKey> _foreignKeys;
  final bool _omitPrimaryKey;
  final bool _omitUniqueKeys;
  final List<ColumnKeyGroup> _primaryKeyGroups;
  final List<ColumnKeyGroup> _uniqueKeyGroups;
  final List<ReflectedField> _reflectedFields;
  final ReflectedEntity<T>? _reflectedEntity;

  final List<ReflectedField>? _editableFields;

  late SqlReflectedClassStructure<T> _structure;

  Result<SqlReflectedClassStructure<T>> get structure => initialize().onCorrectSelect((_) => _structure);

  /// [Extension method]

  FutureResult<void> createOrCheckTable(SqlEngine engine) async => await initialize().onCorrectFuture((_) => CreateOrCheckReflectedTable<T>(engine: engine, reflectedStructure: _structure).execute());
  FutureResult<void> eliminateAll(SqlEngine engine) async => initialize().onCorrectFuture((_) => SqlReflectedTotalElimination<T>(engine: engine, reflectedStructure: _structure).execute());
  FutureResult<void> eliminateDeterminated({required SqlEngine engine, required List<int> ids}) async =>
      initialize().onCorrectFuture((_) => SqlReflectedDeterminateElimination<T>(engine: engine, reflectedStructure: _structure, identifiers: ids).execute());

  FutureResult<void> aggregate({required SqlEngine engine, required List<T> items}) async =>
      await initialize().onCorrectFuture((_) => SqlReflectedAggregation<T>(engine: engine, reflectedStructure: _structure, content: items).execute());

  FutureResult<void> modify({required SqlEngine engine, required List<T> items}) async =>
      await initialize().onCorrectFuture((_) => SqlReflectedModifier<T>(engine: engine, reflectedStructure: _structure, content: items).execute());

  FutureResult<Map<int, bool>> checkExisting({required SqlEngine engine, required List<int> ids}) async =>
      await initialize().onCorrectFuture((_) => SqlReflectedExists<T>(engine: engine, reflectedStructure: _structure, identifiers: ids).execute());

  FutureResult<int> obtainMaximumKey({required SqlEngine engine}) async => await initialize().onCorrectFuture((_) => SqlReflectedObtainMaximumKey<T>(engine: engine, reflectedStructure: _structure).execute());
  FutureResult<int> obtainMinimumKey({required SqlEngine engine}) async => await initialize().onCorrectFuture((_) => SqlReflectedObtainMinimumKey<T>(engine: engine, reflectedStructure: _structure).execute());

  FutureResult<List<T>> queryAll({required SqlEngine engine}) async => await initialize().onCorrectFuture(
    (_) => ReflectedSelectionQuery<T>(
      engine: engine,
      reflectedStructure: _structure,
      queryCommand: SqlQueryCommand(tables: [TableSelection(tableName)]),
    ).execute(),
  );

  FutureResult<List<int>> queryIdentifiers({required SqlEngine engine, List<ColumnCondition> conditions = const [], int? limits}) async =>
      await initialize().onCorrectFuture((_) => SqlReflectedObtainIdentifiers<T>(engine: engine, reflectedStructure: _structure, conditions: conditions, limits: limits).execute());

  FutureResult<List<T>> queryIterator({required SqlEngine engine, int from = 0, required int amount}) async => await initialize()
      .onCorrect((_) => _reflectedEntity!.getPrimaryKeyField())
      .onCorrectFuture(
        (primary) => ReflectedSelectionQuery<T>(
          engine: engine,
          reflectedStructure: _structure,
          queryCommand: SqlQueryCommand(
            tables: [TableSelection(tableName)],
            conditions: [ColumnCompareValue(columnName: primary.name, conditionator: CompareSelectedValue.greaterEqual(from))],
            limit: amount,
            orders: [
              QueryOrder(fields: [primary.name], isAscendent: true),
            ],
          ),
        ).execute(),
      );

  FutureResult<List<int>> queryIdentifiersIterator({required SqlEngine engine, List<ColumnCondition> conditions = const [], int from = 0, required int amount}) async => await initialize().onCorrectFuture(
    (_) => SqlReflectedObtainIdentifiers<T>(
      engine: engine,
      reflectedStructure: _structure,
      conditions: [
        ColumnCompareValue(columnName: _structure.reflectedEntity.getPrimaryKeyField().content.name, conditionator: CompareSelectedValue.greaterEqual(from)),
        ...conditions,
      ],
      limits: amount,
    ).execute(),
  );

 
  /// [/Extension method]

  SqlReflectedTable.custom({required ReflectionLibrary reflectionLibrary, required SqlReflectedClassStructure<T> structure})
    : initialStructure = structure,
      tableName = structure.tableName,
      _foreignKeys = structure.foreignKeys,
      _omitPrimaryKey = false,
      _omitUniqueKeys = false,
      _primaryKeyGroups = structure.primaryKeyGroups,
      _uniqueKeyGroups = structure.uniqueKeyGroups,
      _reflectedFields = structure.fieldColumnMap.keys.toList(),
      _reflectedEntity = structure.reflectedEntity,
      _editableFields = structure.editableFields,

      _reflectionLibrary = reflectionLibrary {
    _structure = structure;
  }

  SqlReflectedTable.automatic({
    required this.tableName,
    required ReflectionLibrary library,
    List<ForeignKey> foreignKeys = const [],
    ReflectedEntity<T>? reflectedEntity,
    bool omitPrimaryKey = false,
    bool omitUniqueKeys = false,
    List<ColumnKeyGroup> primaryKeyGroups = const [],
    List<ColumnKeyGroup> uniqueKeyGroups = const [],
    List<ReflectedField> reflectedFields = const [],
    List<ReflectedField>? editableFields,
  }) : initialStructure = null,
       _foreignKeys = foreignKeys,
       _omitPrimaryKey = omitPrimaryKey,
       _omitUniqueKeys = omitUniqueKeys,
       _primaryKeyGroups = primaryKeyGroups,
       _uniqueKeyGroups = uniqueKeyGroups,
       _reflectedFields = reflectedFields,
       _reflectedEntity = reflectedEntity,
       _reflectionLibrary = library,
       _editableFields = editableFields;

  @override
  Result<void> performInitialization() {
    if (initialStructure == null) {
      return _buildStructure();
    } else {
      _structure = initialStructure!;
      return voidResult;
    }
  }

  Result<void> _buildStructure() {
    late final List<ReflectedField> reflectedFields;
    late final List<ReflectedField> editableFields;
    late final ReflectedEntity<T> reflectedEntity;

    if (_reflectedEntity != null) {
      reflectedEntity = _reflectedEntity;
    } else {
      final reflectedEntityResult = _reflectionLibrary.searchEntityReflected<T>();

      if (reflectedEntityResult.itsFailure) {
        return reflectedEntityResult.cast();
      }
      reflectedEntity = reflectedEntityResult.content;
    }

    if (_reflectedFields.isEmpty) {
      reflectedFields = reflectedEntity.classReflector.fields;
    } else {
      reflectedFields = _reflectedFields;
    }

    if (_editableFields != null) {
      editableFields = _editableFields;
    } else {
      editableFields = reflectedEntity.changeableFields;
    }

    return BuildSqlReflectedStructure<T>(
      reflectionLibrary: _reflectionLibrary,
      reflectedEntity: reflectedEntity,
      reflectedFields: reflectedFields,
      tableName: tableName,
      foreignKeys: _foreignKeys,
      omitPrimaryKey: _omitPrimaryKey,
      omitUniqueKeys: _omitUniqueKeys,
      primaryKeyGroups: _primaryKeyGroups,
      uniqueKeyGroups: _uniqueKeyGroups,
      editableFields: editableFields,
    ).execute().injectVoidLogic((x) => _structure = x);
  }

  @override
  void performObjectDiscard() {}
}
