import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/local_playlist.dart';
import '../models/song_sort.dart';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import '../utils/lyrics_loader.dart';
import '../utils/song_utils.dart';

enum RepeatMode { none, one, all }

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final DatabaseService _db = DatabaseService();
  final PermissionService _permissions = PermissionService();

  static const _keyMediaGranted = 'media_access_granted';
  static const _keyOnboardingDone = 'onboarding_completed';

  List<SongModel> _librarySongs = [];
  List<SongModel> _queue = [];
  List<AssetEntity> _videos = [];
  List<LocalPlaylist> _playlists = [];

  int _currentIndex = -1;
  double _speed = 1.0;
  List<String> _favorites = [];
  List<String> _recentlyPlayedIds = [];
  Set<String> _excludedFolders = {};
  bool _isLoading = false;
  bool _permissionGranted = false;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.none;
  Color _dynamicAccentColor = Colors.redAccent;
  bool _useDynamicAccent = true;

  Timer? _sleepTimer;
  StreamSubscription<ProcessingState>? _endOfTrackSub;
  Duration? _sleepTimerRemaining;
  DateTime? _sleepTimerEndsAt;

  Duration? _pointA;
  Duration? _pointB;
  bool _isABLoopActive = false;
  int _abLoopCount = 0;
  int _abLoopMax = 0;

  String _searchQuery = '';
  String? _currentLyrics;
  SongSort _songSort = SongSort.title;
  bool _hideShortSounds = true;
  int _minDurationMs = 10000;
  bool _gaplessEnabled = true;
  bool _karaokeMode = false;
  int _karaokeLeadSeconds = 8;
  int? _karaokeSkippedForIndex;

  int _shellTabIndex = 0;
  int _libraryTabIndex = 0;
  String? _scrollToSongId;

  Duration _lastStatsPosition = Duration.zero;
  Duration _lastSavedPosition = Duration.zero;

  bool get isPlaying => _audioPlayer.playing;
  SongModel? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  List<SongModel> get songs => _librarySongs;
  List<SongModel> get queue => _queue;
  List<AssetEntity> get videos => _videos;
  List<LocalPlaylist> get playlists => _playlists;
  double get speed => _speed;
  List<String> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get permissionGranted => _permissionGranted;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  Color get dynamicAccentColor => _dynamicAccentColor;
  bool get useDynamicAccent => _useDynamicAccent;
  String get searchQuery => _searchQuery;
  String? get currentLyrics => _currentLyrics;
  SongSort get songSort => _songSort;
  bool get hideShortSounds => _hideShortSounds;
  Set<String> get excludedFolders => _excludedFolders;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;
  Duration? get pointA => _pointA;
  Duration? get pointB => _pointB;
  bool get isABLoopActive => _isABLoopActive;
  int get abLoopMax => _abLoopMax;
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get karaokeMode => _karaokeMode;
  int get karaokeLeadSeconds => _karaokeLeadSeconds;
  int get shellTabIndex => _shellTabIndex;
  int get libraryTabIndex => _libraryTabIndex;
  String? get scrollToSongId => _scrollToSongId;

  bool isFavorite(String songId) => _favorites.contains(songId);

  List<SongModel> get filteredSongs => SongUtils.sortSongs(
        SongUtils.filterSongs(
          _librarySongs,
          query: _searchQuery,
          excludedFolders: _excludedFolders,
          minDurationMs: _minDurationMs,
          hideShortSounds: _hideShortSounds,
        ),
        _songSort,
      );

  List<SongModel> get recentlyPlayed {
    final result = <SongModel>[];
    for (final id in _recentlyPlayedIds) {
      for (final s in _librarySongs) {
        if (SongUtils.songId(s) == id) {
          result.add(s);
          break;
        }
      }
    }
    return result;
  }

  List<SongModel> get favoriteSongs =>
      _librarySongs.where((s) => isFavorite(SongUtils.songId(s))).toList();

  List<SongModel> get smartRecentlyAdded {
    final sorted = List<SongModel>.from(_librarySongs);
    sorted.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    return sorted.take(15).toList();
  }

  List<SongModel> get smartMostPlayed {
    final result = <SongModel>[];
    for (final id in _topPlayedIds) {
      for (final s in _librarySongs) {
        if (SongUtils.songId(s) == id) {
          result.add(s);
          break;
        }
      }
    }
    return result;
  }

  List<String> _topPlayedIds = [];

  MusicProvider();

  Future<void> init() async {
    try {
      await _loadPreferences();
      await _loadPlaylists();
      await _loadTopPlayed();
      _setupAudioListeners();
    } catch (e) {
      debugPrint('MusicProvider.init error: $e');
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (_repeatMode == RepeatMode.one) {
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.play();
        } else {
          playNext();
        }
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (_isABLoopActive && _pointA != null && _pointB != null && position >= _pointB!) {
        if (_abLoopMax > 0) {
          _abLoopCount++;
          if (_abLoopCount >= _abLoopMax) {
            clearABLoop();
            pause();
            return;
          }
        }
        _audioPlayer.seek(_pointA!);
      }
      _tickSleepTimer();
      _tickStats(position);
      _tickKaraoke(position);
      _tickPeriodicSave(position);
    });

    _audioPlayer.currentIndexStream.listen((index) async {
      if (index != null && index != _currentIndex && index < _queue.length) {
        _currentIndex = index;
        _karaokeSkippedForIndex = null;
        final song = _queue[_currentIndex];
        _addToRecentlyPlayed(SongUtils.songId(song));
        await loadLyrics(song);
        await _updateDynamicAccent(song.id);
        notifyListeners();
      }
    });
  }

  void _tickStats(Duration position) {
    if (!isPlaying || currentSong == null) return;
    final delta = position - _lastStatsPosition;
    _lastStatsPosition = position;
    if (delta.inMilliseconds > 500 && delta.inMilliseconds < 5000) {
      _db.recordPlay(SongUtils.songId(currentSong!), delta.inMilliseconds);
    }
  }

  void _tickKaraoke(Duration position) {
    if (!_karaokeMode || !isPlaying || currentSong == null) return;
    final dur = _audioPlayer.duration;
    if (dur == null || dur.inMilliseconds < 3000) return;
    final remaining = dur - position;
    if (remaining > Duration(seconds: _karaokeLeadSeconds)) return;
    if (remaining < const Duration(milliseconds: 300)) return;
    if (_karaokeSkippedForIndex == _currentIndex) return;
    _karaokeSkippedForIndex = _currentIndex;
    playNext();
  }

  void toggleKaraokeMode() {
    _karaokeMode = !_karaokeMode;
    _karaokeSkippedForIndex = null;
    _persistBool('karaoke_mode', _karaokeMode);
    notifyListeners();
  }

  void setKaraokeLeadSeconds(int seconds) {
    _karaokeLeadSeconds = seconds.clamp(3, 30);
    _persistPref('karaoke_lead_seconds', _karaokeLeadSeconds);
    notifyListeners();
  }

  void requestLocateCurrentSong() {
    final song = currentSong;
    if (song == null) return;
    _shellTabIndex = 1;
    _libraryTabIndex = 0;
    _scrollToSongId = SongUtils.songId(song);
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

  void _tickSleepTimer() {
    if (_sleepTimerEndsAt == null) return;
    final left = _sleepTimerEndsAt!.difference(DateTime.now());
    if (left.isNegative) {
      _sleepTimerRemaining = null;
      _sleepTimerEndsAt = null;
    } else {
      _sleepTimerRemaining = left;
    }
    notifyListeners();
  }

  Future<void> _updateDynamicAccent(int songId) async {
    if (!_useDynamicAccent) return;
    try {
      final artwork = await _audioQuery.queryArtwork(songId, ArtworkType.AUDIO, size: 200);
      if (artwork != null) {
        final palette = await PaletteGenerator.fromImageProvider(MemoryImage(artwork));
        _dynamicAccentColor =
            palette.dominantColor?.color ?? palette.vibrantColor?.color ?? _dynamicAccentColor;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Accent extraction error: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('favorites') ?? [];
    _recentlyPlayedIds = prefs.getStringList('recently_played') ?? [];
    _excludedFolders = (prefs.getStringList('excluded_folders') ?? []).toSet();
    _speed = prefs.getDouble('playback_speed') ?? 1.0;
    _hideShortSounds = prefs.getBool('hide_short_sounds') ?? true;
    _minDurationMs = prefs.getInt('min_duration_ms') ?? 10000;
    _useDynamicAccent = prefs.getBool('use_dynamic_accent') ?? true;
    _gaplessEnabled = prefs.getBool('gapless_enabled') ?? true;
    _karaokeMode = prefs.getBool('karaoke_mode') ?? false;
    _karaokeLeadSeconds = prefs.getInt('karaoke_lead_seconds') ?? 8;
    final sortIndex = prefs.getInt('song_sort') ?? 0;
    _songSort = SongSort.values[sortIndex.clamp(0, SongSort.values.length - 1)];
    _audioPlayer.setSpeed(_speed);
    notifyListeners();
  }

  Future<void> _loadPlaylists() async {
    _playlists = await _db.getPlaylists();
    notifyListeners();
  }

  Future<void> _loadTopPlayed() async {
    final rows = await _db.getTopPlayed(20);
    _topPlayedIds = rows.map((r) => r['song_id'] as String).toList();
    notifyListeners();
  }

  void _tickPeriodicSave(Duration position) {
    if (!isPlaying || currentSong == null) return;
    if ((position - _lastSavedPosition).inSeconds.abs() < 4) return;
    _lastSavedPosition = position;
    savePlaybackState();
  }

  /// Sauvegarde position, file d'attente et état lecture (pause / en cours).
  Future<void> savePlaybackState() async {
    final song = currentSong;
    if (song == null || _queue.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_song_id', SongUtils.songId(song));
    await prefs.setInt('resume_position_ms', _audioPlayer.position.inMilliseconds);
    await prefs.setBool('resume_was_playing', isPlaying);
    await prefs.setStringList('resume_queue_ids', _queue.map((s) => SongUtils.songId(s)).toList());
    await prefs.setInt('resume_queue_index', _currentIndex);
  }

  Future<void> _tryResumePlayback() async {
    final prefs = await SharedPreferences.getInstance();
    final positionMs = prefs.getInt('resume_position_ms') ?? 0;
    final wasPlaying = prefs.getBool('resume_was_playing') ?? false;
    final queueIds = prefs.getStringList('resume_queue_ids');
    final queueIndex = prefs.getInt('resume_queue_index') ?? 0;

    List<SongModel> restoreQueue = [];
    if (queueIds != null && queueIds.isNotEmpty) {
      for (final id in queueIds) {
        for (final s in _librarySongs) {
          if (SongUtils.songId(s) == id) {
            restoreQueue.add(s);
            break;
          }
        }
      }
    }

    if (restoreQueue.isEmpty) {
      final songId = prefs.getString('resume_song_id');
      if (songId == null) return;
      for (final s in _librarySongs) {
        if (SongUtils.songId(s) == songId) {
          restoreQueue = [s];
          break;
        }
      }
    }

    if (restoreQueue.isEmpty) return;

    final index = queueIndex.clamp(0, restoreQueue.length - 1);
    await setQueue(restoreQueue, index, autoPlay: wasPlaying);
    if (positionMs > 0) {
      await _audioPlayer.seek(Duration(milliseconds: positionMs));
      if (wasPlaying) await _audioPlayer.play();
    }
  }

  Future<void> refreshPermissionStatus() async {
    if (await _permissions.hasAudioAccess()) {
      _permissionGranted = true;
      await loadMedia();
      await _markMediaGranted();
    } else {
      _permissionGranted = false;
    }
    notifyListeners();
  }

  Future<void> checkAndRequestPermissions() async {
    if (_permissionGranted && _librarySongs.isNotEmpty) return;

    final granted = await _permissions.requestAudioAccess();
    if (granted) {
      _permissionGranted = true;
      await loadMedia();
      await _markMediaGranted();
    } else {
      _permissionGranted = false;
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

  bool _isBusy = false;

  Future<void> loadMedia({int retryCount = 0}) async {
    if (!_permissionGranted || _isBusy) return;
    _isBusy = true;
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(Duration(milliseconds: 300 + (retryCount * 500)));
      _librarySongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      if (_hideShortSounds) {
        _librarySongs =
            _librarySongs.where((s) => (s.duration ?? 0) >= _minDurationMs).toList();
      }

      await _loadVideosIfAllowed();
      await _loadTopPlayed();
      await _tryResumePlayback();
    } catch (e) {
      debugPrint('Error loading media: $e');
      if (e.toString().contains('database is locked') && retryCount < 3) {
        _isBusy = false;
        return loadMedia(retryCount: retryCount + 1);
      }
    } finally {
      _isLoading = false;
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _loadVideosIfAllowed() async {
    _videos = [];
    if (!await _permissions.hasVideoGalleryAccess()) {
      await _permissions.requestVideoGalleryAccess();
    }
    if (!await _permissions.hasVideoGalleryAccess()) return;

    try {
      final videoAlbums = await PhotoManager.getAssetPathList(type: RequestType.video);
      for (final album in videoAlbums.take(5)) {
        final assets = await album.getAssetListPaged(page: 0, size: 100);
        _videos.addAll(assets);
      }
    } catch (e) {
      debugPrint('Video load error: $e');
    }
    notifyListeners();
  }

  Future<void> refreshLibrary() => loadMedia();

  /// Appelé quand l'app passe en arrière-plan ou se ferme.
  Future<void> onAppPaused() async {
    await savePlaybackState();
  }

  Future<void> setQueue(List<SongModel> songs, int index, {bool autoPlay = true}) async {
    if (songs.isEmpty) return;
    _queue = List<SongModel>.from(songs);
    _currentIndex = index.clamp(0, _queue.length - 1);

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: _queue.map((song) {
        return AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: SongUtils.songId(song),
            album: song.album ?? 'Album inconnu',
            title: song.title,
            artist: song.artist ?? 'Artiste inconnu',
            artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
          ),
        );
      }).toList(),
    );

    await _audioPlayer.setAudioSource(
      playlist,
      initialIndex: _currentIndex,
      preload: _gaplessEnabled,
    );
    if (autoPlay) await _audioPlayer.play();
    final song = _queue[_currentIndex];
    _addToRecentlyPlayed(SongUtils.songId(song));
    await loadLyrics(song);
    await _updateDynamicAccent(song.id);
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

  void setSpeed(double speed) {
    _speed = speed;
    _audioPlayer.setSpeed(speed);
    _persistPref('playback_speed', speed);
    notifyListeners();
  }

  void setPitch(double pitch) {
    // just_audio supports pitch via setPitch on some platforms; speed used as proxy on Android
    try {
      _audioPlayer.setSpeed(_speed * pitch.clamp(0.5, 2.0));
    } catch (_) {}
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _audioPlayer.setShuffleModeEnabled(_isShuffle);
    if (_isShuffle) _audioPlayer.shuffle();
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
      case RepeatMode.one:
        _repeatMode = RepeatMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
      case RepeatMode.all:
        _repeatMode = RepeatMode.none;
        _audioPlayer.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  void forceRepeatOne() {
    _repeatMode = RepeatMode.one;
    _audioPlayer.setLoopMode(LoopMode.one);
    notifyListeners();
  }

  Future<void> toggleFavorite(String songId) async {
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
    } else {
      _favorites.add(songId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }

  void _addToRecentlyPlayed(String songId) async {
    _recentlyPlayedIds.remove(songId);
    _recentlyPlayedIds.insert(0, songId);
    if (_recentlyPlayedIds.length > 30) {
      _recentlyPlayedIds = _recentlyPlayedIds.take(30).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recently_played', _recentlyPlayedIds);
    notifyListeners();
  }

  Future<void> play() async {
    await _audioPlayer.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    await savePlaybackState();
    notifyListeners();
  }

  void playNext() => _audioPlayer.seekToNext();
  void playPrevious() => _audioPlayer.seekToPrevious();

  void setSleepTimer(Duration duration, {bool endOfTrack = false}) {
    _sleepTimer?.cancel();
    _endOfTrackSub?.cancel();
    if (endOfTrack) {
      _endOfTrackSub = _audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          pause();
          cancelSleepTimer();
        }
      });
      _sleepTimerEndsAt = null;
      _sleepTimerRemaining = null;
    } else {
      _sleepTimerEndsAt = DateTime.now().add(duration);
      _sleepTimerRemaining = duration;
      _sleepTimer = Timer(duration, () {
        pause();
        cancelSleepTimer();
      });
    }
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _endOfTrackSub?.cancel();
    _endOfTrackSub = null;
    _sleepTimer = null;
    _sleepTimerEndsAt = null;
    _sleepTimerRemaining = null;
    notifyListeners();
  }

  void setPointA() {
    _pointA = _audioPlayer.position;
    notifyListeners();
  }

  void setPointB() {
    _pointB = _audioPlayer.position;
    if (_pointA != null && _pointB! > _pointA!) {
      _isABLoopActive = true;
      _abLoopCount = 0;
      _audioPlayer.seek(_pointA!);
    }
    notifyListeners();
  }

  void setABLoopMax(int count) {
    _abLoopMax = count;
    notifyListeners();
  }

  void clearABLoop() {
    _pointA = null;
    _pointB = null;
    _isABLoopActive = false;
    _abLoopCount = 0;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSongSort(SongSort sort) {
    _songSort = sort;
    _persistPref('song_sort', sort.index);
    notifyListeners();
  }

  Future<void> setHideShortSounds(bool value) async {
    _hideShortSounds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_short_sounds', value);
    await loadMedia();
  }

  Future<void> addExcludedFolder(String path) async {
    _excludedFolders.add(path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('excluded_folders', _excludedFolders.toList());
    notifyListeners();
  }

  Future<void> removeExcludedFolder(String path) async {
    _excludedFolders.remove(path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('excluded_folders', _excludedFolders.toList());
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
    final id = await _db.createPlaylist(name);
    await _loadPlaylists();
    return id;
  }

  Future<void> renamePlaylist(String id, String name) async {
    await _db.renamePlaylist(id, name);
    await _loadPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _db.deletePlaylist(id);
    await _loadPlaylists();
  }

  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    final ids = await _db.getPlaylistSongIds(playlistId);
    final result = <SongModel>[];
    for (final id in ids) {
      for (final s in _librarySongs) {
        if (SongUtils.songId(s) == id) {
          result.add(s);
          break;
        }
      }
    }
    return result;
  }

  Future<void> addToPlaylist(String playlistId, SongModel song) async {
    await _db.addSongToPlaylist(playlistId, SongUtils.songId(song));
    await _loadPlaylists();
  }

  Future<void> removeFromPlaylist(String playlistId, String songId) async {
    await _db.removeSongFromPlaylist(playlistId, songId);
    await _loadPlaylists();
  }

  Future<Map<String, int>> getListeningSummary() => _db.getListeningSummary();

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
    _sleepTimer?.cancel();
    _endOfTrackSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
