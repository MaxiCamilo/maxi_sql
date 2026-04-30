import 'package:maxi_reflection/maxi_reflection.dart';
import 'package:maxi_sql/maxi_sql.dart';

class SqlReflectedClassStructure<T> {
  final String tableName;
  final ReflectedEntity<T> reflectedEntity;
  final ReflectionLibrary reflectionLibrary;
  final List<ColumnKeyGroup> primaryKeyGroups;
  final List<ColumnKeyGroup> uniqueKeyGroups;
  final List<ForeignKey> foreignKeys;
  final Map<ReflectedField, SqlColumnFormat> fieldColumnMap;
  final List<ReflectedField> editableFields;

  const SqlReflectedClassStructure({
    required this.reflectionLibrary,
    required this.tableName,
    required this.reflectedEntity,
    required this.primaryKeyGroups,
    required this.uniqueKeyGroups,
    required this.foreignKeys,
    required this.fieldColumnMap,
    required this.editableFields,
  });
}
