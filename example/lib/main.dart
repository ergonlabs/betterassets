import 'dart:async';
import 'dart:convert';

import 'package:betterassets/betterassets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AssetBundle2 assets;

  @override
  void initState() {
    super.initState();
    assets = AssetBundle2(rootBundle);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder(
              future: assets.list(),
              builder: (context, items) => Text('list: ${items.data}'),
            ),
            FutureBuilder(
              future: assets.list(path: 'assets'),
              builder: (context, items) => Text('list(assets): ${items.data}'),
            ),
            FutureBuilder(
              future: assets.list(path: 'assets/bob.json'),
              builder: (context, items) => Text('list(assets/bob.json): ${items.data}'),
            ),
            FutureBuilder(
              future: Future(() async {
                final stream = await assets.open('assets/bob.json');
                final data = await stream.read(await stream.length());
                assert(data.length == await stream.length());
                return utf8.decode(data);
              }),
              builder: (context, items) => Text('file(assets/bob.json): ${items.data}'),
            ),

          ],
        ),
      ),
    );
  }
}
