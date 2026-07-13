import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doudou_player/models/video_collection.dart';
import 'package:doudou_player/services/collection_service.dart';
import 'package:doudou_player/services/library_path.dart';
import 'package:doudou_player/services/library_service.dart';
import 'package:doudou_player/services/settings_service.dart';
import 'package:doudou_player/services/thumbnail_service.dart';

class _NoopThumbnailService extends ThumbnailService {
  @override
  Future<String?> generateForVideo(String videoPath) async => null;

  @override
  Future<void> deleteForVideo(String? thumbnailPath) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<({CollectionService collections, LibraryService library})> createServices() async {
    final settings = SettingsService();
    await settings.load();
    final collections = CollectionService();
    await collections.load();
    final library = LibraryService(
      settings,
      thumbnailService: _NoopThumbnailService(),
      collectionService: collections,
    );
    await library.load();
    return (collections: collections, library: library);
  }

  test('createManualCollection adds empty manual collection', () async {
    final services = await createServices();

    final collection =
        await services.collections.createManualCollection('My Shows');

    expect(collection.type, VideoCollectionType.manual);
    expect(collection.name, 'My Shows');
    expect(collection.videoIds, isEmpty);
    expect(services.collections.manualCollections, hasLength(1));
  });

  test('renameCollection updates manual collection name', () async {
    final services = await createServices();
    final collection =
        await services.collections.createManualCollection('Old Name');

    await services.collections.renameCollection(collection.id, 'New Name');

    expect(services.collections.findById(collection.id)?.name, 'New Name');
  });

  test('renameCollection ignores scanRoot collections', () async {
    final services = await createServices();

    await services.collections.registerScanRootCollection(
      '/tmp/videos',
      null,
      ['video1.mp4'],
    );

    final folder = services.collections.scanRootCollections.single;
    await services.collections.renameCollection(folder.id, 'Renamed');

    expect(services.collections.findById(folder.id)?.name, isNot('Renamed'));
  });

  test('deleteCollection removes metadata without touching library', () async {
    final services = await createServices();
    final collection =
        await services.collections.createManualCollection('To Delete');

    await services.collections.deleteCollection(collection.id);

    expect(services.collections.findById(collection.id), isNull);
  });

  test('addVideosToCollection deduplicates video ids', () async {
    final services = await createServices();
    final collection =
        await services.collections.createManualCollection('Playlist');

    await services.collections.addVideosToCollection(
      collection.id,
      {'video-a.mp4', 'video-b.mp4'},
    );
    await services.collections.addVideosToCollection(
      collection.id,
      {'video-a.mp4', 'video-c.mp4'},
    );

    final updated = services.collections.findById(collection.id)!;
    expect(updated.videoIds, hasLength(3));
    expect(updated.videoIds, containsAll(['video-a.mp4', 'video-b.mp4', 'video-c.mp4']));
  });

  test('registerScanRootCollection creates folder collection', () async {
    final services = await createServices();

    await services.collections.registerScanRootCollection(
      '/tmp/my-videos',
      'bookmark-data',
      ['video1.mp4', 'video2.mp4'],
    );

    final folders = services.collections.scanRootCollections;
    expect(folders, hasLength(1));
    expect(folders.single.type, VideoCollectionType.scanRoot);
    expect(folders.single.scanRootPath, '/tmp/my-videos');
    expect(folders.single.directoryBookmark, 'bookmark-data');
    expect(folders.single.videoIds, ['video1.mp4', 'video2.mp4']);
  });

  test('registerScanRootCollection merges on rescan', () async {
    final services = await createServices();

    await services.collections.registerScanRootCollection(
      '/tmp/my-videos',
      'bookmark-v1',
      ['video1.mp4'],
    );
    await services.collections.registerScanRootCollection(
      '/tmp/my-videos',
      'bookmark-v2',
      ['video2.mp4'],
    );

    final folders = services.collections.scanRootCollections;
    expect(folders, hasLength(1));
    expect(folders.single.videoIds, ['video1.mp4', 'video2.mp4']);
    expect(folders.single.directoryBookmark, 'bookmark-v2');
  });

  test('registerScanRootCollection treats /private paths as same root', () async {
    final services = await createServices();

    await services.collections.registerScanRootCollection(
      '/private/tmp/shared',
      null,
      ['video1.mp4'],
    );
    await services.collections.registerScanRootCollection(
      '/tmp/shared',
      null,
      ['video2.mp4'],
    );

    expect(services.collections.scanRootCollections, hasLength(1));
    expect(
      services.collections.scanRootCollections.single.videoIds,
      ['video1.mp4', 'video2.mp4'],
    );
  });

  test('pruneVideoIds removes missing videos from all collections', () async {
    final services = await createServices();
    final manual =
        await services.collections.createManualCollection('Manual');

    await services.collections.registerScanRootCollection(
      '/tmp/folder',
      null,
      ['keep.mp4', 'remove.mp4'],
    );
    await services.collections.addVideosToCollection(
      manual.id,
      {'keep.mp4', 'remove.mp4'},
    );

    await services.collections.pruneVideoIds({'keep.mp4'});

    expect(
      services.collections.findById(manual.id)!.videoIds,
      ['keep.mp4'],
    );
    expect(
      services.collections.scanRootCollections.single.videoIds,
      ['keep.mp4'],
    );
  });

  test('videosInCollection returns items in collection order', () async {
    final tempDir = Directory.systemTemp.createTempSync('doudou_collection_test');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final pathA = '${tempDir.path}/a.mp4';
    final pathB = '${tempDir.path}/b.mp4';
    File(pathA).createSync();
    File(pathB).createSync();

    final services = await createServices();

    await services.library.addVideoPaths([pathA, pathB]);
    final collection =
        await services.collections.createManualCollection('Ordered');
    await services.collections.addVideosToCollection(
      collection.id,
      [pathB, pathA],
    );

    final items = services.collections.videosInCollection(
      collection.id,
      services.library,
    );

    expect(items.map((item) => item.filePath), [pathB, pathA]);
  });

  test('collections persist across load', () async {
    final services = await createServices();
    await services.collections.createManualCollection('Persisted');
    await services.collections.registerScanRootCollection(
      '/tmp/folder',
      null,
      ['video.mp4'],
    );

    final reloaded = CollectionService();
    await reloaded.load();

    expect(reloaded.manualCollections, hasLength(1));
    expect(reloaded.manualCollections.single.name, 'Persisted');
    expect(reloaded.scanRootCollections, hasLength(1));
    expect(
      reloaded.scanRootCollections.single.id,
      normalizeLibraryPath('/tmp/folder'),
    );
  });
}
