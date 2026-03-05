# Maxi SQL

A powerful Dart library that provides **interface-based abstractions** for SQL database operations. Maxi SQL serves as the foundation for consistent database interactions across different SQL engines (SQLite, MariaDB, PostgreSQL, etc.).

## 🎯 Purpose

Maxi SQL defines a unified interface contract for database operations, allowing:

- **Multiple Implementations** - SQLite, MariaDB, PostgreSQL, MySQL, and other SQL databases can implement the same interfaces
- **Database Agnostic Code** - Write your application once and switch databases with configuration changes only
- **Type-Safe Operations** - Leverage Dart's type system for database queries and commands
- **Consistent API** - Same interface regardless of underlying database engine

## 📦 Core Modules

### 1. Engines Module
Manages connections, transactions, and database structure:
- **SqlConfiguration** - Database configuration factory
- **SqlEngine** - Main connection and transaction manager
- **SqlDataConnector** - Query and command executor
- **SqlTransaction** - ACID transaction support
- **SqlStructure** - Database schema management
- **SqlCommand** - Type-safe command representation

### 2. Query Module
Constructs type-safe SQL queries:
- **TableSelection** - Table specification
- **ColumnSelection** - Column selection and projection
- **ColumnCondition** - WHERE clause conditions
- **QueryJoiner** - JOIN operations
- **QueryOrden** - ORDER BY clauses
- **ColumnKeyGroup** - GROUP BY operations
- **ForeignKey** - Foreign key relationships

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│     Your Application Code               │
│  (Database Agnostic - Uses Interfaces)  │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Maxi SQL (Core Interfaces)         │
│  Engines Module │ Query Module          │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┼────────────────┐
    │            │                │
┌───▼──┐  ┌─────▼────┐  ┌───────▼───┐
│SQLite│  │ MariaDB  │  │PostgreSQL │
│ Impl │  │   Impl   │  │   Impl    │
└──────┘  └──────────┘  └───────────┘
```

## 💡 Key Concepts

### Interface-First Design
The library defines **what** database operations should do, not **how** to implement them. This separation allows different databases to provide their own optimized implementations.

### Pluggable Architecture
Concrete implementations (like SQLite or MariaDB adapters) implement the core interfaces without modifying the library itself.

### Resource Management
Proper lifecycle management through Dart's `Disposable` pattern ensures connections and transactions are properly cleaned up.

### Unified Error Handling
All async operations use `FutureResult<T>` for consistent, safe error handling without exceptions.

## 🚀 Quick Start

### 1. Configure Database Engine

```dart
// Create configuration (implementation-specific)
SqliteSqlConfiguration config = SqliteSqlConfiguration('/path/to/database.db');
```

### 2. Build Engine

```dart
SqlEngine engine = config.buildEngine();
```

### 3. Execute Queries

```dart
// Create data connector
var connector = engine.buildDataConnector();

// Execute query
var result = await connector.executeQuery(queryCommand);
```

### 4. Use Transactions

```dart
// Begin transaction
var transaction = await engine.beginTransaction();

try {
  await transaction.executeInsert(insertCommand);
  await transaction.executeUpdate(updateCommand);
  await transaction.commit();
} catch (e) {
  await transaction.rollback();
}
```

## 🔌 Implementation Examples

### SQLite
Implementation provided by **maxi_sqlite** package:
- Full transaction support
- Query result mapping
- Schema management

### MariaDB (Future)
Implementation provided by **maxi_mariadb** package:
- Connection pooling
- Advanced query features
- Native MariaDB optimizations

## 📚 Documentation

For detailed documentation, see [doc.md](./doc.md) which includes:
- Complete interface specifications
- Usage patterns and examples
- Best practices
- Implementation guidelines
- Extension points

## ✨ Features

✅ Type-safe database operations  
✅ Database-agnostic application code  
✅ ACID transaction support  
✅ Flexible query building  
✅ Schema management  
✅ Consistent error handling  
✅ Proper resource lifecycle  
✅ Extensible architecture  

## 📋 Dependencies

- **maxi_framework** - Core abstractions and base classes
- **maxi_reflection** - Type introspection utilities

## 🤝 Contributing

To implement a database adapter:

1. Create a new package (e.g., `maxi_mariadb`)
2. Implement all core interfaces
3. Add query-to-SQL adapters
4. Create comprehensive tests
5. Document database-specific features

## 📄 License

See [LICENSE](./LICENSE) file

## 📖 Related Packages

- **maxi_sqlite** - SQLite implementation
- **maxi_framework** - Core framework
- **maxi_reflection** - Reflection utilities

---

**Maxi SQL** - Building the foundation for flexible, scalable SQL database applications in Dart.
