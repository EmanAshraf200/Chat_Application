import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:scholar_chat/Screens/group_model.dart';

import 'package:scholar_chat/Screens/groupchatscreen.dart';

class HomePageGroup extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePageGroup> {
  Stream<QuerySnapshot> groupChatsStream = FirebaseFirestore.instance
      .collection('Groups')
      .where('participants',
          arrayContains: FirebaseAuth.instance.currentUser!.email)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(255, 165, 153, 200),
                const Color.fromARGB(255, 96, 62, 191)
              ],
            ),
          ),
        ),
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(
            "assets/images/3d-smartphone-function-icon-illustration-png.webp",
            height: 70,
          ),
          Text('Chat')
        ]),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: groupChatsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          List<QueryDocumentSnapshot> groupChatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groupChatDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot groupChatDoc = groupChatDocs[index];
              GroupChat groupChat = GroupChat.fromSnapshot(groupChatDoc);

              Stream<QuerySnapshot> messagesStream = FirebaseFirestore.instance
                  .collection('Groups')
                  .doc(groupChat.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .snapshots();

              return StreamBuilder<QuerySnapshot>(
                stream: messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return buildListTile(groupChat, "No messages yet", "");
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return buildListTile(groupChat, "No messages yet", "");
                  }

                  QueryDocumentSnapshot lastMessageDoc =
                      snapshot.data!.docs.first;
                  String lastMessageText = lastMessageDoc['text'];
                  Timestamp lastMessageTimestamp = lastMessageDoc['timestamp'];
                  String lastMessageDate =
                      DateFormat('HH:mm').format(lastMessageTimestamp.toDate());

                  return buildListTile(
                      groupChat, lastMessageText, lastMessageDate);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildListTile(GroupChat groupChat, String subtitle, String trailing) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(groupChat.imageUrl),
          ),
          title: Text(groupChat.groupName),
          subtitle: Text(subtitle),
          trailing: Text(trailing),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(
                    groupId: groupChat.groupId,
                    groupName: groupChat.groupName,
                    imageUrl: groupChat.imageUrl),
              ),
            );
          },
        ),
        Divider(
          color: Colors.grey,
          thickness: 0.5,
          indent: 16.0,
          endIndent: 16.0,
        ),
      ],
    );
  }
}
