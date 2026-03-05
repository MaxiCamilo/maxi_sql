# Maxi SQL - Implementation Guide

This guide explains how to create a new SQL database adapter for Maxi SQL (e.g., MariaDB, PostgreSQL, etc.).

## Table of Contents

1. [Project Structure](#project-structure)
2. [Core Interface Implementations](#core-interface-implementations)
3. [Query Adapters](#query-adapters)
4. [Connection Management](#connection-management)
5. [Error Handling](#error-handling)
6. [Testing](#testing)
7. [Publishing](#publishing)

---

## Project Structure

Create a new Dart package following this structure:

```
maxi_DBNAME/
├── lib/
│   ├── maxi_DBNAME.dart              # Main export file
│   └── src/
│       ├── adapters/                 # Query-to-SQL converters
│       │   ├── column_condition_adapter.dart
│       │   ├── column_selection_adapter.dart
│       │   ├── query_joiner_adapter.dart
│       │   └── ...other adapters
│       ├── engine/                   # Core engine implementations
│       │   ├── DBNAME_sql_configuration.dart
│       │   ├── DBNAME_sql_engine.dart
│       │   ├── DBNAME_data_connector.dart
│       │   ├── DBNAME_transaction.dart
│       │   ├── DBNAME_structure.dart
│       │   └── DBNAME_connection.dart
│       ├── models/                   # Data models and DTOs
│       │   ├── connection_pool.dart
│       │   ├── column_info.dart
│       │   └── query_context.dart
│       └── utils/                    # Utility functions
│           ├── sql_builder.dart
│           ├── type_mapper.dart
│           └── validators.dart
├── test/
│   ├── adapters/
│   ├── engine/
│   └── integration/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

---

## Core Interface Implementations

### 1. SqlConfiguration Implementation

```dart
import 'package:maxi_sql/maxi_sql.dart';

class PostgresqlSqlConfiguration implements SqlConfiguration {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final int maxConnections;
  
  PostgresqlSqlConfiguration({
    required this.host,
    this.port = 5432,
    required this.database,
    required this.username,
    required this.password,
    this.maxConnections = 10,
  });
  
  @override
  SqlEngine buildEngine() {
    return PostgresqlSqlEngine(this);
  }
}
```

**Key Points:**
- Store all configuration needed to connect to the database
- Provide sensible defaults for optional parameters
- Validate configuration in constructor or during engine building

---

### 2. SqlEngine Implementation

```dart
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_framework/maxi_framework.dart';

class PostgresqlSqlEngine implements SqlEngine {
  final PostgresqlSqlConfiguration _configuration;
  final ConnectionPool _connectionPool;
  bool _isDisposed = false;
  
  PostgresqlSqlEngine(this._configuration) 
    : _connectionPool = ConnectionPool(
        configuration: _configuration,
        initialConnections: 1,
        maxConnections: _configuration.maxConnections,
      );
  
  @override
  bool get isActive => !_isDisposed;
  
  @override
  SqlDataConnector buildDataConnector() {
    if (_isDisposed) {
      throw StateError('Engine has been disposed');
    }
    return PostgresqlDataConnector(_connectionPool);
  }
  
  @override
  SqlStructure buildStructureManager() {
    if (_isDisposed) {
      throw StateError('Engine has been disposed');
    }
    return PostgresqlStructure(_connectionPool);
  }
  
  @override
  FutureResult<SqlTransaction> beginTransaction() async {
    if (_isDisposed) {
      return FutureResult.error('Engine has been disposed');
    }
    
    try {
      final connection = await _connectionPool.acquire();
      await connection.execute('BEGIN TRANSACTION');
      return FutureResult.success(
        PostgresqlTransaction(_connectionPool, connection),
      );
    } catch (e) {
      return FutureResult.error(e.toString());
    }
  }
  
  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _connectionPool.dispose();
    }
  }
}
```

**Key Points:**
- Implement state management (`isActive`, disposal tracking)
- Return proper error results from async operations
- Clean up resources in `dispose()`
- Maintain isolation between different connectors/transactions

---

### 3. SqlDataConnector Implementation

```dart
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_framework/maxi_framework.dart';

class PostgresqlDataConnector implements SqlDataConnector {
  final ConnectionPool _connectionPool;
  final QueryQueue _commandQueue = QueryQueue();
  
  PostgresqlDataConnector(this._connectionPool);
  
  @override
  FutureResult<TableResult> executeQuery(SqlQueryCommand command) async {
    return _commandQueue.enqueue(() async {
      try {
        final connection = await _connectionPool.acquire();
        
        final sql = PostgresqlQueryBuilder().build(command);
        final result = await connection.query(sql, command.parameters);
        
        return FutureResult.success(_mapToTableResult(result));
      } catch (e) {
        return FutureResult.error(e.toString());
      }
    });
  }
  
  @override
  FutureResult<void> executeInsert(SqlInsertCommand command) async {
    return _commandQueue.enqueue(() async {
      try {
        final connection = await _connectionPool.acquire();
        
        final sql = PostgresqlCommandBuilder().buildInsert(command);
        await connection.execute(sql, command.parameters);
        
        return FutureResult.success(null);
      } catch (e) {
        return FutureResult.error(e.toString());
      }
    });
  }
  
  @override
  FutureResult<void> executeUpdate(SqlUpdateCommand command) async {
    return _commandQueue.enqueue(() async {
      try {
        final connection = await _connectionPool.acquire();
        
        final sql = PostgresqlCommandBuilder().buildUpdate(command);
        await connection.execute(sql, command.parameters);
        
        return FutureResult.success(null);
      } catch (e) {
        return FutureResult.error(e.toString());
      }
    });
  }
  
  @override
  FutureResult<void> executeDelete(SqlDeleteCommand command) async {
    return _commandQueue.enqueue(() async {
      try {
        final connection = await _connectionPool.acquire();
        
        final sql = PostgresqlCommandBuilder().buildDelete(command);
        await connection.execute(sql, command.parameters);
        
        return FutureResult.success(null);
      } catch (e) {
        return FutureResult.error(e.toString());
      }
    });
  }
  
  TableResult _mapToTableResult(DatabaseResult dbResult) {
    return TableResult(
      rows: dbResult.rows.map((row) => _mapRowToMap(row)).toList(),
      affectedRows: dbResult.affectedRows,
      columnNames: dbResult.columnNames,
    );
  }
  
  Map<String, dynamic> _mapRowToMap(DatabaseRow row) {
    final map = <String, dynamic>{};
    for (final column in row.columns) {
      map[column.name] = column.value;
    }
    return map;
  }
}
```

**Key Points:**
- Use a queue (`QueryQueue`) to serialize command execution
- Acquire connections from pool for each operation
- Convert database-specific results to `TableResult`
- Properly handle resource cleanup
- Use parameterized queries to prevent SQL injection

---

### 4. SqlTransaction Implementation

```dart
class PostgresqlTransaction 
    implements SqlTransaction {
  final ConnectionPool _connectionPool;
  final DatabaseConnection _connection;
  bool _confirmed = false;
  bool _wasCommitted = false;
  bool _isDisposed = false;
  
  PostgresqlTransaction(this._connectionPool, this._connection);
  
  @override
  bool get confirmed => _confirmed;
  
  @override
  bool get wasCommitted => _wasCommitted;
  
  @override
  bool get isActive => !_isDisposed;
  
  // Implement SqlEngine methods to execute commands within transaction
  // All commands execute on _connection instead of acquiring new ones
  
  @override
  FutureResult<void> commit() async {
    if (_confirmed) {
      return FutureResult.success(null);
    }
    
    try {
      await _connection.execute('COMMIT');
      _confirmed = true;
      _wasCommitted = true;
      return FutureResult.success(null);
    } catch (e) {
      return FutureResult.error(e.toString());
    }
  }
  
  @override
  FutureResult<void> rollback() async {
    if (_confirmed) {
      return FutureResult.error(
        'Cannot rollback an already confirmed transaction',
      );
    }
    
    try {
      await _connection.execute('ROLLBACK');
      _confirmed = true;
      _wasCommitted = false;
      return FutureResult.success(null);
    } catch (e) {
      return FutureResult.error(e.toString());
    }
  }
  
  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      if (!_confirmed) {
        try {
          await _connection.execute('ROLLBACK');
        } catch (_) {
          // Ignore rollback errors
        }
      }
      _isDisposed = true;
      await _connectionPool.release(_connection);
    }
  }
}
```

**Key Points:**
- Always use the same connection for all transaction commands
- Track transaction state (confirmed, committed)
- Auto-rollback on disposal if not confirmed
- Prevent operations after confirmation
- Release connection back to pool on disposal

---

### 5. SqlStructure Implementation

```dart
class PostgresqlStructure implements SqlStructure {
  final ConnectionPool _connectionPool;
  
  PostgresqlStructure(this._connectionPool);
  
  /// Create a table with the specified schema
  Future<bool> createTable(String tableName, List<ColumnDefinition> columns) async {
    try {
      final connection = await _connectionPool.acquire();
      final sql = _buildCreateTableSql(tableName, columns);
      await connection.execute(sql);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if a table exists
  Future<bool> tableExists(String tableName) async {
    try {
      final connection = await _connectionPool.acquire();
      final result = await connection.query(
        '''
        SELECT EXISTS (
          SELECT 1 FROM information_schema.tables 
          WHERE table_name = @tableName
        )
        ''',
        {'tableName': tableName},
      );
      return result.rows.isNotEmpty && result.rows.first['exists'] == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get table schema information
  Future<TableSchema?> describeTable(String tableName) async {
    try {
      final connection = await _connectionPool.acquire();
      final result = await connection.query(
        '''
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = @tableName
        ORDER BY ordinal_position
        ''',
        {'tableName': tableName},
      );
      
      return TableSchema(
        tableName: tableName,
        columns: result.rows
            .map((row) => ColumnInfo(
              name: row['column_name'],
              type: row['data_type'],
              nullable: row['is_nullable'] == 'YES',
              defaultValue: row['column_default'],
            ))
            .toList(),
      );
    } catch (e) {
      return null;
    }
  }
  
  String _buildCreateTableSql(
    String tableName,
    List<ColumnDefinition> columns,
  ) {
    // Implementation specific to PostgreSQL syntax
    // Handle primary keys, foreign keys, constraints, etc.
  }
}
```

**Key Points:**
- Use database-specific queries to inspect schema
- Handle table existence and validation
- Provide schema information retrieval
- Support table creation with proper syntax

---

## Query Adapters

Query adapters convert generic Maxi SQL query objects into database-specific SQL syntax.

### ColumnCondition Adapter Example

```dart
class PostgresqlColumnConditionAdapter {
  String adaptCondition(ColumnCondition condition) {
    // Convert generic condition to PostgreSQL WHERE clause
    
    if (condition is EqualityCondition) {
      return '${condition.column} = ${_formatValue(condition.value)}';
    }
    
    if (condition is ComparisonCondition) {
      return '${condition.column} ${condition.operator} ${_formatValue(condition.value)}';
    }
    
    if (condition is RangeCondition) {
      return '${condition.column} BETWEEN ${_formatValue(condition.min)} '
             'AND ${_formatValue(condition.max)}';
    }
    
    if (condition is InCondition) {
      final values = condition.values
          .map(_formatValue)
          .join(', ');
      return '${condition.column} IN ($values)';
    }
    
    // Handle other conditions...
    throw UnsupportedError('Unsupported condition type');
  }
  
  String _formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String) return "'$value'";
    if (value is DateTime) return "'${value.toIso8601String()}'";
    return value.toString();
  }
}
```

### Query Builder Pattern

```dart
class PostgresqlQueryBuilder {
  String build(SqlQueryCommand command) {
    final buffer = StringBuffer('SELECT ');
    
    // Add columns
    buffer.write(_buildSelectClause(command));
    
    // Add FROM
    buffer.write(' FROM ');
    buffer.write(_buildFromClause(command));
    
    // Add WHERE
    if (command.conditions.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(_buildWhereClause(command.conditions));
    }
    
    // Add JOINs
    if (command.joins.isNotEmpty) {
      buffer.write(_buildJoinClauses(command.joins));
    }
    
    // Add GROUP BY
    if (command.groupBy.isNotEmpty) {
      buffer.write(' GROUP BY ');
      buffer.write(command.groupBy.join(', '));
    }
    
    // Add ORDER BY
    if (command.orderBy.isNotEmpty) {
      buffer.write(' ORDER BY ');
      buffer.write(_buildOrderByClause(command.orderBy));
    }
    
    // Add LIMIT/OFFSET
    if (command.limit != null) {
      buffer.write(' LIMIT ${command.limit}');
    }
    if (command.offset != null) {
      buffer.write(' OFFSET ${command.offset}');
    }
    
    return buffer.toString();
  }
  
  // Helper methods...
}
```

**Key Points:**
- Create one adapter per query component type
- Handle database-specific SQL syntax variations
- Use parameterized queries for security
- Properly escape and format values
- Support all query types and combinations

---

## Connection Management

### Connection Pool Pattern

```dart
class ConnectionPool {
  final Configuration _configuration;
  late final List<DatabaseConnection> _connections;
  final Queue<DatabaseConnection> _availableConnections = Queue();
  final int _maxConnections;
  bool _isDisposed = false;
  
  ConnectionPool({
    required Configuration configuration,
    required int initialConnections,
    required int maxConnections,
  })  : _configuration = configuration,
        _maxConnections = maxConnections {
    _initializeConnections(initialConnections);
  }
  
  /// Acquire a connection from the pool
  Future<DatabaseConnection> acquire() async {
    if (_isDisposed) {
      throw StateError('Connection pool has been disposed');
    }
    
    if (_availableConnections.isNotEmpty) {
      return _availableConnections.removeFirst();
    }
    
    if (_connections.length < _maxConnections) {
      final connection = await _createConnection();
      _connections.add(connection);
      return connection;
    }
    
    // Wait for a connection to become available
    return _waitForAvailableConnection();
  }
  
  /// Release a connection back to the pool
  Future<void> release(DatabaseConnection connection) async {
    if (!_isDisposed && connection.isActive) {
      _availableConnections.addLast(connection);
    } else if (!connection.isActive) {
      await connection.close();
    }
  }
  
  /// Create and connect to database
  Future<DatabaseConnection> _createConnection() async {
    final connection = DatabaseConnection(_configuration);
    await connection.connect();
    return connection;
  }
  
  /// Initialize pool with initial connections
  void _initializeConnections(int count) {
    // Create initial connections
  }
  
  /// Dispose all connections
  Future<void> dispose() async {
    _isDisposed = true;
    for (final connection in _connections) {
      await connection.close();
    }
    _connections.clear();
    _availableConnections.clear();
  }
  
  Future<DatabaseConnection> _waitForAvailableConnection() async {
    // Implement waiting logic with timeout
  }
}
```

**Key Points:**
- Reuse connections for efficiency
- Implement timeout for connection acquisition
- Handle connection validation before reuse
- Clean up inactive connections
- Prevent connection leaks

---

## Error Handling

```dart
class DatabaseErrorMapper {
  FutureResult<T> mapError<T>(Exception e, String context) {
    if (e is ConnectionException) {
      return FutureResult.error(
        'Connection failed: ${e.message}',
        severity: ErrorSeverity.critical,
      );
    }
    
    if (e is QueryException) {
      return FutureResult.error(
        'Query execution failed: ${e.message}',
        severity: ErrorSeverity.high,
      );
    }
    
    if (e is ConstraintViolationException) {
      return FutureResult.error(
        'Constraint violation: ${e.message}',
        severity: ErrorSeverity.medium,
      );
    }
    
    return FutureResult.error(
      'Database error: ${e.toString()}',
      context: context,
    );
  }
}
```

**Key Points:**
- Map database-specific exceptions to standard errors
- Provide meaningful error messages
- Include error context and severity
- Never expose database connection strings or sensitive data

---

## Testing

### Unit Tests

```dart
void main() {
  group('PostgresqlSqlConfiguration', () {
    test('should build valid engine', () {
      final config = PostgresqlSqlConfiguration(
        host: 'localhost',
        database: 'test_db',
        username: 'user',
        password: 'pass',
      );
      
      final engine = config.buildEngine();
      expect(engine, isA<PostgresqlSqlEngine>());
      expect(engine.isActive, isTrue);
    });
  });
  
  group('PostgresqlDataConnector', () {
    late PostgresqlSqlEngine engine;
    late SqlDataConnector connector;
    
    setUp(() async {
      engine = _buildTestEngine();
      connector = engine.buildDataConnector();
      // Create test tables
    });
    
    tearDown(() async {
      await engine.dispose();
    });
    
    test('should execute query and return results', () async {
      final command = SqlQueryCommand(
        table: 'users',
        columns: ['id', 'name'],
      );
      
      final result = await connector.executeQuery(command);
      expect(result.isSuccess, isTrue);
      expect(result.value, isA<TableResult>());
    });
    
    test('should handle insert command', () async {
      final command = SqlInsertCommand(
        table: 'users',
        values: {'name': 'John', 'email': 'john@example.com'},
      );
      
      final result = await connector.executeInsert(command);
      expect(result.isSuccess, isTrue);
    });
  });
}
```

### Integration Tests

```dart
void main() {
  group('PostgreSQL Integration Tests', () {
    late PostgresqlSqlEngine engine;
    
    setUpAll(() async {
      // Start test database
      engine = _startTestDatabase();
    });
    
    tearDownAll(() async {
      // Stop test database
      await engine.dispose();
    });
    
    test('transaction commit should persist data', () async {
      final transaction = await engine.beginTransaction();
      
      // Insert data
      // Update data
      // Commit
      
      // Verify data persists
    });
    
    test('transaction rollback should discard changes', () async {
      final transaction = await engine.beginTransaction();
      
      // Insert data
      // Rollback
      
      // Verify data doesn't exist
    });
  });
}
```

**Key Points:**
- Test each interface implementation thoroughly
- Use test databases (Docker containers recommended)
- Test error scenarios and edge cases
- Verify resource cleanup
- Integration tests should test real database interactions

---

## Publishing

### 1. Update pubspec.yaml

```yaml
name: maxi_postgresql
description: PostgreSQL implementation for Maxi SQL database abstraction library
version: 1.0.0
publish_to: none  # or pub.dev

environment:
  sdk: ^3.10.8

dependencies:
  maxi_sql:
    path: ../maxi_sql
  maxi_framework:
    path: ../maxi_framework
  postgres: ^3.0.0  # PostgreSQL driver

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.0
  testcontainers: ^0.1.0
```

### 2. Create README

Document:
- Installation instructions
- Configuration examples
- Database-specific features
- Connection pooling details
- Performance considerations
- Known limitations

### 3. Add CHANGELOG

```markdown
## 1.0.0
- Initial release
- Full SqlEngine implementation
- QueryBuilder with all adapters
- Connection pooling
- Transaction support
- Schema management
```

---

## Best Practices

### 1. **Connection Safety**
- Always return connections to pool
- Implement connection validation
- Handle connection timeouts gracefully

### 2. **Query Performance**
- Use parameterized queries
- Implement query result caching (optional)
- Handle pagination efficiently
- Provide query execution logging (optional)

### 3. **Type Safety**
- Leverage Dart's type system
- Map database types to Dart types correctly
- Handle NULL values consistently

### 4. **Error Recovery**
- Implement retry logic for transient failures
- Provide clear error messages
- Log errors for debugging

### 5. **Resource Cleanup**
- Implement `Disposable` pattern correctly
- Clean up connections and transactions
- Prevent resource leaks through tests

### 6. **Documentation**
- Document database-specific behavior
- Provide configuration examples
- Explain performance implications
- List known limitations

---

## Checklist for New Implementation

- [ ] Implement `SqlConfiguration`
- [ ] Implement `SqlEngine`
- [ ] Implement `SqlDataConnector`
- [ ] Implement `SqlTransaction`
- [ ] Implement `SqlStructure`
- [ ] Create query adapters for all query types
- [ ] Implement connection pooling
- [ ] Add comprehensive error handling
- [ ] Write unit tests (>80% coverage)
- [ ] Write integration tests
- [ ] Create detailed README
- [ ] Document database-specific features
- [ ] Test resource cleanup and disposal
- [ ] Performance testing
- [ ] Security review (SQL injection prevention)
- [ ] Publish to pub.dev

---

## Support

For questions or issues implementing a new database adapter, refer to:
- Maxi SQL core documentation
- maxi_sqlite implementation as reference
- Existing test cases
- Dart documentation for async patterns

---

**Happy implementing!** 🚀
