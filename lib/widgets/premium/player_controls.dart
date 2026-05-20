import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  final MusicProvider provider;
  final VoidCallback onPlayPause;

  const PlayerControls({
    super.key,
    required this.provider,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleBtn(
          icon: Icons.shuffle_rounded,
          active: provider.isShuffle,
          color: c,
          onTap: provider.toggleShuffle,
        ),
        _CircleBtn(
          icon: Icons.skip_previous_rounded,
          size: 52,
          color: c,
          onTap: provider.playPrevious,
        ),
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accent, c.accent.withValues(alpha: 0.75)],
              ),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 44,
              color: c.scheme.onPrimary,
            ),
          ),
        ),
        _CircleBtn(
          icon: Icons.skip_next_rounded,
          size: 52,
          color: c,
          onTap: provider.playNext,
        ),
        _CircleBtn(
          icon: provider.repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          active: provider.repeatMode != RepeatMode.none,
          color: c,
          onTap: provider.cycleRepeatMode,
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool active;
  final DzColors color;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 44,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color.accent.withValues(alpha: 0.18) : color.card.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: active ? color.accent : color.primaryText.withValues(alpha: 0.85),
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
