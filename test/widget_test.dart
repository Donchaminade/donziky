import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ThemeProvider expose le thème clair Tega par défaut', (tester) async {
    final theme = ThemeProvider();
    await theme.ready;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: theme,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final provider = context.watch<ThemeProvider>();
              final mode = provider.themeMode == ThemeMode.light ? 'light' : 'dark';
              final style = provider.isTega ? 'tega' : 'classic';
              return Text('$mode-$style-${provider.displayName}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('light-tega-Tega'), findsOneWidget);

    await theme.setVisualStyle(AppVisualStyle.classic);
    theme.toggleTheme(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('dark-classic-Tega'), findsOneWidget);
  });

  test('SongUtils filters by query', () {
    final result = SongUtils.filterSongs(
      [],
      query: 'test',
      excludedFolders: {},
      minDurationMs: 1000,
      hideShortSounds: false,
    );
    expect(result, isEmpty);
  });

  test('MusicProvider repeat mode cycles from all', () {
    final provider = MusicProvider();
    expect(provider.repeatMode, RepeatMode.all);
    provider.dispose();
  });
}
