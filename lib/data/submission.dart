class Submission {
  final String? id; // null until saved to Firestore
  final String deviceNotes;
  final List<
    String
  >
  topGuesses;
  final String status; // "pending" | "confirmed" | "relabeled" | "rejected"
  final String? confirmedAs;

  // "unrecognized": all 4 capture attempts failed to meet threshold with no split-probability candidate.
  //  "disambiguation_unresolved": user tapped "I'm Not Sure" on the Produce Disambiguation Screen. (Screen ng Unresolved Image)
  final String submissionType;

  const Submission({
    this.id,
    required this.deviceNotes,
    required this.topGuesses,
    this.status = 'pending',
    this.confirmedAs,
    this.submissionType = 'unrecognized',
  });

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'deviceNotes': deviceNotes,
      'topGuesses': topGuesses,
      'status': status,
      'confirmedAs': confirmedAs,
      'submissionType': submissionType,
    };
  }
}
