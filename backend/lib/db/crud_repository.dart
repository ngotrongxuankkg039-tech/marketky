import 'mysql_database.dart';

class CrudRepository {
  CrudRepository({
    required this._database,
    required this.table,
    required this.allowedColumns,
  });

  final MySqlDatabase _database;
  final String table;
  final Set<String> allowedColumns;

  Future<List<Map<String, dynamic>>> findAll({String orderBy = 'id DESC'}) {
    _assertIdentifier(orderBy.replaceAll(' DESC', '').replaceAll(' ASC', ''));
    return _database.withConnection((connection) async {
      final results = await connection.query(
        'SELECT * FROM $table ORDER BY $orderBy',
      );
      return results
          .map((row) => Map<String, dynamic>.from(row.fields))
          .toList();
    });
  }

  Future<Map<String, dynamic>?> findById(int id) {
    return _database.withConnection((connection) async {
      final results = await connection.query(
        'SELECT * FROM $table WHERE id = ?',
        [id],
      );
      if (results.isEmpty) return null;
      return Map<String, dynamic>.from(results.first.fields);
    });
  }

  Future<int> insert(Map<String, dynamic> data) {
    final safeData = _safeData(data);
    return _database.withConnection((connection) async {
      final columns = safeData.keys.join(', ');
      final marks = safeData.keys.map((_) => '?').join(', ');
      final result = await connection.query(
        'INSERT INTO $table ($columns) VALUES ($marks)',
        safeData.values.toList(),
      );
      return result.insertId ?? 0;
    });
  }

  Future<void> update(int id, Map<String, dynamic> data) {
    final safeData = _safeData(data);
    return _database.withConnection((connection) async {
      final assignments = safeData.keys
          .map((column) => '$column = ?')
          .join(', ');
      await connection.query('UPDATE $table SET $assignments WHERE id = ?', [
        ...safeData.values,
        id,
      ]);
    });
  }

  Future<void> delete(int id) {
    return _database.withConnection((connection) async {
      await connection.query('DELETE FROM $table WHERE id = ?', [id]);
    });
  }

  Map<String, dynamic> _safeData(Map<String, dynamic> data) {
    return {
      for (final entry in data.entries)
        if (allowedColumns.contains(entry.key)) entry.key: entry.value,
    };
  }

  void _assertIdentifier(String value) {
    final clean = value.replaceAll('_', '').replaceAll('.', '');
    if (clean.isEmpty || clean.contains(RegExp(r'[^a-zA-Z0-9]'))) {
      throw ArgumentError('Unsafe SQL identifier: $value');
    }
  }
}
