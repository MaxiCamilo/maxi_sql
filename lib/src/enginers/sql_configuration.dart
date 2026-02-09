import 'package:maxi_db/src/enginers/sql_engine.dart';

/// Signalizes the configuration of a SQL engine, allowing to build it and use it in the application
abstract interface class SqlConfiguration {
  /// Builds a new SQL engine based on the configuration, allowing to manage connections and database structures
  SqlEngine buildEngine();
}
