/// 🤖 Generated wholely or partially with GPT-5.6 Sol; OpenAI Codex
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('File write stream:', () {
    final List<FileOperation> events = [];
    StreamSubscription<FileOperation>? subscription;

    FlavorConfig.setup();

    setUp(() async {
      events.clear();
      await subscription?.cancel();
      subscription = FileManager.fileWriteStream.stream.listen(events.add);
    });
    tearDown(() async {
      await subscription?.cancel();
    });

    test('broadcastFileWrite', () async {
      // broadcast a write event
      FileManager.broadcastFileWrite(FileOperationType.write, '/test.sbn2');

      // wait for the event to be broadcast
      await null;

      // check that the event was received
      expect(events, hasLength(1));
      expect(events.last.filePath, '/test'); // without the extension
      expect(events.last.type, FileOperationType.write);
    });

    test('system directory watch', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      setupMockPathProvider();

      await FileManager.init();

      final rootDir = FileManager.documentsDirectory;
      final file = File('$rootDir/test.sbn2');

      // write to file
      await file.create(recursive: true);
      await file.writeAsString('test_content');
      await Future.delayed(const Duration(milliseconds: 1));
      expect(events, hasLength(greaterThanOrEqualTo(2)));
      expect(events.last.filePath, '/test'); // without the extension
      expect(events.last.type, FileOperationType.write);
      events.clear();

      // delete file
      await file.delete();
      await Future.delayed(const Duration(milliseconds: 1));
      expect(events, hasLength(greaterThanOrEqualTo(1)));
      expect(events.last.filePath, '/test'); // without the extension
      expect(events.last.type, FileOperationType.delete);
    });

    test('switching roots discovers existing nested notes', () async {
      final oldRoot = await Directory.systemTemp.createTemp('saber-old-');
      final newRoot = await Directory.systemTemp.createTemp('saber-new-');
      addTearDown(() async {
        if (oldRoot.existsSync()) await oldRoot.delete(recursive: true);
        if (newRoot.existsSync()) await newRoot.delete(recursive: true);
      });

      await FileManager.init(documentsDirectory: oldRoot.path);
      final nestedNote = File('${newRoot.path}/folder/existing.sbn2');
      await nestedNote.create(recursive: true);
      await nestedNote.writeAsString('existing note');
      events.clear();

      await FileManager.useDataDir(newRoot.path);
      await null;

      final rootChildren = await FileManager.getChildrenOfDirectory('/');
      final nestedChildren = await FileManager.getChildrenOfDirectory('/folder');
      expect(rootChildren?.directories, contains('folder'));
      expect(nestedChildren?.files, contains('existing'));
      expect(
        events.any(
          (event) =>
              event.type == FileOperationType.write && event.filePath == '/',
        ),
        isTrue,
      );
    });
  });
}
