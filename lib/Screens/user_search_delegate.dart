import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class User {
  final String firstName;
  final String secondName;
  final String imageUrl;
  final String email;

  User({
    required this.firstName,
    required this.secondName,
    required this.imageUrl,
    required this.email,
  });
}

class UserSearchDelegate extends SearchDelegate<User> {
  final String currentUserEmail;

  UserSearchDelegate(this.currentUserEmail);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text('Enter a search term'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('user_name', isGreaterThanOrEqualTo: query)
          .where('user_name', isLessThan: query + 'z')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        List<User> searchResults = snapshot.data!.docs.map((doc) {
          return User(
            firstName: doc['firstname'],
            secondName: doc['secondname'],
            imageUrl: doc['imageurl'],
            email: doc['email'],
          );
        }).toList();
        if (searchResults.isEmpty) {
          return Center(
            child: Text('No user found'),
          );
        }

        return ListView.builder(
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            User user = searchResults[index];

            Stream<DocumentSnapshot> chatStream = FirebaseFirestore.instance
                .collection('chats')
                .doc(generateChatId(currentUserEmail, user.email))
                .snapshots();

            return StreamBuilder<DocumentSnapshot>(
              stream: chatStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                DocumentSnapshot? chatDoc = snapshot.data;
                String lastMessageText = chatDoc?.exists == true
                    ? chatDoc!['lastMessage']
                    : 'No messages yet';
                Timestamp? lastMessageTimestamp =
                    chatDoc?.exists == true ? chatDoc!['timestamp'] : null;

                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.imageUrl),
                      ),
                      title: Text("${user.firstName} ${user.secondName}"),
                      subtitle: Text(lastMessageText),
                      trailing: Text(
                        lastMessageTimestamp != null
                            ? _formatTimestamp(lastMessageTimestamp)
                            : '',
                      ),
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
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}

String _formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  String formattedDate = DateFormat('HH:mm').format(dateTime);
  return formattedDate;
}

String generateChatId(String email1, String email2) {
  List<String> emails = [email1, email2]..sort();
  return emails.join('_');
}
