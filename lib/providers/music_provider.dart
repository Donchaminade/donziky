import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _playlist = [];
  int _currentIndex = -1;
  double _speed = 1.0;
  List<int> _favorites = [];

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;
  SongModel? get currentSong => _currentIndex != -1 ? _playlist[_currentIndex] : null;
  double get speed => _speed;
  List<int> get favorites => _favorites;
  bool isFavorite(int songId) => _favorites.contains(songId);

  MusicProvider() {
    _loadFavorites();
  }

  // Setters
  void setPlaylist(List<SongModel> songs, int index) {
    _playlist = songs;
    _currentIndex = index;
    _playCurrentSong();
    notifyListeners();
  }

  void setSpeed(double speed) {
    _speed = speed;
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  // Favorites
  void _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites');
    if (favorites != null) {
      _favorites = favorites.map((id) => int.parse(id)).toList();
      notifyListeners();
    }
  }

  void toggleFavorite(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
    } else {
      _favorites.add(songId);
    }
    await prefs.setStringList('favorites', _favorites.map((id) => id.toString()).toList());
    notifyListeners();
  }


  void _playCurrentSong() async {
    if (currentSong != null) {
      try {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(currentSong!.uri!)),
        );
        _audioPlayer.play();
        _audioPlayer.setSpeed(_speed);
      } catch (e) {
        // Gérer les erreurs de lecture
      }
    }
  }

  void play() {
    _audioPlayer.play();
    notifyListeners();
  }

  void pause() {
    _audioPlayer.pause();
    notifyListeners();
  }

  void playNext() {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      _playCurrentSong();
      notifyListeners();
    }
  }

  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _playCurrentSong();
      notifyListeners();
    }
  }
}