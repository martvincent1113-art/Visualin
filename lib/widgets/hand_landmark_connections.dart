/// A line in the 21-point MediaPipe hand skeleton.
class HandLandmarkConnection {
  const HandLandmarkConnection(this.startIndex, this.endIndex);

  final int startIndex;
  final int endIndex;
}

/// MediaPipe's canonical hand topology: finger chains plus the outer palm.
///
/// Landmark indices are wrist (0), then thumb through pinky in four-point
/// chains. Keeping this explicit avoids joining adjacent list indices, which
/// incorrectly links one finger's tip to the next finger's base.
const List<HandLandmarkConnection> handLandmarkConnections =
    <HandLandmarkConnection>[
  HandLandmarkConnection(0, 1),
  HandLandmarkConnection(1, 2),
  HandLandmarkConnection(2, 3),
  HandLandmarkConnection(3, 4),
  HandLandmarkConnection(0, 5),
  HandLandmarkConnection(5, 6),
  HandLandmarkConnection(6, 7),
  HandLandmarkConnection(7, 8),
  HandLandmarkConnection(5, 9),
  HandLandmarkConnection(9, 10),
  HandLandmarkConnection(10, 11),
  HandLandmarkConnection(11, 12),
  HandLandmarkConnection(9, 13),
  HandLandmarkConnection(13, 14),
  HandLandmarkConnection(14, 15),
  HandLandmarkConnection(15, 16),
  HandLandmarkConnection(13, 17),
  HandLandmarkConnection(17, 18),
  HandLandmarkConnection(18, 19),
  HandLandmarkConnection(19, 20),
  HandLandmarkConnection(0, 17),
];

/// The terminal landmark in each MediaPipe finger chain.
const Set<int> handLandmarkFingertips = <int>{4, 8, 12, 16, 20};
