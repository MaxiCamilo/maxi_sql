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

  FutureResult<SqlTransaction> beginTransaction();
}

/// Interface defining the functions of an SQL transaction, allowing to execute multiple commands in a single unit of work, with the ability to commit or roll back the changes. When it is discarded, pending commands will be canceled and the transaction will be rolled back if it was not already confirmed
abstract interface class SqlTransaction implements SqlEngine {
  /// Indicates whether the command was committed or rolled back
  bool get confirmed;

  /// Indicates whether the transaction completed successfully
  bool get wasCommitted;

  /// Commits the transaction, making all changes permanent. If the transaction was already confirmed, this will do nothing. If the transaction was rolled back, this will return an error
  FutureResult<void> commit();

  /// Rolls back the transaction, undoing all changes. If the transaction was already confirmed, this will return an error. If the transaction was already rolled back, this will do nothing
  FutureResult<void> rollback();
}
