import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Biblio',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        home: HomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = 'samdouble';
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

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

class MyWidget extends StatelessWidget {
  @override
  Widget build(context) {
    return FutureBuilder<String>(
      future: getleader(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data ?? 'No data');
        } else {
          return CircularProgressIndicator();
        }
      }
    );
  }
}

class _HomePageState extends State<HomePage> {
  String result = '';

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    const String appTitle = 'Biblio';
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(appTitle),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Hello'),
          MyWidget(),
          Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  String? res = await SimpleBarcodeScanner.scanBarcode(
                    context,
                    barcodeAppBar: const BarcodeAppBar(
                      appBarTitle: 'Test',
                      centerTitle: false,
                      enableBackButton: true,
                      backButtonIcon: Icon(Icons.arrow_back_ios),
                    ),
                    isShowFlashIcon: true,
                    delayMillis: 500,
                    cameraFace: CameraFace.back,
                    scanFormat: ScanFormat.ONLY_BARCODE,
                  );
                  setState(() {
                    result = res as String;
                  });
                },
                child: const Text('Scan Barcode'),
              ),
              const SizedBox(
                height: 10,
              ),
              Text('Scan Barcode Result: $result'),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () async {
                  SimpleBarcodeScanner.streamBarcode(
                    context,
                    barcodeAppBar: const BarcodeAppBar(
                      appBarTitle: 'Test',
                      centerTitle: false,
                      enableBackButton: true,
                      backButtonIcon: Icon(Icons.arrow_back_ios),
                    ),
                    isShowFlashIcon: true,
                    delayMillis: 2000,
                  ).listen((event) {
                    print("Stream Barcode Result: $event");
                  });
                },
                child: const Text('Stream Barcode'),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigator.push(context, MaterialPageRoute(builder: (context) {
                  //   return const BarcodeWidgetPage();
                  // }));
                },
                child: const Text('Barcode Scanner Widget(Android Only)')
              ),
              Text('A random idea:'),
              Text(appState.current),
              Text('Hello'),
              Text('Hello World'),
            ],
          ),
          Text('Hello'),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Item 1'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Text('Item 2'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
