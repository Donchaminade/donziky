import 'package:donziker/theme/app_theme.dart';
import 'package:donziker/theme/theme_extensions.dart';
import 'package:donziker/utils/song_utils.dart';
import 'package:donziker/widgets/motion/pressable_scale.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class LibraryPlaylistCard extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const LibraryPlaylistCard({super.key, required this.name, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.lime,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.queue_music_rounded, color: AppTheme.ink),
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.primaryText),
            ),
            Text('$count titres', style: TextStyle(fontSize: 12, color: c.secondaryText)),
          ],
        ),
      ),
    );
  }
}

class LibraryArtistTile extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const LibraryArtistTile({super.key, required this.name, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.ink,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c.primaryText)),
                    Text('$count titres', style: TextStyle(fontSize: 13, color: c.secondaryText)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.tertiaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class LibrarySimpleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const LibrarySimpleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: c.isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.lime,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.ink),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: c.primaryText)),
          subtitle: Text(subtitle, style: TextStyle(color: c.secondaryText)),
          trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: c.tertiaryText),
          onTap: onTap,
        ),
      ),
    );
  }
}

class LibraryEmpty extends StatelessWidget {
  final String title;
  final String? subtitle;

  const LibraryEmpty({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = context.dz;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.library_music_outlined, size: 56, color: c.tertiaryText),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: c.primaryText)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: c.secondaryText)),
          ],
        ],
      ),
    );
  }
}

String libraryFolderLabel(List<SongModel> songs) => SongUtils.folderName(songs.first);
