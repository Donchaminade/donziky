import 'dart:async';

import 'package:donziker/models/local_playlist.dart';
import 'package:donziker/models/repeat_mode.dart';
import 'package:donziker/models/song_sort.dart';
import 'package:donziker/services/database_service.dart';
import 'package:donziker/services/library_service.dart';
import 'package:donziker/services/listening_stats_service.dart';
import 'package:donziker/services/playback_service.dart';
import 'package:donziker/services/queue_service.dart';
import 'package:donziker/utils/lyrics_loader.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:donziker/models/repeat_mode.dart';

class MusicProvider extends ChangeNotifier {
  final PlaybackService playback = PlaybackService();
  final QueueService queueService = QueueService();
  final LibraryService library = LibraryService();
  final ListeningStatsService stats;
  final OnAudioQuery _artworkQuery = OnAudioQuery();

  static const _keyMediaGranted = 'media_access_granted';
  static const _keyOnboardingDone = 'onboarding_completed';

  Color _dynamicAccentColor = const Color(0xFFD4F26A);
  Color _artworkTint = const Color(0xFF8EC8F5);
  bool _useDynamicAccent = true;
  bool _hasExtractedAccent = false;
  String? _currentLyrics;

  int _shellTabIndex = 0;
  int _libraryTabIndex = 0;
  String? _requestedLibrarySection;
  String? _scrollToSongId;
  int _locateGeneration = 0;
  bool _sessionRestored = false;
  bool _preview = false;
  bool _listenersReady = false;
  int _accentToken = 0;

  MusicProvider({DatabaseService? database})
      : stats = ListeningStatsService(database ?? DatabaseService()) {
    playback.onPaused = savePlaybackState;
    playback.onChanged = notifyListeners;
  }

  bool get isPlaying => playback.uiPlaying;
  SortOrder get sortOrder => library.sortOrder;
  SongModel? get currentSong => queueService.current;
  List<SongModel> get songs => library.songs;
  List<SongModel> get queue => queueService.items;
  List<AssetEntity> get videos => library.videos;
  List<LocalPlaylist> get playlists => library.playlists;
  double get speed => playback.speed;
  List<String> get favorites => library.favorites;
  bool get isLoading => library.isLoading;
  bool get permissionGranted => library.permissionGranted;
  bool get isShuffle => playback.isShuffle;
  RepeatMode get repeatMode => playback.repeatMode;
  Color get dynamicAccentColor => _dynamicAccentColor;
  Color get artworkTint => _artworkTint;
  bool get hasExtractedAccent => _hasExtractedAccent;
  bool get useDynamicAccent => _useDynamicAccent;
  String get searchQuery => library.searchQuery;
  String? get currentLyrics => _currentLyrics;
  SongSort get songSort => library.songSort;
  bool get hideShortSounds => library.hideShortSounds;
  Set<String> get excludedFolders => library.excludedFolders;
  Duration? get sleepTimerRemaining => playback.sleepTimerRemaining;
  Duration? get pointA => playback.pointA;
  Duration? get pointB => playback.pointB;
  bool get isABLoopActive => playback.isABLoopActive;
  int get abLoopMax => playback.abLoopMax;
  AudioPlayer get audioPlayer => playback.player;
  bool get karaokeMode => playback.karaokeMode;
  int get karaokeLeadSeconds => playback.karaokeLeadSeconds;
  int get shellTabIndex => _shellTabIndex;
  int get libraryTabIndex => _libraryTabIndex;
  String? get requestedLibrarySection => _requestedLibrarySection;
  String? get scrollToSongId => _scrollToSongId;
  int get locateGeneration => _locateGeneration;

  bool isFavorite(String songId) => library.isFavorite(songId);
  List<SongModel> get filteredSongs => library.filteredSongs;
  List<SongModel> get recentlyPlayed => library.recentlyPlayed;
  List<SongModel> get favoriteSongs => library.favoriteSongs;
  List<SongModel> get smartRecentlyAdded => library.smartRecentlyAdded;
  List<SongModel> get smartMostPlayed => library.smartMostPlayed(stats.topPlayedIds);

  Future<void> init() async {
    try {
      await _loadPreferences();
      await library.loadPlaylists();
      await stats.loadTop();
      _bindPlayback();
    } catch (e) {
      debugPrint('MusicProvider.init error: $e');
    }
  }

  void _bindPlayback() {
    playback.bind(
      notify: notifyListeners,
      playNext: playNext,
      pause: () => pause(),
      currentSong: () => currentSong,
      currentIndex: () => queueService.currentIndex,
      queueLength: () => queueService.items.length,
      songAt: (index) => index >= 0 && index < queueService.items.length ? queueService.items[index] : null,
      onIndexChanged: (index, song) async {
        queueService.currentIndex = index;
        library.remember(SongUtils.songId(song));
        await _persistRecent();
        await loadLyrics(song);
        await _updateDynamicAccent(song.id);
        notifyListeners();
      },
      onPosition: (position) {
        final song = currentSong;
        stats.tick(
          playing: playback.uiPlaying,
          song: song,
          songId: song == null ? null : SongUtils.songId(song),
          position: position,
        );
        if (song != null && playback.shouldSave(position)) {
          savePlaybackState();
        }
      },
    );
    _listenersReady = true;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    library.favorites = prefs.getStringList('favorites') ?? [];
    library.recentlyPlayedIds = prefs.getStringList('recently_played') ?? [];
    library.excludedFolders = (prefs.getStringList('excluded_folders') ?? []).toSet();
    playback.speed = prefs.getDouble('playback_speed') ?? 1.0;
    library.hideShortSounds = prefs.getBool('hide_short_sounds') ?? true;
    library.minDurationMs = prefs.getInt('min_duration_ms') ?? 10000;
    _useDynamicAccent = prefs.getBool('use_dynamic_accent') ?? true;
    playback.gaplessEnabled = prefs.getBool('gapless_enabled') ?? true;
    playback.karaokeMode = prefs.getBool('karaoke_mode') ?? false;
    playback.karaokeLeadSeconds = prefs.getInt('karaoke_lead_seconds') ?? 8;
    final sortIndex = prefs.getInt('song_sort') ?? SongSort.dateAdded.index;
    library.songSort = SongSort.values[sortIndex.clamp(0, SongSort.values.length - 1)];
    library.sortOrder = (prefs.getBool('song_sort_desc') ?? true) ? SortOrder.descending : SortOrder.ascending;
    playback.setSpeed(playback.speed);
    library.invalidateFilter();
    notifyListeners();
  }

  void toggleKaraokeMode() {
    playback.toggleKaraoke(notifyListeners);
    _persistBool('karaoke_mode', playback.karaokeMode);
  }

  void setKaraokeLeadSeconds(int seconds) {
    playback.setKaraokeLead(seconds, notifyListeners);
    _persistPref('karaoke_lead_seconds', playback.karaokeLeadSeconds);
  }

  void requestLocateCurrentSong() {
    final song = currentSong;
    if (song == null) return;
    _shellTabIndex = 0;
    _libraryTabIndex = 0;
    _scrollToSongId = SongUtils.songId(song);
    _locateGeneration++;
    notifyListeners();
  }

  void clearScrollToSong() {
    _scrollToSongId = null;
  }

  void setShellTab(int index) {
    _shellTabIndex = index;
    notifyListeners();
  }

  void setLibraryTab(int index) {
    _libraryTabIndex = index;
    notifyListeners();
  }

  void openLibrarySection(String section) {
    _requestedLibrarySection = section;
    _shellTabIndex = 1;
    notifyListeners();
  }

  void consumeLibrarySection() {
    _requestedLibrarySection = null;
  }

  Future<void> _updateDynamicAccent(int songId) async {
    final token = ++_accentToken;
    try {
      final artwork = await _artworkQuery.queryArtwork(songId, ArtworkType.AUDIO, size: 200);
      if (artwork == null || token != _accentToken) return;
      final palette = await PaletteGenerator.fromImageProvider(MemoryImage(artwork));
      if (token != _accentToken) return;
      final color = palette.dominantColor?.color ?? palette.vibrantColor?.color ?? _artworkTint;
      _artworkTint = color;
      _hasExtractedAccent = true;
      if (_useDynamicAccent) _dynamicAccentColor = color;
      notifyListeners();
    } catch (e) {
      debugPrint('Accent extraction error: $e');
    }
  }

  Future<void> _persistRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recently_played', library.recentlyPlayedIds);
  }

  Future<void> savePlaybackState() async {
    try {
      final song = currentSong;
      if (song == null || queueService.items.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final positionMs = playback.isPlayerOpen ? playback.player.position.inMilliseconds : 0;
      await prefs.setString('resume_song_id', SongUtils.songId(song));
      await prefs.setInt('resume_position_ms', positionMs);
      await prefs.setBool('resume_was_playing', isPlaying);
      await prefs.setStringList('resume_queue_ids', queueService.items.map(SongUtils.songId).toList());
      await prefs.setInt('resume_queue_index', queueService.currentIndex);
    } catch (e, st) {
      debugPrint('sauvegarde lecture: $e\n$st');
    }
  }

  Future<void> _tryResumePlayback() async {
    // Ne jamais recharger la file par-dessus une lecture déjà lancée.
    if (playback.userWantsPlayback) {
      _sessionRestored = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final positionMs = prefs.getInt('resume_position_ms') ?? 0;
    final queueIds = prefs.getStringList('resume_queue_ids');
    final queueIndex = prefs.getInt('resume_queue_index') ?? 0;

    final restoreQueue = <SongModel>[];
    if (queueIds != null && queueIds.isNotEmpty) {
      for (final id in queueIds) {
        final match = queueService.byPersistentId(id, library.songs);
        if (match != null) restoreQueue.add(match);
      }
    }

    if (restoreQueue.isEmpty) {
      final songId = prefs.getString('resume_song_id');
      if (songId == null) return;
      final match = queueService.byPersistentId(songId, library.songs);
      if (match != null) restoreQueue.add(match);
    }

    if (restoreQueue.isEmpty) return;

    final index = queueIndex.clamp(0, restoreQueue.length - 1);
    await setQueue(restoreQueue, index, autoPlay: false);
    if (positionMs > 0) {
      await playback.player.seek(Duration(milliseconds: positionMs));
    }
    await prefs.setBool('resume_was_playing', false);
    _sessionRestored = true;
  }

  Future<void> checkAndRequestPermissions() async {
    if (_preview) return;
    if (library.permissionGranted && library.songs.isNotEmpty) return;

    final granted = await library.permissions.requestAudioAccess();
    if (granted) {
      library.permissionGranted = true;
      await library.permissions.ensureNotificationPermission();
      await loadMedia();
      await _markMediaGranted();
    } else {
      library.permissionGranted = false;
    }
    notifyListeners();
  }

  Future<void> _markMediaGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMediaGranted, true);
    await prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<bool> wasMediaGrantedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMediaGranted) ?? false;
  }

  static Future<bool> wasOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> refreshPermissionStatus({bool loadLibrary = true}) async {
    if (_preview) return;
    if (await library.permissions.hasAudioAccess()) {
      library.permissionGranted = true;
      if (loadLibrary) await loadMedia();
      await _markMediaGranted();
    } else {
      library.permissionGranted = false;
    }
    notifyListeners();
  }

  Future<void> ensureLibraryLoaded() async {
    if (_preview) return;
    if (!library.permissionGranted) return;
    if (library.songs.isNotEmpty && _sessionRestored) return;
    await loadMedia();
  }

  Future<void> loadMedia({int retryCount = 0}) async {
    if (_preview) return;
    if (!library.permissionGranted || library.isBusy) return;
    library.isBusy = true;
    library.isLoading = true;
    notifyListeners();

    try {
      await library.querySongs(retryCount: retryCount);
      await library.loadVideosIfAllowed();
      await stats.loadTop();
      if (!_sessionRestored) {
        await _tryResumePlayback();
      }
    } catch (e) {
      debugPrint('Error loading media: $e');
      if (e.toString().contains('database is locked') && retryCount < 3) {
        library.isBusy = false;
        return loadMedia(retryCount: retryCount + 1);
      }
    } finally {
      library.isLoading = false;
      library.isBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshLibrary() => loadMedia();

  Future<void> onAppPaused() async {
    await savePlaybackState();
  }

  Future<void> setQueue(List<SongModel> songs, int index, {bool autoPlay = true}) async {
    if (songs.isEmpty) return;
    if (!_listenersReady) _bindPlayback();
    queueService.replace(songs, index);
    await playback.prepareTransport();
    await queueService.loadInto(playback.player, gapless: playback.gaplessEnabled);
    if (autoPlay) {
      playback.uiPlaying = true;
      playback.userWantsPlayback = true;
      notifyListeners();
      await playback.applyUiState();
    } else {
      playback.uiPlaying = false;
      playback.userWantsPlayback = false;
      await playback.holdWake(false);
      notifyListeners();
    }
    final song = queueService.current;
    if (song != null) {
      library.remember(SongUtils.songId(song));
      await _persistRecent();
      await loadLyrics(song);
      await _updateDynamicAccent(song.id);
    }
    notifyListeners();
  }

  void playSongInLibrary(SongModel song, {List<SongModel>? contextList}) {
    final list = contextList ?? filteredSongs;
    final index = list.indexWhere((s) => s.id == song.id);
    if (index == -1) {
      setQueue([song], 0);
    } else {
      setQueue(list, index);
    }
  }

  /// [newIndex] est l'index final (après retrait) quand [alreadyFinal] est vrai,
  /// comme le fournit `ReorderableListView.onReorderItem`.
  Future<void> reorderQueue(int oldIndex, int newIndex, {bool alreadyFinal = false}) async {
    if (queueService.items.length < 2) return;
    final target = alreadyFinal ? newIndex : QueueService.audioMoveTarget(oldIndex, newIndex);
    if (oldIndex == target) return;
    queueService.reorder(oldIndex, newIndex, adjustForRemoval: !alreadyFinal);
    final src = playback.isPlayerOpen ? playback.player.audioSource : null;
    if (src is ConcatenatingAudioSource) {
      await src.move(oldIndex, target.clamp(0, queueService.items.length - 1));
    }
    notifyListeners();
    await savePlaybackState();
  }

  void setSpeed(double value) {
    playback.setSpeed(value);
    _persistPref('playback_speed', value);
    notifyListeners();
  }

  void setPitch(double pitch) {
    playback.setPitch(pitch);
    notifyListeners();
  }

  void toggleShuffle() => playback.toggleShuffle(notifyListeners);

  void cycleRepeatMode() => playback.cycleRepeat(notifyListeners);

  void forceRepeatOne() => playback.forceRepeatOne(notifyListeners);

  Future<void> toggleFavorite(String songId) async {
    if (library.favorites.contains(songId)) {
      library.favorites.remove(songId);
    } else {
      library.favorites.add(songId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', library.favorites);
    notifyListeners();
  }

  void togglePlayPause() => playback.togglePlayPause(notifyListeners);

  Future<void> play() => playback.play(notifyListeners);

  Future<void> pause() => playback.pause(notifyListeners);

  void playNext() => playback.playNext();
  void playPrevious() => playback.playPrevious();

  void setSleepTimer(Duration duration, {bool endOfTrack = false}) {
    playback.setSleepTimer(duration, endOfTrack: endOfTrack, notify: notifyListeners);
  }

  void cancelSleepTimer() => playback.cancelSleepTimer(notifyListeners);

  void setPointA() => playback.setPointA(notifyListeners);

  void setPointB() => playback.setPointB(notifyListeners);

  void setABLoopMax(int count) => playback.setABLoopMax(count, notifyListeners);

  void clearABLoop() {
    playback.clearABLoop();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    library.searchQuery = query;
    library.invalidateFilter();
    notifyListeners();
  }

  void setSongSort(SongSort sort) {
    library.songSort = sort;
    library.sortOrder = sort.defaultOrder;
    _persistPref('song_sort', sort.index);
    _persistBool('song_sort_desc', library.sortOrder == SortOrder.descending);
    library.invalidateFilter();
    notifyListeners();
  }

  void toggleSortOrder() {
    library.sortOrder =
        library.sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending;
    _persistBool('song_sort_desc', library.sortOrder == SortOrder.descending);
    library.invalidateFilter();
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    library.sortOrder = order;
    _persistBool('song_sort_desc', order == SortOrder.descending);
    library.invalidateFilter();
    notifyListeners();
  }

  Future<void> setHideShortSounds(bool value) async {
    library.hideShortSounds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_short_sounds', value);
    await loadMedia();
  }

  Future<void> addExcludedFolder(String path) async {
    library.excludedFolders.add(path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('excluded_folders', library.excludedFolders.toList());
    library.invalidateFilter();
    notifyListeners();
  }

  Future<void> removeExcludedFolder(String path) async {
    library.excludedFolders.remove(path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('excluded_folders', library.excludedFolders.toList());
    library.invalidateFilter();
    notifyListeners();
  }

  void setUseDynamicAccent(bool value) {
    _useDynamicAccent = value;
    _persistBool('use_dynamic_accent', value);
    notifyListeners();
  }

  Future<void> loadLyrics(SongModel song) async {
    _currentLyrics = await LyricsLoader.loadFromPath(song.data);
    notifyListeners();
  }

  Future<String> createPlaylist(String name) async {
    final id = await library.createPlaylist(name);
    notifyListeners();
    return id;
  }

  Future<void> renamePlaylist(String id, String name) async {
    await library.renamePlaylist(id, name);
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    await library.deletePlaylist(id);
    notifyListeners();
  }

  Future<List<SongModel>> getPlaylistSongs(String playlistId) => library.playlistSongs(playlistId);

  Future<void> addToPlaylist(String playlistId, SongModel song) async {
    await library.addToPlaylist(playlistId, song);
    notifyListeners();
  }

  Future<void> removeFromPlaylist(String playlistId, String songId) async {
    await library.removeFromPlaylist(playlistId, songId);
    notifyListeners();
  }

  Future<Map<String, int>> getListeningSummary() => stats.summary();

  /// Fraction 0–1 utilisée seulement par les captures, quand aucun
  /// moteur audio n'est branché. Nulle en usage réel.
  @visibleForTesting
  double? previewProgress;

  double resolvedProgress({
    required Duration position,
    required Duration duration,
  }) {
    final seeded = previewProgress;
    if (seeded != null) return seeded.clamp(0.0, 1.0);
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  (Duration, Duration) resolvedClock({
    required Duration position,
    required Duration duration,
    required int songMs,
  }) {
    final seeded = previewProgress;
    if (seeded != null && songMs > 0) {
      return (Duration(milliseconds: (songMs * seeded).round()), Duration(milliseconds: songMs));
    }
    return (position, duration);
  }

  @visibleForTesting
  void seedPreview({
    List<SongModel> songs = const [],
    List<LocalPlaylist> playlists = const [],
    List<String> favoriteIds = const [],
    List<String> recentIds = const [],
    List<String> topPlayedIds = const [],
    Map<String, int>? summary,
    Map<String, List<SongModel>>? playlistSongs,
    bool permissionGranted = true,
    SongModel? current,
    bool playing = false,
    double? previewProgress,
  }) {
    _preview = true;
    this.previewProgress = previewProgress;
    _sessionRestored = true;
    library.permissionGranted = permissionGranted;
    library.songs = List<SongModel>.from(songs);
    library.playlists = playlists;
    library.favorites = List<String>.from(favoriteIds);
    library.recentlyPlayedIds = List<String>.from(recentIds);
    library.isLoading = false;
    library.invalidateFilter();
    stats.topPlayedIds = topPlayedIds;
    stats.previewSummary = summary;
    if (playlistSongs != null) library.previewPlaylistSongs.addAll(playlistSongs);
    if (current != null) {
      final list = List<SongModel>.from(library.songs);
      var index = list.indexWhere((s) => s.id == current.id);
      if (index < 0) {
        list.insert(0, current);
        index = 0;
      }
      queueService.replace(list, index);
      playback.uiPlaying = playing;
    }
    notifyListeners();
  }

  void _persistPref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) await prefs.setDouble(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  void _persistBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  void dispose() {
    savePlaybackState();
    playback.dispose();
    super.dispose();
  }
}
