import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/notifications.dart';

class SqliteService {
  List<Notifications> notificationlist = [];
  //static List<String> indexSync = [];
  static Future<Database> initializeDB() async {
    String path = await getDatabasesPath();

    return openDatabase(
      join(path, 'database.db'),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE Notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, address TEXT NOT NULL, time TEXT NOT NULL, carType TEXT NOT NULL, status TEXT, user_id TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<String> createItem(Notifications notification) async {
    final db = await SqliteService.initializeDB();

    final id = await db.insert('Notifications', notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    //indexSync.add(id.toString());
    //print(indexSync[0]);
    return id.toString();
  }

  Future<List<Notifications>> getNotifications() async {
    notificationlist = [];
    final db = await SqliteService.initializeDB();

    List<Map> notificationsQuery =
        await db.rawQuery("SELECT * FROM Notifications");
    for (var i in notificationsQuery) {
      String address = i["address"];
      String time = i["time"];
      String carType = i["carType"];
      String status = i["status"];
      String id = i["id"].toString();

      Notifications newnewNotification = Notifications(
          entryId: id,
          address: address,
          time: time,
          carType: carType,
          status: status);
      notificationlist.add(newnewNotification);
    }
    return notificationlist;
  }

  Future<void> deleteItem(String id) async {
    final db = await SqliteService.initializeDB();
    try {
      await db.delete("Notifications", where: "id = ?", whereArgs: [id]);
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future<bool> itemExists(String userid) async {
    final db = await SqliteService.initializeDB();

    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM Notifications WHERE user_id="$userid"'));
    if (count != 0) {
      return Future<bool>.value(true);
    } else {
      return Future<bool>.value(false);
    }
  }

  Future<int> getNotificationCount() async {
    final db = await SqliteService.initializeDB();

    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Notifications'));
    if (count != null) {
      return count;
    } else {
      return 0;
    }
  }
}
