import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String imageUrl;

  GroupChatScreen({
    required this.groupId,
    required this.groupName,
    required this.imageUrl,
  });

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late Stream<QuerySnapshot> messagesStream;
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    messagesStream = FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void sendMessage() {
    final currentTime = Timestamp.now();
    FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'text': messageController.text,
      'timestamp': currentTime,
      'sender': FirebaseAuth.instance.currentUser!.email,
      'messageType': 'text',
    });
    messageController.clear();
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void sendImage(String imageUrl) {
    final currentTime = Timestamp.now();
    FirebaseFirestore.instance
        .collection('Groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'text': imageUrl,
      'timestamp': currentTime,
      'sender': FirebaseAuth.instance.currentUser!.email,
      'messageType': 'image',
      'imageUrl': imageUrl,
    });
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

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
                const Color.fromARGB(255, 96, 62, 191),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.imageUrl),
            ),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> messageDocs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messageDocs.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messageDocs[index].data() as Map<String, dynamic>;
                    final messageText = messageData['text'];
                    final messageType = messageData['messageType'];
                    final imageUrl = messageData['imageUrl'];
                    final messageFrom = messageData['sender'];
                    if (messageType == 'text') {
                      final isCurrentUser = messageFrom ==
                          FirebaseAuth.instance.currentUser!.email;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('email', isEqualTo: messageFrom)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox.shrink();
                          }

                          final userData = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final senderFullName =
                              '${userData['firstname']} ${userData['secondname']}';

                          return ListTile(
                            subtitle: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Color.fromARGB(255, 96, 62, 191)
                                      : Color.fromARGB(255, 165, 153, 200),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(28),
                                    topRight: isCurrentUser
                                        ? Radius.circular(0)
                                        : Radius.circular(28),
                                    bottomLeft: Radius.circular(28),
                                    bottomRight: isCurrentUser
                                        ? Radius.circular(28)
                                        : Radius.circular(0),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 23, vertical: 23),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Text(
                                  messageText,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 17),
                                ),
                              ),
                            ),
                            title: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Text(senderFullName),
                            ),
                          );
                        },
                      );
                    } else if (messageType == 'image') {
                      final isCurrentUser = messageFrom ==
                          FirebaseAuth.instance.currentUser!.email;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('email', isEqualTo: messageFrom)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox.shrink();
                          }

                          final userData = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final senderFullName =
                              '${userData['firstname']} ${userData['secondname']}';

                          return ListTile(
                            subtitle: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                child: Image.network(
                                  imageUrl,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Text(senderFullName),
                            ),
                          );
                        },
                      );
                    }

                    return SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration:
                        InputDecoration(labelText: 'Type your message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () async {
                    final pickedImage = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );

                    if (pickedImage != null) {
                      final imageFile = File(pickedImage.path);
                      final storageRef = FirebaseStorage.instance
                          .ref()
                          .child('group_images')
                          .child('${DateTime.now()}.jpg');
                      final uploadTask = storageRef.putFile(imageFile);

                      final imageUrl =
                          await (await uploadTask).ref.getDownloadURL();

                      sendImage(imageUrl);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




///////////////////////////////////////////////////////////////////////////////////////////////////
