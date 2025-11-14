import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../Models/song_object.dart';

class DBHelper {
  // Singleton pattern
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sound_bits.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Called when database is first created
  Future<void> _onCreate(Database db, int version) async {
    print('Database created at version $version');

    // Create session table
    await db.execute('''
      CREATE TABLE session (
        id INTEGER PRIMARY KEY,
        currentSong TEXT,
        queue TEXT,
        folderName TEXT
      )
    ''');
    print('Session table created');
  }

  // Save session (current song, queue, folder name)
  Future<void> saveSession({
    required Song currentSong,
    required List<Song> queue,
    required String folderName,
  }) async {
    final db = await database;

    final data = {
      'id': 1, // <-- Always overwrite row with id 1
      'currentSong': jsonEncode(currentSong.toMap()),
      'queue': jsonEncode(queue.map((s) => s.toMap()).toList()),
      'folderName': folderName,
    };

    // Insert or replace existing session
    await db.insert(
      'session',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace, // replaces the row with the same id
    );

    print("Session saved in DB (overwritten id=1)");
  }


  // Restore session
  Future<Map<String, dynamic>?> getSession() async {
    final db = await database;

    final result = await db.query(
      'session',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isNotEmpty) {

      final row = result.first;

      // Decode JSON
      final currentSongMap = jsonDecode(row['currentSong'] as String);
      final queueList = jsonDecode(row['queue'] as String) as List;

      // Convert a decoded song map safely
      Song convertSong(Map<String, dynamic> s) {
        return Song.fromMap({
          ...s,
          "thumbnail": s["thumbnail"] != null
              ? Uint8List.fromList(List<int>.from(s["thumbnail"]))
              : null,
        });
      }

      return {
        'currentSong': convertSong(Map<String, dynamic>.from(currentSongMap)),
        'queue': queueList
            .map((s) => convertSong(Map<String, dynamic>.from(s)))
            .toList(),
        'folderName': row['folderName'] as String,
      };
    }

    return null;
  }



  Future<void> clearSession() async {
    final db = await database;

    await db.delete('session'); // deletes all rows

    print("Session table cleared");
  }


  // Optional: close the database
  Future<void> closeDB() async {
    final db = await database;
    await db.close();
  }
}
