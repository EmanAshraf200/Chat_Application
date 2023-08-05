import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class User {
  final String firstName;
  final String secondName;
  final String imageUrl;
  final String email;

  User(
      {required this.firstName,
      required this.secondName,
      required this.imageUrl,
      required this.email});
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Stream<QuerySnapshot> usersStream =
      FirebaseFirestore.instance.collection('users').snapshots();
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserEmail();
  }

  void fetchCurrentUserEmail() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        setState(() {
          currentUserEmail = user.email;
        });
      }
    });
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
                const Color.fromARGB(255, 96, 62, 191)
              ],
            ),
          ),
        ),
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(
            'assets/images/scholar.png',
            height: 50,
          ),
          Text('Chat')
        ]),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          List<User> users = snapshot.data!.docs.map((doc) {
            return User(
                firstName: doc['firstname'],
                secondName: doc['secondname'],
                imageUrl: doc['imageurl'],
                email: doc['email']);
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              User user = users[index];
              if (user.email == currentUserEmail) {
                return SizedBox.shrink();
              }

              Stream<QuerySnapshot> lastMessageStream = FirebaseFirestore
                  .instance
                  .collection('Messages')
                  .where('chatId',
                      isEqualTo: generateChatId(currentUserEmail!, user.email))
                  .orderBy('createdtime', descending: true)
                  .limit(1)
                  .snapshots();

              return StreamBuilder<QuerySnapshot>(
                stream: lastMessageStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user.imageUrl),
                          ),
                          title: Text("${user.firstName} ${user.secondName}"),
                          subtitle: Text('Loading...'),
                          onTap: () {
                            Navigator.pushNamed(context, 'chat', arguments: {
                              'currentUserEmail': currentUserEmail,
                              'otherUserEmail': user.email,
                              'otherUserName':
                                  "${user.firstName} ${user.secondName}",
                              'otherUserImageUrl': user.imageUrl,
                            });
                            print("${user.email} ${currentUserEmail}");
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

                  // Get the last message document
                  QueryDocumentSnapshot? lastMessageDoc =
                      snapshot.data!.docs.isNotEmpty
                          ? snapshot.data!.docs.first
                          : null;

                  String lastMessageText = lastMessageDoc != null
                      ? lastMessageDoc['Message']
                      : 'No messages yet';

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.imageUrl),
                        ),
                        title: Text("${user.firstName} ${user.secondName}"),
                        subtitle: Text(lastMessageText),
                        onTap: () {
                          Navigator.pushNamed(context, 'chat', arguments: {
                            'currentUserEmail': currentUserEmail,
                            'otherUserEmail': user.email,
                            'otherUserName':
                                "${user.firstName} ${user.secondName}",
                            'otherUserImageUrl': user.imageUrl,
                          });
                          print("${user.email} ${currentUserEmail}");
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
                },
              );
            },
          );
        },
      ),
    );
  }
}

String generateChatId(String email1, String email2) {
  List<String> emails = [email1, email2]..sort();
  return emails.join('_');
}
