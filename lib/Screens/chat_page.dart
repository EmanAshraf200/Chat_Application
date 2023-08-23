import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Chat_Page extends StatefulWidget {
  const Chat_Page({Key? key}) : super(key: key);

  @override
  State<Chat_Page> createState() => _Chat_PageState();
}

class _Chat_PageState extends State<Chat_Page> {
  final ScrollController _scrollController = ScrollController();
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference message =
      FirebaseFirestore.instance.collection('Messages');
  CollectionReference chats = FirebaseFirestore.instance.collection('chats');
  TextEditingController controller = TextEditingController();
  bool otherUserIsTyping = false;
  bool isTyping = false;
  void startListeningToTyping() {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    String currentUserEmail = args['currentUserEmail'] ?? '';
    String otherUserEmail = args['otherUserEmail'] ?? '';

    users
        .where('email', isEqualTo: otherUserEmail)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final otherUserDoc = snapshot.docs.first;
        final data = otherUserDoc.data() as Map<String, dynamic>;
        final isTyping =
            data.containsKey('isTyping') ? data['isTyping'] : false;

        setState(() {
          otherUserIsTyping = isTyping;
        });
      }
    });
  }

  void startTyping() {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    String currentUserEmail = args['currentUserEmail'] ?? '';
    print('Updating typing status for user: $currentUserEmail');

    users.where('email', isEqualTo: currentUserEmail).get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final currentUserDoc = snapshot.docs.first;
        currentUserDoc.reference.update({'isTyping': true}).then((_) {
          print('Typing status updated successfully.');
        }).catchError((error) {
          print('Error updating typing status: $error');
        });
      }
    });
  }

  void stopTyping() {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    String currentUserEmail = args['currentUserEmail'] ?? '';
    users.where('email', isEqualTo: currentUserEmail).get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final currentUserDoc = snapshot.docs.first;
        currentUserDoc.reference.update({'isTyping': false});
      }
    });
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      startListeningToTyping();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    String? otherUserName = args['otherUserName'];
    String? otherUserImageUrl = args['otherUserImageUrl'];
    String currentUserEmail = args['currentUserEmail'] ?? '';
    String otherUserEmail = args['otherUserEmail'] ?? '';

    String chatId = generateChatId(currentUserEmail, otherUserEmail);
    final sequenceNumber = DateTime.now().microsecondsSinceEpoch;

    return StreamBuilder<QuerySnapshot>(
      stream: message
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdtime', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
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
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(otherUserImageUrl!),
                  ),
                  SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserName!,
                        style: TextStyle(fontSize: 16),
                      ),
                      if (otherUserIsTyping)
                        Text('Typing...', style: TextStyle(fontSize: 12)),
                      StreamBuilder<QuerySnapshot>(
                        stream: users
                            .where('email', isEqualTo: otherUserEmail)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return SizedBox.shrink();
                          }
                          final userData = snapshot.data!.docs[0].data()
                              as Map<String, dynamic>;
                          final isOnline = userData['isOnline'] ?? false;
                          return Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                                fontSize: 12,
                                color: isOnline ? Colors.green : Colors.grey),
                          );
                        },
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
                  child: ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final messageData =
                          documents[index].data() as Map<String, dynamic>;

                      final messageText = messageData!['Message'];

                      final messageType = messageData['messageType'];
                      final imageUrl = messageData['imageUrl'];
                      if (messageType == 'text') {
                        return messageData!['sender'] == currentUserEmail
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Color.fromARGB(255, 96, 62, 191),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(28),
                                          topRight: Radius.circular(28),
                                          bottomRight: Radius.circular(28),
                                        )),
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
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 165, 153, 200),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(28),
                                          topRight: Radius.circular(28),
                                          bottomLeft: Radius.circular(28),
                                        )),
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
                                ],
                              );
                      } else if (messageType == 'image') {
                        return messageData['sender'] == currentUserEmail
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Image.network(
                                      imageUrl,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    child: Image.network(
                                      imageUrl,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              );
                      }
                      return SizedBox.shrink();
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
                        child: Padding(
                          padding: const EdgeInsets.all(23),
                          child: TextField(
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                startTyping();
                              } else {
                                stopTyping();
                              }
                            },
                            controller: controller,
                            onSubmitted: (value) {
                              message.add({
                                'Message': value,
                                'createdtime':
                                    Timestamp.fromMicrosecondsSinceEpoch(
                                        sequenceNumber),
                                'sender': currentUserEmail,
                                'chatId': chatId,
                                'messageType': 'text',
                              });
                              chats.doc(chatId).set({
                                'first_Email': currentUserEmail,
                                'second_Email': otherUserEmail,
                                'lastMessage': value,
                                'timestamp':
                                    Timestamp.fromMicrosecondsSinceEpoch(
                                        sequenceNumber),
                              }, SetOptions(merge: true));
                              controller.clear();
                              _scrollController.animateTo(
                                0,
                                duration: Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              );
                              stopTyping();
                            },
                            decoration: InputDecoration.collapsed(
                                hintText: "Type your message..."),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          message.add({
                            'Message': controller.text,
                            'createdtime': Timestamp.fromMicrosecondsSinceEpoch(
                                sequenceNumber),
                            'sender': currentUserEmail,
                            'chatId': chatId,
                            'messageType': 'text',
                          });
                          chats.doc(chatId).set({
                            'first_Email': currentUserEmail,
                            'second_Email': otherUserEmail,
                            'lastMessage': controller.text,
                            'timestamp': Timestamp.fromMicrosecondsSinceEpoch(
                                sequenceNumber),
                          }, SetOptions(merge: true));
                          controller.clear();
                          _scrollController.animateTo(
                            0,
                            duration: Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                          );
                          stopTyping();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.image),
                        onPressed: () async {
                          final pickedImage = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);

                          if (pickedImage != null) {
                            final imageFile = File(pickedImage.path);
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child('images')
                                .child(chatId)
                                .child('${DateTime.now()}.jpg');
                            final uploadTask = storageRef.putFile(imageFile);

                            final imageUrl =
                                await (await uploadTask).ref.getDownloadURL();

                            message.add({
                              'sender': currentUserEmail,
                              'chatId': chatId,
                              'messageType': 'image',
                              'imageUrl': imageUrl,
                              'createdtime':
                                  Timestamp.fromMicrosecondsSinceEpoch(
                                      sequenceNumber),
                            });
                            chats.doc(chatId).set({
                              'first_Email': currentUserEmail,
                              'second_Email': otherUserEmail,
                              'lastMessage': "image",
                              'timestamp': Timestamp.fromMicrosecondsSinceEpoch(
                                  sequenceNumber),
                            }, SetOptions(merge: true));

                            _scrollController.animateTo(
                              0,
                              duration: Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ));
      },
    );
  }
}

////////////////////////////////
String generateChatId(String email1, String email2) {
  List<String> emails = [email1, email2]..sort();
  return emails.join('_');
}
