import 'package:maxi_db/maxi_sql.dart';

enum QueryJoinerFunction { inner, left, right, fullOuter }

class QueryJoiner {
  final ColumnSelection originTable;
  final ColumnSelection externalTable;
  final QueryJoinerFunction type;
  final List<ColumnCompareTwoColumns> comparers;

  const QueryJoiner({required this.originTable, required this.externalTable, required this.comparers, this.type = QueryJoinerFunction.inner});
}
