import 'dart:io';
import 'dart:ui' as ui;

import 'package:donziker/models/local_playlist.dart';
import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/albums_screen.dart';
import 'package:donziker/screens/artists_screen.dart';
import 'package:donziker/screens/favorites_screen.dart';
import 'package:donziker/screens/folders_screen.dart';
import 'package:donziker/screens/genres_screen.dart';
import 'package:donziker/screens/library_detail_screens.dart';
import 'package:donziker/screens/library_hub_screen.dart';
import 'package:donziker/screens/main_shell.dart';
import 'package:donziker/screens/onboarding_screen.dart';
import 'package:donziker/screens/player_screen.dart';
import 'package:donziker/screens/playlist_detail_screen.dart';
import 'package:donziker/screens/playlists_screen.dart';
import 'package:donziker/screens/settings_screen.dart';
import 'package:donziker/screens/songs_screen.dart';
import 'package:donziker/screens/splash_permission_screen.dart';
import 'package:donziker/screens/stats_screen.dart';
import 'package:donziker/screens/videos_screen.dart';
import 'package:donziker/screens/wow_splash_screen.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/load_app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SongModel> songs;
  late MusicProvider music;
  late ThemeProvider theme;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.lucasjosino.on_audio_query'), (call) async => null);
    await loadAppFonts();
    songs = [
      _song(1, 'Weekly Discovery', 'Tega', 'Feel-good', date: 900, genre: 'Pop'),
      _song(2, 'Nuit calme', 'Ayo', 'Nouveautés', date: 800, genre: 'Soul'),
      _song(3, 'Citron vert', 'Kidi', 'Tendances', date: 700, genre: 'Afrobeats'),
      _song(4, 'Dimanche', 'Ama', 'Focus', date: 600, genre: 'Jazz'),
      _song(5, 'Retour', 'Burna', 'Classiques', date: 500, genre: 'Pop'),
    ];
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'is_dark': false,
      'visual_style': 'tega',
      'display_name': 'Tega',
      'disable_animations': true,
    });
    theme = ThemeProvider();
    await theme.ready;
    music = MusicProvider();
    music.seedPreview(
      songs: songs,
      playlists: const [
        LocalPlaylist(id: 'pl1', name: 'Dimanche', createdAt: 2, songCount: 4),
        LocalPlaylist(id: 'pl2', name: 'Focus', createdAt: 1, songCount: 8),
        LocalPlaylist(id: 'pl3', name: 'Nuit', createdAt: 3, songCount: 3),
      ],
      favoriteIds: const ['1', '3'],
      recentIds: const ['1', '2', '4'],
      topPlayedIds: const ['3', '1', '5'],
      summary: const {'plays': 128, 'ms': 5400000},
      playlistSongs: {'pl1': songs.take(3).toList()},
      current: songs.first,
      playing: false,
      previewProgress: 0.38,
    );
  });

  tearDown(() => music.dispose());

  testWidgets('captures des écrans 780×1688', (tester) async {
    await _prepareSurface(tester);
    final dir = Directory('/opt/cursor/artifacts/screenshots');
    dir.createSync(recursive: true);

    Future<void> shoot(String name, Widget screen, {ThemeMode mode = ThemeMode.light}) async {
      theme.toggleTheme(mode == ThemeMode.dark);
      await tester.pumpWidget(_harness(theme, music, screen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 50),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 8),
        );
      } catch (_) {}
      await _capture(tester, '${dir.path}/$name.png');
    }

    await shoot('01-splash', const WowSplashScreen(holdNavigation: true));
    music.library.permissionGranted = false;
    await shoot('02-onboarding', const OnboardingScreen());
    music.library.permissionGranted = true;
    await shoot('03-permissions', const SplashPermissionScreen(preview: true));
    await shoot('04-accueil', const MainShell());
    music.setShellTab(1);
    await shoot('05-bibliotheque', const MainShell());
    music.setShellTab(2);
    await shoot('06-favoris', const FavoritesScreen());
    music.setShellTab(3);
    await shoot('07-reglages', const SettingsScreen());
    await shoot('08-stats', const StatsScreen());
    await shoot('09-lecteur', const PlayerScreen());
    await shoot('24-lecteur-circulaire', const PlayerScreen());
    await shoot('25-themes', const SettingsScreen());
    await shoot('10-playlists', const PlaylistsScreen());
    await shoot('11-detail-playlist', const PlaylistDetailScreen(playlistId: 'pl1', name: 'Dimanche'));
    await shoot('12-morceaux', const SongsScreen());
    await shoot('13-albums', const AlbumsScreen());
    await shoot('14-artistes', const ArtistsScreen());
    await shoot('15-genres', const GenresScreen());
    await shoot('16-dossiers', const FoldersScreen());
    await shoot('17-videos', const VideosScreen());
    await shoot('18-album', AlbumDetailScreen(name: 'Feel-good', songs: songs));
    await shoot('19-artiste', ArtistDetailScreen(name: 'Tega', songs: songs));
    await shoot('20-genre', GenreDetailScreen(name: 'Pop', songs: songs.where((s) => (s.genre ?? '') == 'Pop').toList()));
    await shoot('21-dossier', FolderDetailScreen(path: '/storage/emulated/0/Music/Feel-good', songs: [songs.first]));
    music.openLibrarySection('playlists');
    await shoot('22-bibliotheque-playlists', const LibraryHubScreen());
    theme.toggleTheme(true);
    await tester.pumpWidget(_harness(theme, music, const MainShell()));
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 8),
      );
    } catch (_) {}
    await _capture(tester, '${dir.path}/23-accueil-sombre.png');

    for (final name in ['04-accueil', '24-lecteur-circulaire', '25-themes']) {
      final file = File('${dir.path}/$name.png');
      expect(file.existsSync(), isTrue, reason: name);
      final bytes = file.readAsBytesSync();
      final data = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.length);
      expect(data.getUint32(16), 780, reason: name);
      expect(data.getUint32(20), 1688, reason: name);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}

Widget _harness(ThemeProvider theme, MusicProvider music, Widget screen) {
  final tega = theme.isTega;
  final accent = theme.accentColor;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: music),
      ChangeNotifierProvider.value(value: theme),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: tega ? AppTheme.tegaLight() : AppTheme.classicLight(accent),
      darkTheme: tega ? AppTheme.tegaDark() : AppTheme.classicDark(accent),
      themeMode: theme.themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final data = theme.disableAnimations ? media.copyWith(disableAnimations: true) : media;
        return MediaQuery(data: data, child: child ?? const SizedBox.shrink());
      },
      home: RepaintBoundary(
        child: Material(
          color: tega
              ? (theme.themeMode == ThemeMode.dark ? AppTheme.darkBg : AppTheme.canvas)
              : null,
          child: screen,
        ),
      ),
    ),
  );
}

Future<void> _prepareSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 2.0;
  await tester.binding.setSurfaceSize(const Size(390, 844));
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _capture(WidgetTester tester, String path) async {
  final boundary = tester.renderObject(find.byType(RepaintBoundary).first) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
  });
}

SongModel _song(int id, String title, String artist, String album, {required int date, required String genre}) {
  return SongModel({
    '_id': id,
    '_data': '/storage/emulated/0/Music/$album/$title.mp3',
    '_uri': 'content://media/external/audio/media/$id',
    '_display_name': '$title.mp3',
    '_display_name_wo_ext': title,
    '_size': 3000000,
    'title': title,
    'artist': artist,
    'album': album,
    'genre': genre,
    'duration': 186000,
    'date_added': date,
    'file_extension': 'mp3',
  });
}
