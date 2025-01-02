import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<String> getleader() async {
  final dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  final dbPath = join(dir.path, 'my_database.db');
  final db = await databaseFactoryIo.openDatabase(dbPath);
  // dynamically typed store
  var store = StoreRef.main();
  // Easy to put/get simple values or map
  // A key can be of type int or String and the value can be anything as long as it can
  // be properly JSON encoded/decoded
  await store.record('title').put(db, 'Simple application');
  await store.record('version').put(db, 10);
  await store.record('settings').put(db, {'offline': true});

  // read values
  var title = await store.record('title').get(db) as String;
  // var version = await store.record('version').get(db) as int;
  // var settings = await store.record('settings').get(db) as Map;

  // ...and delete
  await store.record('version').delete(db);
  return title;
}
