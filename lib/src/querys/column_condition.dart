import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ColumnCondition {}

class ColumnCompareValue implements ColumnCondition {
  final String columnName;
  final String tableName;
  final Conditionator conditionator;

  const ColumnCompareValue({required this.columnName, required this.conditionator, this.tableName = ''});
}

class ColumnCompareTwoColumns implements ColumnCondition {
  final String columnName1;
  final String tableName1;
  final String columnName2;
  final String tableName2;
  final ConditionCompareType condition;

  const ColumnCompareTwoColumns({required this.columnName1, required this.columnName2, this.tableName1 = '', this.tableName2 = '', this.condition = ConditionCompareType.equal});
}



