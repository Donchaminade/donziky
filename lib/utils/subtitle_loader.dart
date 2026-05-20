import 'dart:io';

class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({required this.start, required this.end, required this.text});
}

class SubtitleLoader {
  static Future<List<SubtitleCue>> loadFromVideoPath(String videoPath) async {
    final base = videoPath.replaceAll(RegExp(r'\.[^.\\/]+$'), '');
    for (final ext in ['.srt', '.SRT', '.vtt', '.VTT']) {
      final file = File('$base$ext');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (ext.toLowerCase().contains('vtt')) {
          return _parseVtt(content);
        }
        return _parseSrt(content);
      }
    }
    return [];
  }

  static List<SubtitleCue> _parseSrt(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.split(RegExp(r'\n\s*\n'));
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;
      final timeLine = lines.length >= 3 ? lines[1] : lines[0];
      final textStart = lines.length >= 3 ? 2 : 1;
      final match = RegExp(r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})')
          .firstMatch(timeLine);
      if (match == null) continue;
      final start = _toDuration(match, 1);
      final end = _toDuration(match, 5);
      final text = lines.sublist(textStart).join('\n');
      cues.add(SubtitleCue(start: start, end: end, text: text));
    }
    return cues;
  }

  static Duration _toDuration(RegExpMatch m, int offset) {
    final h = int.parse(m.group(offset)!);
    final min = int.parse(m.group(offset + 1)!);
    final s = int.parse(m.group(offset + 2)!);
    final ms = int.parse(m.group(offset + 3)!);
    return Duration(hours: h, minutes: min, seconds: s, milliseconds: ms);
  }

  static List<SubtitleCue> _parseVtt(String content) {
    final lines = content.split('\n');
    final cues = <SubtitleCue>[];
    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.contains('-->')) {
        final match = RegExp(r'(\d{2}:)?(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2}:)?(\d{2}):(\d{2})\.(\d{3})').firstMatch(line);
        if (match != null) {
          // Simplified VTT parse
          final textLines = <String>[];
          i++;
          while (i < lines.length && lines[i].trim().isNotEmpty) {
            textLines.add(lines[i]);
            i++;
          }
          if (textLines.isNotEmpty) {
            cues.add(SubtitleCue(
              start: Duration.zero,
              end: const Duration(hours: 1),
              text: textLines.join('\n'),
            ));
          }
        }
      }
      i++;
    }
    return cues;
  }

  static SubtitleCue? cueAt(List<SubtitleCue> cues, Duration position) {
    for (final c in cues) {
      if (position >= c.start && position < c.end) return c;
    }
    return null;
  }
}
