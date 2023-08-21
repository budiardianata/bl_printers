import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bl_printer/bl_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _blPrinterPlugin = BlPrinter();
  List<BluetoothDevice> devices = [];
  bool _isEnable = false;
  bool _hasPermission = false;
  BluetoothState status = BluetoothState(status: BluetoothStatus.disable);

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    bool enable = false;
    bool permission = false;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    _blPrinterPlugin.getBluetoothStatus().listen((event) async {
      if (event.status != BluetoothStatus.disable) {
        final devices = await _blPrinterPlugin.devices;
        setState(() {
          this.devices
            ..clear()
            ..addAll(devices);
        });
      }
      setState(() {
        status = event;
      });
    }).onError((e) {});
    try {
      platformVersion = await _blPrinterPlugin.getPlatformVersion() ??
          'Unknown platform version';
      enable = await _blPrinterPlugin.isBluetoothEnable;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _isEnable = enable;
      _hasPermission = permission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Text('Running on: $_platformVersion '
                '\nEnable: $_isEnable'
                '\nStatus: $status'
                '\nPermisson: $_hasPermission'),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final item = devices[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.address),
                    selected: status.device?.address == item.address,
                    onTap: () {
                      if (status.status == BluetoothStatus.connected) {
                        _blPrinterPlugin.disconnect(item);
                      } else {
                        _blPrinterPlugin.connect(item);
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: devices.length,
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final data = await getTicket(withImage: true);
                    _blPrinterPlugin.printData(data);
                  },
                  child: const Text('print'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final data = await printQrSampe(withImage: true);
                    _blPrinterPlugin.printData(data);
                  },
                  child: const Text('print Sample QR'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _blPrinterPlugin.printTest();
                  },
                  child: const Text('print test'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<List<String>> getTicket({bool withImage = false}) async {
    final builder = PrintBuilder(PaperSize.mm58);

    if (withImage) {
      ByteData bytes = await rootBundle.load('assets/logo.png');
      var buffer = bytes.buffer;
      var m = base64Encode(Uint8List.view(buffer));
      builder.image(m, align: PrintAlign.center, width: 100, height: 100);
    }
    builder.feed(1);
    builder.text(
      "PT. Ivo Mas Tunggal",
      style: PrintTextStyle(
        align: PrintAlign.center,
        size: PrintSize.large,
        formats: {PrintFormat.bold},
      ),
    );
    builder.text(
      "Sungai Rokan Estate",
      style: PrintTextStyle(
        align: PrintAlign.center,
      ),
    );
    builder.text(
      "Pangkalan Rokan Mill",
      style: PrintTextStyle(align: PrintAlign.center, size: PrintSize.small),
    );

    builder.feed(1);
    builder.text(
      'SURAT PENGANTAR BIBIT ',
      style: PrintTextStyle(
        align: PrintAlign.center,
        size: PrintSize.large,
        formats: {PrintFormat.bold},
      ),
    );
    builder.text(
      'SRKE/BBT/05/23/AA001',
      style: PrintTextStyle(
        align: PrintAlign.center,
        formats: {PrintFormat.bold},
      ),
    );
    builder.hr();
    builder.feed(1);
    builder.row(
      cols: [
        ColumnPrint(text: "NoPol Kendaraan", width: 5),
        ColumnPrint(text: "NoPol Kendaraan", width: 3),
      ],
    );
    builder.row(
      cols: [
        ColumnPrint(text: "Nama Sopir", width: 5),
        ColumnPrint(text: "Jono", width: 3),
      ],
    );
    builder.row(
      cols: [
        ColumnPrint(text: "Tujuan", width: 5),
        ColumnPrint(text: "Kadista Estate", width: 3),
      ],
    );

    builder.feed(1);
    builder.feed(2);
    builder.table(
      headers: [
        ColumnPrint(text: "Batch", width: 5),
        ColumnPrint(
          text: "Tipe",
          width: 2,
          style: PrintTextStyle(align: PrintAlign.center),
        ),
        ColumnPrint(
          text: "Bedeng",
          width: 3,
        ),
        ColumnPrint(
          text: "Clone",
          width: 2,
          style: PrintTextStyle(align: PrintAlign.center),
        ),
        ColumnPrint(
          text: "Qty",
          width: 2,
          style: PrintTextStyle(align: PrintAlign.end),
        )
      ],
      bodies: [
        ['202201D122', 'D', 'PL-001', '-', '1000'],
        ['202201R122', 'R', 'PL-002', '1234', '500'],
        ['202201R122', 'R', 'PL-002', '1211', '500'],
        ['202201R122', 'R', 'PL-002', '1211', '500'],
        ['202201R122', 'R', 'PL-002', '1211', '500'],
      ],
      size: PrintSize.small,
    );

    builder.feed(5);
    final qrBytes = await QrPainter(
      data: "hRdqrGTtB52kKZKcna2+RUO4zs4V5Z7Reh7TYrXbQ7cCdkB6Vbe0JGYsz7mU44FITqMeY5R5QOJItE6KYkgqRUNQC8vIFIyYMrXrd/a3SbM8ZVyqhkOI8zJfhQa/rbM87CRhFr/1YdCWelx1MdvSnFm98zSZKgmsrliK+Sfel2El67m4tQ6aLOU7aM1nbRT4fkcV9MUfQH9VuBWwmWf673up+eFDp8Ba27rSD13hxWvssxadWyCUCIuo2Eh58Wr8mRo5SrwfSwBf266WEiPa3T6Ce60kYPfI6bgXO/xux6ZvxXeYI57KTJER7f9BsyBuA2QigLp/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==",
      version: QrVersions.max,
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      emptyColor: Colors.white
    ).toImageData(300);
    if (qrBytes != null) {
      var buffer = await convertImageToBitmap(qrBytes.buffer);
      var m = base64Encode(buffer);
      builder.image(m, align: PrintAlign.center, width: 300, height: 300);
    }

    builder.hr();
    builder.hr();
    builder.hr();
    builder.hr();
    builder.qrCode('hRdqrGTtB52kKZKcna2+RUO4zs4V5Z7Reh7TYrXbQ7cCdkB6Vbe0JGYsz7mU44FITqMeY5R5QOJItE6KYkgqRUNQC8vIFIyYMrXrd/a3SbM8ZVyqhkOI8zJfhQa/rbM87CRhFr/1YdCWelx1MdvSnFm98zSZKgmsrliK+Sfel2El67m4tQ6aLOU7aM1nbRT4fkcV9MUfQH9VuBWwmWf673up+eFDp8Ba27rSD13hxWvssxadWyCUCIuo2Eh58Wr8mRo5SrwfSwBf266WEiPa3T6Ce60kYPfI6bgXO/xux6ZvxXeYI57KTJER7f9BsyBuA2QigLp/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==');
    builder.hr();
    builder.hr();

    return builder.result;
  }

  Future<List<String>> printQrSampe({bool withImage = false}) async {
    final builder = PrintBuilder(PaperSize.mm58);
    builder.hr();
    builder.feed(1);
    builder.qrCode('hRdqrGTtB52kKZKcna2+RUO4zs4V5Z7Reh7TYrXbQ7cCdkB6Vbe0JGYsz7mU44FITqMeY5R5QOJItE6KYkgqRUNQC8vIFIyYMrXrd/a3SbM8ZVyqhkOI8zJfhQa/rbM87CRhFr/1YdCWelx1MdvSnFm98zSZKgmsrliK+Sfel2El67m4tQ6aLOU7aM1nbRT4fkcV9MUfQH9VuBWwmWf673up+eFDp8Ba27rSD13hxWvssxadWyCUCIuo2Eh58Wr8mRo5SrwfSwBf266WEiPa3T6Ce60kYPfI6bgXO/xux6ZvxXeYI57KTJER7f9BsyBuA2QigLp/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==');
    builder.feed(1);
    builder.hr();
    builder.feed(1);
    builder.qrCode('hRdqrGTtB52kKZKcna2+RUO4zs4V5Z7Reh7TYrXbQ7cCdkB6Vbe0JGYsz7mU44FITqMeY5R5QOJItE6KYkgqRUNQC8vIFIyYMrXrd/a3SbM8ZVyqhkOI8zJfhQa/rbM87CRhFr/1YdCWelx1MdvSnFm98zSZKgmsrliK+Sfel2El67m4tQ6aLOU7aM1nbRT4fkcV9MUfQH9VuBWwmWf673up+eFDp8Ba27rSD13hxWvssxadWyCUCIuo2Eh58Wr8mRo5SrwfSwBf266WEiPa3T6Ce60kYPfI6bgXO/xux6ZvxXeYI57KTJER7f9BsyBuA2QigLp/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==', size: 27);
    builder.feed(1);
    builder.hr();
    builder.feed(1);
    builder.qrCode('hRdqrGTtB52kKZKcna2+RUO4zs4V5Z7Reh7TYrXbQ7cCdkB6Vbe0JGYsz7mU44FITqMeY5R5QOJItE6KYkgqRUNQC8vIFIyYMrXrd/a3SbM8ZVyqhkOI8zJfhQa/rbM87CRhFr/1YdCWelx1MdvSnFm98zSZKgmsrliK+Sfel2El67m4tQ6aLOU7aM1nbRT4fkcV9MUfQH9VuBWwmWf673up+eFDp8Ba27rSD13hxWvssxadWyCUCIuo2Eh58Wr8mRo5SrwfSwBf266WEiPa3T6Ce60kYPfI6bgXO/xux6ZvxXeYI57KTJER7f9BsyBuA2QigLp/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==', size: 29);
    builder.feed(1);
    builder.hr();

    return builder.result;
  }

  Future<Uint8List> convertImageToBitmap(ByteBuffer image) async {

    final pngBytes = image.asUint8List();

    img.Image imgBitmap = img.decodeImage(Uint8List.fromList(pngBytes))!;
    img.Image resizedBitmap = img.copyResize(imgBitmap, width: 300); // Adjust the width as needed

    return Uint8List.fromList(img.encodePng(resizedBitmap));
  }
}
