import 'package:flutter_test/flutter_test.dart';
import 'package:visualin/widgets/hand_landmark_connections.dart';

void main() {
  test('uses the canonical 21-link MediaPipe hand topology', () {
    final pairs = handLandmarkConnections
        .map((connection) =>
            '${connection.startIndex}-${connection.endIndex}')
        .toSet();

    expect(pairs, <String>{
      '0-1', '1-2', '2-3', '3-4',
      '0-5', '5-6', '6-7', '7-8',
      '5-9', '9-10', '10-11', '11-12',
      '9-13', '13-14', '14-15', '15-16',
      '13-17', '17-18', '18-19', '19-20',
      '0-17',
    });
    expect(handLandmarkConnections, hasLength(21));
  });

  test('does not join a fingertip directly to the next finger base', () {
    final pairs = handLandmarkConnections
        .map((connection) =>
            '${connection.startIndex}-${connection.endIndex}')
        .toSet();

    expect(pairs, isNot(contains('4-5')));
    expect(pairs, isNot(contains('8-9')));
    expect(pairs, isNot(contains('12-13')));
    expect(pairs, isNot(contains('16-17')));
    expect(handLandmarkFingertips, <int>{4, 8, 12, 16, 20});
  });
}
