import 'package:maxi_sql/src/enginers/sql_command.dart';
import 'package:maxi_framework/maxi_framework.dart';

/// Interface defining the functions of an SQL database connection, including command and query execution, as well as transaction management. When it is discarded, pending transactions will be canceled and connections will be closed
abstract interface class SqlDataConnector {
  /// Executes the provided SQL query command and returns the resulting table. If another command is active or a transaction is in progress, this query will be queued and executed once the current command or transaction finishes. If the connection is not active, it will attempt to connect before executing the query
  FutureResult<TableResult> executeQuery(SqlQueryCommand command);

  /// Executes the provided SQL delete command. If another command is active or a transaction is in progress, this command will be queued and executed once the current command or transaction finishes. If the connection is not active, it will attempt to connect before executing the command
  FutureResult<void> executeDelete(SqlDeleteCommand command);

  /// Executes the provided SQL update command. If another command is active or a transaction is in progress, this command will be queued and executed once the current command or transaction finishes. If the connection is not active, it will attempt to connect before executing the command
  FutureResult<void> executeUpdate(SqlUpdateCommand command);

  /// Executes the provided SQL insert command. If another command is active or a transaction is in progress, this command will be queued and executed once the current command or transaction finishes. If the connection is not active, it will attempt to connect before executing the command
  FutureResult<void> executeInsert(SqlInsertCommand command);
}
