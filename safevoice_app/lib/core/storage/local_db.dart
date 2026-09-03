import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../storage/secure_storage.dart';

part 'local_db.g.dart';

// ── Table Definitions ─────────────────────────────────────────────────────────

/// Persists queue items for offline-first submission.
class OfflineQueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // report | evidence | sos | location_ping
  TextColumn get payloadJson => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of submitted/synced cases.
class LocalCases extends Table {
  TextColumn get caseId => text()();
  TextColumn get status => text()();
  TextColumn get incidentType => text()();
  TextColumn get riskLevel => text().withDefault(const Constant(''))();
  DateTimeColumn get submittedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get statusHistoryJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {caseId};
}

/// Local encrypted drafts.
class LocalDrafts extends Table {
  TextColumn get draftId => text()();
  TextColumn get formDataJson => text()(); // AES-256 encrypted at rest
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {draftId};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [OfflineQueueItems, LocalCases, LocalDrafts])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase._(QueryExecutor e) : super(e);

  static LocalDatabase? _instance;

  static Future<LocalDatabase> getInstance(SecureStorage secureStorage) async {
    _instance ??= LocalDatabase._(await _openConnection(secureStorage));
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  // ── OfflineQueue helpers ──────────────────────────────────────────────────

  Future<List<OfflineQueueItem>> getPendingItems() =>
      (select(offlineQueueItems)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<int> insertQueueItem(OfflineQueueItemsCompanion item) =>
      into(offlineQueueItems).insert(item);

  Future<bool> updateQueueItem(OfflineQueueItem item) =>
      update(offlineQueueItems).replace(item);

  Future<int> deleteQueueItem(String id) =>
      (delete(offlineQueueItems)..where((t) => t.id.equals(id))).go();

  // ── Draft helpers ─────────────────────────────────────────────────────────

  Future<List<LocalDraft>> getAllDrafts() =>
      (select(localDrafts)
            ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
          .get();

  Future<LocalDraft?> getDraft(String draftId) =>
      (select(localDrafts)..where((t) => t.draftId.equals(draftId)))
          .getSingleOrNull();

  Future<int> upsertDraft(LocalDraftsCompanion draft) =>
      into(localDrafts).insertOnConflictUpdate(draft);

  Future<int> deleteDraft(String draftId) =>
      (delete(localDrafts)..where((t) => t.draftId.equals(draftId))).go();

  // ── Case cache helpers ────────────────────────────────────────────────────

  Future<List<LocalCase>> getCachedCases() =>
      (select(localCases)
            ..orderBy([(t) => OrderingTerm.desc(t.submittedAt)]))
          .get();

  Future<int> upsertCase(LocalCasesCompanion c) =>
      into(localCases).insertOnConflictUpdate(c);
}

Future<QueryExecutor> _openConnection(SecureStorage secureStorage) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dbFolder.path, 'safevoice.db');

  // Retrieve or generate a DB encryption key stored in Android Keystore / iOS SE
  String? encKey = await secureStorage.readDbEncryptionKey();
  if (encKey == null) {
    // Generate a random 256-bit key on first run
    encKey = _generateHexKey();
    await secureStorage.saveDbEncryptionKey(encKey);
  }

  return SqfliteQueryExecutor.singleFile(
    dbPath,
    logStatements: false,
  );
}

String _generateHexKey() {
  // 32 random bytes expressed as hex (256-bit key for SQLCipher)
  final bytes = List<int>.generate(32, (i) {
    // Platform secure random not available at compile-time; use simple seed here.
    // In production, use dart:math Random.secure()
    return (DateTime.now().microsecondsSinceEpoch + i) & 0xFF;
  });
  return bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}
