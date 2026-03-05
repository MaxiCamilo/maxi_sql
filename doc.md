# Maxi SQL - Documentation

## Overview

**Maxi SQL** is a Dart library that provides a comprehensive interface-based foundation for SQL database operations. It serves as an abstraction layer that enables multiple SQL database implementations (such as SQLite, MariaDB, PostgreSQL, etc.) to adapt seamlessly to a unified API.

The library follows a **pluggable architecture** where the core interfaces define the contract, and concrete implementations can be created for different database engines without modifying the core library.

---

## Architecture

### Core Concept

Maxi SQL is built on the principle that **interfaces define contracts**, not implementations. This allows:

- ✅ Multiple database engines (SQLite, MariaDB, PostgreSQL, MySQL, etc.) to implement the same interfaces
- ✅ Applications to switch between database engines with minimal code changes
- ✅ Consistent API regardless of the underlying database system
- ✅ Easy testing and mocking of database operations

### Module Structure

The library is organized into two main modules:

1. **Engines Module** - Database connection and transaction management
2. **Query Module** - Query construction and data filtering

---

## Engines Module

The Engines module provides interfaces for managing database connections, configurations, and structures.

### Key Interfaces

#### 1. **SqlConfiguration**
An interface that represents the configuration needed to create a SQL engine.

```dart
abstract interface class SqlConfiguration {
  SqlEngine buildEngine();
}
```

**Purpose:** Encapsulates database-specific configuration details and provides a factory method to instantiate a `SqlEngine`.

**Usage Example:**
```dart
// A SQLite implementation would provide:
class SqliteSqlConfiguration implements SqlConfiguration {
  final String databasePath;
  
  SqliteSqlConfiguration(this.databasePath);
  
  @override
  SqlEngine buildEngine() {
    return SqliteSqlEngine(databasePath);
  }
}
```

---

#### 2. **SqlEngine**
The main interface for database operations. It manages connections and transaction lifecycle.

```dart
abstract interface class SqlEngine implements Disposable {
  bool get isActive;
  
  SqlDataConnector buildDataConnector();
  
  SqlStructure buildStructureManager();
  
  FutureResult<SqlTransaction> beginTransaction();
}
```

**Properties:**
- `isActive` - Indicates if the engine is operational and can create connections

**Methods:**
- `buildDataConnector()` - Creates a new database connection for executing queries and commands
- `buildStructureManager()` - Creates a structure manager for database schema operations
- `beginTransaction()` - Initiates a new transaction

**Lifecycle:**
- When the engine is disposed, all active connections are closed and pending transactions are canceled
- Implements `Disposable` for proper resource cleanup

---

#### 3. **SqlDataConnector**
Handles command and query execution against the database.

```dart
abstract interface class SqlDataConnector {
  FutureResult<TableResult> executeQuery(SqlQueryCommand command);
  
  FutureResult<void> executeDelete(SqlDeleteCommand command);
  
  FutureResult<void> executeUpdate(SqlUpdateCommand command);
  
  FutureResult<void> executeInsert(SqlInsertCommand command);
}
```

**Methods:**
- `executeQuery()` - Executes SELECT queries and returns results as a `TableResult`
- `executeDelete()` - Executes DELETE commands
- `executeUpdate()` - Executes UPDATE commands
- `executeInsert()` - Executes INSERT commands

**Features:**
- Commands are queued if another command is already executing
- Automatic connection establishment if needed
- Proper error handling through `FutureResult`

---

#### 4. **SqlTransaction**
Represents a database transaction with commit/rollback capabilities.

```dart
abstract interface class SqlTransaction implements SqlEngine {
  bool get confirmed;
  
  bool get wasCommitted;
  
  FutureResult<void> commit();
  
  FutureResult<void> rollback();
}
```

**Properties:**
- `confirmed` - Whether the transaction has been committed or rolled back
- `wasCommitted` - Whether the transaction completed successfully

**Methods:**
- `commit()` - Makes all changes permanent
- `rollback()` - Undoes all changes

**Behavior:**
- Extends `SqlEngine`, allowing transaction commands to be executed like regular commands
- Failed transactions are automatically rolled back upon disposal
- Prevents inconsistent state through proper error handling

---

#### 5. **SqlStructure**
Manages database schema and structure operations.

```dart
abstract interface class SqlStructure {
  // Methods for creating, modifying, and validating database tables
  // and managing database schemas
}
```

**Purpose:**
- Create and delete tables
- Validate table schemas
- Manage database structure operations
- Handle migrations and schema evolution

---

#### 6. **SqlCommand** (Related Types)
Represents SQL commands ready for execution.

**Command Types:**
- `SqlQueryCommand` - A SELECT query
- `SqlInsertCommand` - An INSERT statement
- `SqlUpdateCommand` - An UPDATE statement
- `SqlDeleteCommand` - A DELETE statement

**Purpose:** Encapsulates SQL command details in a type-safe manner, allowing different implementations to generate database-specific SQL syntax.

---

## Query Module

The Query module provides interfaces and utilities for constructing complex SQL queries in a type-safe, chainable manner.

### Key Interfaces

#### 1. **ColumnSelection**
Defines which columns to select in a query.

```dart
abstract interface class ColumnSelection {
  // Methods for specifying which columns to retrieve
}
```

**Purpose:** Build SELECT clauses with specific column specification or wildcard selection.

---

#### 2. **ColumnCondition**
Represents WHERE clause conditions.

```dart
abstract interface class ColumnCondition {
  // Methods for creating filter conditions
}
```

**Purpose:** Create type-safe WHERE clause conditions with operators like:
- Equality: `column == value`
- Comparison: `<`, `>`, `<=`, `>=`
- Pattern matching: `LIKE`
- Range: `BETWEEN`
- Null checks: `IS NULL`, `IS NOT NULL`

---

#### 3. **TableSelection**
Specifies which table(s) to query.

```dart
abstract interface class TableSelection {
  // Methods for selecting tables
}
```

**Purpose:** Define the primary table(s) being queried.

---

#### 4. **QueryJoiner**
Handles SQL JOIN operations.

```dart
abstract interface class QueryJoiner {
  // Methods for joining tables
}
```

**Purpose:** Construct JOINs between tables:
- INNER JOIN
- LEFT JOIN
- RIGHT JOIN
- FULL OUTER JOIN

---

#### 5. **QueryOrden** (Query Ordering)
Handles ORDER BY clauses.

```dart
abstract interface class QueryOrden {
  // Methods for ordering results
}
```

**Purpose:** Sort query results by one or more columns in ASC/DESC order.

---

#### 6. **ForeignKey**
Represents foreign key relationships.

```dart
abstract interface class ForeignKey {
  // Methods for managing foreign key constraints
}
```

**Purpose:** Define and manage relationships between tables.

---

#### 7. **ColumnKeyGroup**
Groups columns for aggregate functions.

```dart
abstract interface class ColumnKeyGroup {
  // Methods for GROUP BY operations
}
```

**Purpose:** Create GROUP BY clauses for aggregate queries.

---

## Usage Pattern

### Basic Flow

```
1. Create SqlConfiguration
   ↓
2. Build SqlEngine (using configuration)
   ↓
3. Build SqlDataConnector or SqlStructure
   ↓
4. Construct query using Query module interfaces
   ↓
5. Execute query via SqlDataConnector
   ↓
6. Process results
```

### Transaction Example

```
1. BeginTransaction() on SqlEngine
   ↓
2. Execute multiple commands via transaction
   ↓
3. Commit or Rollback
```

---

## Implementation Examples

### SQLite Implementation Structure

```
maxi_sqlite/
├── adapters/              # Convert generic interfaces to SQLite syntax
│   ├── column_condition_to_sqlite.dart
│   └── ...
├── enginer/               # SqlEngine implementation for SQLite
├── logic/                 # SQLite-specific logic
└── models/                # Data models
```

**Key Classes:**
- `SqliteSqlEngine` - Implements `SqlEngine`
- `SqliteSqlConfiguration` - Implements `SqlConfiguration`
- `SqliteDataConnector` - Implements `SqlDataConnector`
- Query adapters to convert generic query objects to SQLite SQL

### MariaDB Implementation (Future)

Similar structure would be created for MariaDB:
- `MariadbSqlEngine` - Implements `SqlEngine`
- `MariadbSqlConfiguration` - Implements `SqlConfiguration`
- MariaDB-specific adapters and drivers

---

## Benefits of This Architecture

### 1. **Flexibility**
- Switch database engines by changing configuration
- Support multiple databases in the same application

### 2. **Testability**
- Mock implementations for unit testing
- No actual database required during testing

### 3. **Maintainability**
- Clear separation of concerns
- Each implementation is isolated
- Easy to add new database engines

### 4. **Consistency**
- Unified API across different database systems
- Predictable behavior regardless of underlying engine
- Code remains database-agnostic

### 5. **Scalability**
- New database adapters can be added without modifying core
- Open/Closed Principle: open for extension, closed for modification

---

## Dependencies

**Core Dependencies:**
- `maxi_framework` - Provides base classes like `Disposable` and `FutureResult`
- `maxi_reflection` - Reflection utilities for type handling

**Why These Dependencies:**
- `Disposable` - Resource lifecycle management
- `FutureResult` - Unified error handling and async operations
- Reflection - Schema introspection and dynamic query building

---

## Error Handling

All asynchronous operations return `FutureResult<T>` which provides:

```dart
FutureResult<TableResult> result = connector.executeQuery(command);

if (result.isSuccess) {
  TableResult data = result.value;
  // Process data
} else {
  String error = result.error;
  // Handle error
}
```

**Benefits:**
- No exceptions thrown in normal operation
- Consistent error handling pattern
- Predictable error types

---

## Lifecycle Management

### Engine Lifecycle
```
SqlEngine created → buildConnector/buildStructure → dispose()
```

### Connector Lifecycle
```
Created → executeQuery/executeInsert/etc. → dispose()
```

### Transaction Lifecycle
```
beginTransaction() → executeCommands() → commit()/rollback() → dispose()
```

**Important:** Always dispose engines and connectors to prevent resource leaks.

---

## Extension Points

Implementations can extend by:

1. **Adding Database-Specific Features**
   - Pool management
   - Caching strategies
   - Custom SQL dialects

2. **Optimizations**
   - Query optimization
   - Connection pooling
   - Prepared statement caching

3. **Monitoring**
   - Query logging
   - Performance metrics
   - Connection statistics

---

## Best Practices

1. **Use SqlConfiguration for Setup**
   - Centralize database configuration
   - Make it easy to switch environments

2. **Proper Resource Disposal**
   ```dart
   var engine = configuration.buildEngine();
   try {
     // Use engine
   } finally {
     engine.dispose();
   }
   ```

3. **Use Transactions for Multi-Step Operations**
   ```dart
   var transaction = await engine.beginTransaction();
   try {
     await transaction.executeInsert(cmd1);
     await transaction.executeUpdate(cmd2);
     await transaction.commit();
   } catch (e) {
     await transaction.rollback();
   }
   ```

4. **Type-Safe Query Building**
   - Use query module interfaces
   - Avoid raw SQL strings when possible
   - Leverage compile-time type checking

---

## Roadmap & Future Enhancements

- PostgreSQL implementation
- MySQL implementation
- Connection pooling strategies
- Query caching layer
- Migration tools
- Schema validation utilities
- Performance monitoring and profiling

---

## Contributing

To implement a new database engine:

1. Create a new project (e.g., `maxi_postgresql`)
2. Implement core interfaces:
   - `SqlConfiguration`
   - `SqlEngine`
   - `SqlDataConnector`
   - `SqlStructure`
3. Implement query adapters to convert generic query objects to target SQL dialect
4. Add comprehensive tests
5. Document database-specific behaviors and limitations

---

## License

Refer to the LICENSE file in the repository.

---

## Support & Documentation

For more information, refer to:
- Individual implementation documentation (e.g., `maxi_sqlite/README.md`)
- API documentation in interface files
- Test files for usage examples
