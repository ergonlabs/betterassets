import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

enum ReadType {
  forward_only,
  random_access,
}

class AssetBundle2 implements AssetBundle {
  static const MethodChannel _channel = const MethodChannel('betterassets');
  final AssetBundle _root;
  final _streams = Map<String, AssetRandomAccessFile>();

  AssetBundle2(this._root) {
    _channel.setMethodCallHandler(_handleCall);
  }

  Future _handleCall(MethodCall call) {
    switch (call.method) {
      case 'close':
        _streams.remove(call.arguments['key']);
    }
  }

  Future<List<String>> list({String path = ''}) {
    return _channel.invokeListMethod('list', {'path': path});
  }

  Future<RandomAccessFile> open(String path, {ReadType mode = ReadType.random_access}) async {
    final String key =
        await _channel.invokeMethod('open', {'path': path, 'mode': mode == ReadType.forward_only ? 2 : 1});
    var result = AssetRandomAccessFile(_channel, key, path);
    _streams[key] = result;
    return result;
  }

  @override
  Future<ByteData> load(String key) {
    return _root.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return _root.loadString(key, cache: cache);
  }

  @override
  void evict(String key) {
    _root.evict(key);
  }

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) {
    return _root.loadStructuredData(key, parser);
  }
}

final f = File('');
final x = f.open();

class AssetRandomAccessFile with WriteMethodsOnReadonlyAsset, AsyncOnlyAsset implements RandomAccessFile {
  MethodChannel channel;
  String key;
  final String path;

  AssetRandomAccessFile(this.channel, this.key, this.path);

  @override
  Future<void> close() {
    return channel.invokeMethod('stream.close', {'key': key});
  }

  @override
  Future<int> length() {
    return channel.invokeMethod('stream.length', {'key': key});
  }

  @override
  Future<int> position() {
    return channel.invokeMethod('stream.position', {'key': key});
  }

  @override
  Future<Uint8List> read(int bytes) {
    return channel.invokeMethod('stream.read', {'key': key, 'bytes':bytes});
  }

  @override
  Future<int> readByte() {
    return channel.invokeMethod('stream.readByte', {'key': key});
  }

  @override
  Future<RandomAccessFile> setPosition(int position) async {
    await channel.invokeMethod('stream.position', {'key': key, 'position':position});
    return this;
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int end]) async {
    end = max(0, min(buffer.length - start, end));
    if (start >= end) return 0;

    final bytes = await read(end-start);
    buffer.replaceRange(start, end, bytes);

    return bytes.length;
  }
}

mixin AsyncOnlyAsset implements RandomAccessFile {
  T waitOnFuture<T>(Future<T> future) {
    throw UnimplementedError("Asset streams are async only.");
  }

  @override
  void closeSync() {
    waitOnFuture(close());
  }

  @override
  int lengthSync() {
    return waitOnFuture(length());
  }

  @override
  int positionSync() {
    return waitOnFuture(position());
  }

  @override
  int readByteSync() {
    return waitOnFuture(readByte());
  }

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int end]) {
    return waitOnFuture(readInto(buffer, start, end));
  }

  @override
  Uint8List readSync(int bytes) {
    return waitOnFuture(read(bytes));
  }

  @override
  void setPositionSync(int position) {
    return waitOnFuture(setPosition(position));
  }
}

mixin WriteMethodsOnReadonlyAsset {
  @override
  Future<RandomAccessFile> flush() async {
    throw FileSystemException();
  }

  @override
  void flushSync() {
    throw FileSystemException();
  }
  @override
  Future<RandomAccessFile> lock([FileLock mode = FileLock.exclusive, int start = 0, int end = -1]) {
    throw FileSystemException();
  }

  @override
  void lockSync([FileLock mode = FileLock.exclusive, int start = 0, int end = -1]) {
    throw FileSystemException();
  }

  @override
  Future<RandomAccessFile> truncate(int length) {
    throw FileSystemException();
  }

  @override
  void truncateSync(int length) {
    throw FileSystemException();
  }

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) {
    throw FileSystemException();
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    throw FileSystemException();
  }

  @override
  Future<RandomAccessFile> writeByte(int value) {
    throw FileSystemException();
  }

  @override
  int writeByteSync(int value) {
    throw FileSystemException();
  }

  @override
  Future<RandomAccessFile> writeFrom(List<int> buffer, [int start = 0, int end]) {
    throw FileSystemException();
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int end]) {
    throw FileSystemException();
  }

  @override
  Future<RandomAccessFile> writeString(String string, {Encoding encoding = utf8}) {
    throw FileSystemException();
  }

  @override
  void writeStringSync(String string, {Encoding encoding = utf8}) {
    throw FileSystemException();
  }
}
