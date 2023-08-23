import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChat {
  final String groupId;
  final String groupName;
  final List<String> participants;
  final String lastMessage;
  final Timestamp timestamp;
  final String imageUrl;

  GroupChat({
    required this.groupId,
    required this.groupName,
    required this.participants,
    required this.lastMessage,
    required this.timestamp,
    required this.imageUrl,
  });

  factory GroupChat.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return GroupChat(
        groupId: snapshot.id,
        groupName: data['groupName'],
        participants: List<String>.from(data['participants']),
        lastMessage: data['lastMessage'],
        timestamp: data['timestamp'],
        imageUrl: data['imageUrl']);
  }
}
