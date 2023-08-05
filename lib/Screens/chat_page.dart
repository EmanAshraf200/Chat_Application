import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat_Page extends StatefulWidget {
  const Chat_Page({Key? key}) : super(key: key);

  @override
  State<Chat_Page> createState() => _Chat_PageState();
}

class _Chat_PageState extends State<Chat_Page> {
  final ScrollController _scrollController = ScrollController();
  CollectionReference message =
      FirebaseFirestore.instance.collection('Messages');
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    String? otherUserName = args['otherUserName'];
    String? otherUserImageUrl = args['otherUserImageUrl'];
    String currentUserEmail = args['currentUserEmail'] ?? '';
    String otherUserEmail = args['otherUserEmail'] ?? '';

    String chatId = generateChatId(currentUserEmail, otherUserEmail);
    Timestamp currentTime = Timestamp.now();
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
                    ], // Replace with your desired gradient colors
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
                      return messageData!['messageFrom'] == currentUserEmail
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
                                      color: Color.fromARGB(255, 165, 153, 200),
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
                            controller: controller,
                            onSubmitted: (value) {
                              message.add({
                                'Message': value,
                                'createdtime': currentTime,
                                'messageFrom': currentUserEmail,
                                'messageTo': otherUserEmail,
                                'chatId': chatId
                              });
                              controller.clear();
                              _scrollController.animateTo(
                                0,
                                duration: Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              );
                            },
                            decoration: InputDecoration.collapsed(
                                hintText: "Type your message..."),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {},
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
