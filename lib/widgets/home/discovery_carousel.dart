import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/widgets/motion/pressable_scale.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class DiscoveryCardData {
  final String badge;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final SongModel? song;
  final List<SongModel> queue;
  final int index;

  const DiscoveryCardData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.queue,
    this.song,
    this.index = 0,
  });
}

class DiscoveryCarousel extends StatefulWidget {
  final List<DiscoveryCardData> cards;

  const DiscoveryCarousel({super.key, required this.cards});

  @override
  State<DiscoveryCarousel> createState() => _DiscoveryCarouselState();
}

class _DiscoveryCarouselState extends State<DiscoveryCarousel> {
  late final PageController _controller = PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 292,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              var delta = 0.0;
              if (_controller.hasClients && _controller.position.haveDimensions) {
                delta = (_controller.page ?? _controller.initialPage.toDouble()) - index;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _DiscoveryCard(data: widget.cards[index], parallax: delta),
              );
            },
          );
        },
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final DiscoveryCardData data;
  final double parallax;

  const _DiscoveryCard({required this.data, required this.parallax});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        final song = data.song;
        if (song == null || data.queue.isEmpty) return;
        context.read<MusicProvider>().setQueue(data.queue, data.index);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.translate(
                    offset: Offset(parallax * -36, 0),
                    child: _Artwork(data: data),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.lime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.badge,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppTheme.ink,
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFB5B5B5), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppTheme.lime, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: AppTheme.ink, size: 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final DiscoveryCardData data;

  const _Artwork({required this.data});

  @override
  Widget build(BuildContext context) {
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradient,
        ),
      ),
      child: const SizedBox.expand(),
    );
    final song = data.song;
    if (song == null) return gradient;
    return Stack(
      fit: StackFit.expand,
      children: [
        gradient,
        QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          artworkWidth: 800,
          artworkHeight: 800,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: const SizedBox.expand(),
        ),
      ],
    );
  }
}
