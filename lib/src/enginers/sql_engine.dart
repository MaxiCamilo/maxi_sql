import 'package:maxi_sql/src/enginers/sql_data_connector.dart';
import 'package:maxi_sql/src/enginers/sql_structure.dart';
import 'package:maxi_framework/maxi_framework.dart';

/// Interface defining the functions of an SQL engine, including connection and structure management. When it is discarded, all active connections will be closed and pending transactions will be canceled
abstract interface class SqlEngine implements Disposable {
  /// Indicates whether the engine is active and can be used to build connections and structure managers. If it is discarded, this will be false
  bool get isActive;

  /// Builds a new SQL connection, allowing to execute commands and queries, as well as manage transactions
  SqlDataConnector buildDataConnector();

  /// Builds a new SQL structure manager, allowing to manage the structure of the database, such as creating and deleting tables, as well as validating table schemas
  SqlStructure buildStructureManager();
}
