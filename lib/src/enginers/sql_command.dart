import 'package:maxi_sql/maxi_sql.dart';

/// These interfaces define the structure of SQL commands
abstract interface class SqlCommand {}

/// Command that defines a SQL query, can be to one or several tables,
/// with their specific filters, sorters and what specific data is desired to be obtained.
/// If no columns are specified, all columns from the specified table or tables will be obtained.
/// If no conditions are specified, all data from the specified table/s will be obtained.
class SqlQueryCommand implements SqlCommand {
  final List<ColumnSelection> columns;
  final List<TableSelection> tables;
  final List<ColumnCondition> conditions;
  final List<QueryJoiner> joinedTables;
  final List<QueryOrder> orders;
  final List<String> grouped;
  final List<ColumnCondition> having;
  final int? limit;

  const SqlQueryCommand({required this.tables, this.columns = const [], this.conditions = const [], this.orders = const [], this.grouped = const [], this.having = const [], this.limit, this.joinedTables = const []});
}

/// Signature for objects that perform write operations, such as insert, update, delete
abstract interface class SqlWriteCommand implements SqlCommand {}

/// Command that deletes specific data from a table according to the specified conditions. If no conditions are specified, it will delete all data from the table.
class SqlDeleteCommand implements SqlWriteCommand {
  final String tableName;
  final List<ColumnCondition> conditions;

  const SqlDeleteCommand({required this.tableName, this.conditions = const []});
}

/// Command that inserts new data into a table, with the specified values for each column. The keys of the values map correspond to the column names, and the values correspond to the values to be inserted in those columns
class SqlInsertCommand implements SqlWriteCommand {
  final String tableName;
  final Map<String, dynamic> values;

  const SqlInsertCommand({required this.tableName, required this.values});
}

/// Command that updates existing data in a table, setting the specified values for each column according to the specified conditions. The keys of the values map correspond to the column names, and the values correspond to the new values to be set in those columns. If no conditions are specified, it will update all data from the table with the provided values
class SqlUpdateCommand implements SqlWriteCommand {
  final String tableName;
  final Map<String, dynamic> values;
  final List<ColumnCondition> conditions;

  const SqlUpdateCommand({required this.tableName, required this.values, this.conditions = const []});
}

/// Signature for objects that create tables, used in the structure manager
class SqlTableCreator implements SqlCommand {
  final String name;
  final List<SqlColumnFormat> columns;
  final List<ColumnKeyGroup> primaryKeyGroups;
  final List<ColumnKeyGroup> uniqueKeyGroups;
  final List<ForeignKey> foreignKeys;

  const SqlTableCreator({required this.name, required this.columns, required this.primaryKeyGroups, required this.uniqueKeyGroups, required this.foreignKeys});
}
