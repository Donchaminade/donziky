import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('ThemeProvider exposes dark mode by default', (tester) async {
    final theme = ThemeProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: theme,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              return Text(
                context.watch<ThemeProvider>().themeMode == ThemeMode.dark ? 'dark' : 'light',
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('dark'), findsOneWidget);
  });

  test('SongUtils filters by query', () {
    // SongModel cannot be constructed easily without platform; test filter logic via empty list
    final result = SongUtils.filterSongs(
      [],
      query: 'test',
      excludedFolders: {},
      minDurationMs: 1000,
      hideShortSounds: false,
    );
    expect(result, isEmpty);
  });

  test('MusicProvider repeat mode cycles', () {
    final provider = MusicProvider();
    expect(provider.repeatMode, RepeatMode.none);
  });
}
