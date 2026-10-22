import 'package:donziker/services/queue_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyReorder suit ReorderableListView', () {
    final result = QueueService.applyReorder(['a', 'b', 'c', 'd'], 1, 0, 3);
    expect(result.items, ['b', 'c', 'a', 'd']);
    expect(result.currentIndex, 0);
    expect(QueueService.audioMoveTarget(0, 3), 2);
  });

  test('applyReorder vers le haut décale la lecture', () {
    final result = QueueService.applyReorder(['a', 'b', 'c', 'd'], 0, 3, 1);
    expect(result.items, ['a', 'd', 'b', 'c']);
    expect(result.currentIndex, 0);
  });
}
