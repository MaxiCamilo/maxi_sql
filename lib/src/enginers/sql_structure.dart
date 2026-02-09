import 'package:maxi_db/src/enginers/sql_command.dart';
import 'package:maxi_framework/maxi_framework.dart';

/// Defines functions to manage database structures, such as creating and deleting tables, as well as validating table schemas. When it is discarded, all pending operations will be canceled.
abstract interface class SqlStructure {
  /// Checks if a table with the given name exists in the database, returning true if it exists and false if it does not. If the connection is not active, it will attempt to connect before checking the table existence 
  FutureResult<bool> checkTableExists({required String tableName});
  /// Creates a new table in the database using the provided SQL table creator command. If the connection is not active, it will attempt to connect before creating the table. If a table with the same name already exists, this will return an error  
  FutureResult<void> createTable({required SqlTableCreator command});
  /// Deletes the table with the given name from the database. If the connection is not active, it will attempt to connect before deleting the table. If the table does not exist, this will return an error  
  Future<bool> deleteTable({required String tableName});
  /// Validates the schema of the table using the provided SQL table creator command. If the connection is not active, it will attempt to connect before validating the table schema. If the table does not exist or if the schema is invalid, this will return an error
  FutureResult<void> validateTableSchema({required SqlTableCreator command});
}
