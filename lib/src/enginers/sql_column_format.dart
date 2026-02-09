/// Data types contained in the column. The system will convert them to a Dart-compatible format. When writing to the database, the system will do the same but adapt them according to what the database engine supports (if unsupported, an alternative will be used, for example: uintx -> number in sqlite)
enum SqlColumnFormatType { text, boolean, intWithoutLimit, int8, int16, int32, int64, uintWithoutLimit, uint8, uint16, uint32, uint64, doubleWithoutLimit, decimal, dateTime, binary, dynamicType }

/// Defines the structure of a column, including what data it will receive, whether it is a primary key, unique key, and if it is auto-incremented. This is used to create a table and to adapt the data of an existing column.
class SqlColumnFormat {
  final String name;
  final SqlColumnFormatType type;
  final bool isPrimaryKey;
  final bool isUniqueKey;
  final bool isAutoIncrement;

  const SqlColumnFormat({required this.name, required this.type, required this.isPrimaryKey, required this.isUniqueKey, required this.isAutoIncrement});
}
