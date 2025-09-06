import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/screens/favorites_screen.dart' show FavoritesScreen;
import 'package:donziker/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    checkAndRequestPermissions();
  }

  Future<void> checkAndRequestPermissions({bool retry = false}) async {
    // Demande la permission de stockage
    var status = await Permission.storage.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DonZiker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _hasPermission
          ? FutureBuilder<List<SongModel>>(
              future: _audioQuery.querySongs(
                sortType: SongSortType.TITLE,
                orderType: OrderType.ASC_OR_SMALLER,
                uriType: UriType.EXTERNAL,
                ignoreCase: true,
              ),
              builder: (context, item) {
                if (item.hasError) {
                  return Text(item.error.toString());
                }
                if (item.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (item.data!.isEmpty) {
                  return const Center(child: Text("Aucune chanson trouvée."));
                }
                return ListView.builder(
                  itemCount: item.data!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: QueryArtworkWidget(
                        id: item.data![index].id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
                      ),
                      title: Text(item.data![index].title, maxLines: 1),
                      subtitle: Text(item.data![index].artist ?? "Artiste inconnu", maxLines: 1),
                      onTap: () {
                        context.read<MusicProvider>().setPlaylist(item.data!, index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlayerScreen(),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Permission d'accès au stockage refusée."),
                  ElevatedButton(
                    onPressed: () => checkAndRequestPermissions(retry: true),
                    child: const Text("Réessayer"),
                  )
                ],
              ),
            ),
    );
  }
}