enum ColumnSelectionFunction { field, count, maximum, minimum, average, sum }

class ColumnSelection {
  final ColumnSelectionFunction function;
  final String columnName;
  final String tableName;
  final String alias;
  const ColumnSelection({required this.columnName, this.function = ColumnSelectionFunction.field, this.tableName = '', this.alias = ''});
}
