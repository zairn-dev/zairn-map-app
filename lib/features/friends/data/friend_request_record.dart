class FriendRequestRecord {
  const FriendRequestRecord({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String fromUserId;
  final String toUserId;
  final String status;
  final DateTime? createdAt;

  factory FriendRequestRecord.fromMap(Map<String, dynamic> map) {
    return FriendRequestRecord(
      id: map['id'] as int,
      fromUserId: map['from_user_id'] as String,
      toUserId: map['to_user_id'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}
