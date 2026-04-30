import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_reflection/maxi_reflection.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sql/src/reflection/sql_reflected_class_structure.dart';

class BuildSqlReflectedStructure<T> implements SyncFunctionality<SqlReflectedClassStructure<T>> {
  final ReflectedEntity<T> reflectedEntity;
  final List<ReflectedField> reflectedFields;
  final String tableName;
  final List<ForeignKey> foreignKeys;
  final bool omitPrimaryKey;
  final bool omitUniqueKeys;
  final List<ColumnKeyGroup> primaryKeyGroups;
  final List<ColumnKeyGroup> uniqueKeyGroups;
  final List<ReflectedField> editableFields;
  final ReflectionLibrary reflectionLibrary;

  const BuildSqlReflectedStructure({
    required this.reflectedEntity,
    required this.reflectedFields,
    required this.tableName,
    required this.reflectionLibrary,
    this.foreignKeys = const [],
    this.omitPrimaryKey = false,
    this.omitUniqueKeys = false,
    this.primaryKeyGroups = const [],
    this.uniqueKeyGroups = const [],
    this.editableFields = const [],
  });

  @override
  Result<SqlReflectedClassStructure<T>> execute() {
    final fieldColumnMap = <ReflectedField, SqlColumnFormat>{};

    for (final field in reflectedFields) {
      final columnName = field.name;
      final columnType = _getSqlTypeFromReflectedType(field);
      if (columnType == null) {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(
            message: 'Field %1 of class %2 has a type that cannot be mapped to a SQL type, so it cannot be reflected as a SQL table column',
            textParts: [field.name, reflectedEntity.classReflector.name],
          ),
        );
      }

      final columFormat = SqlColumnFormat(
        name: columnName,
        type: columnType,
        isAutoIncrement: false,
        isPrimaryKey: !omitPrimaryKey && field.anotations.any((x) => x == primaryKey),
        isUniqueKey: !omitUniqueKeys && field.anotations.any((x) => x == uniqueKey),
      );

      fieldColumnMap[field] = columFormat;
    }

    return ResultValue(
      content: SqlReflectedClassStructure(
        reflectionLibrary: reflectionLibrary,
        tableName: tableName,
        reflectedEntity: reflectedEntity,
        primaryKeyGroups: primaryKeyGroups,
        uniqueKeyGroups: uniqueKeyGroups,
        foreignKeys: foreignKeys,
        fieldColumnMap: fieldColumnMap,
        editableFields: editableFields.isNotEmpty ? editableFields : reflectedFields.where((x) => !x.readOnly).toList(),
      ),
    );
  }

  SqlColumnFormatType? _getSqlTypeFromReflectedType(ReflectedField field) {
    switch (field.reflectedType.reflectionMode) {
      case ReflectedTypeMode.primitive:
        final dartType = field.reflectedType.dartType;
        switch (dartType) {
          case const (String):
            return SqlColumnFormatType.text;
          case const (int):
            return SqlColumnFormatType.intWithoutLimit;
          case const (double):
            return SqlColumnFormatType.decimal;
          case const (bool):
            return SqlColumnFormatType.boolean;
          case const (DateTime):
            return SqlColumnFormatType.dateTime;
          case const (Uint8List):
          case const (ByteData):
          case const (List<int>):
            return SqlColumnFormatType.binary;
          default:
            return null;
        }
      case ReflectedTypeMode.enums:
        return SqlColumnFormatType.uint8;
      default:
        return null;
    }
  }
}
