import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../widgets/main_drawer.dart';
import '../widgets/my_widget.dart';

class MyAppState extends ChangeNotifier {
  var current = 'samdouble';
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
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
          Text(AppLocalizations.of(context)!.helloWorld),
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
              const SizedBox(
                height: 10,
              ),
              Text('A random idea:'),
              Text(appState.current),
            ],
          ),
          Text('Hello'),
        ],
      ),
      drawer: MainDrawer(),
    );
  }
}
