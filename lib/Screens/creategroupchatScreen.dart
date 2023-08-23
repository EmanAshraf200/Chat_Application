import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scholar_chat/Screens/groupchatscreen.dart';

class CreateGroupChatScreen extends StatefulWidget {
  @override
  _CreateGroupChatScreenState createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  List<String> selectedParticipants = [];
  TextEditingController groupNameController = TextEditingController();

  void createGroupChat() async {
    if (selectedParticipants.isNotEmpty) {
      final groupId = generateGroupId(selectedParticipants);
      final currentTime = Timestamp.now();

      await FirebaseFirestore.instance.collection('Groups').doc(groupId).set({
        'participants': selectedParticipants,
        'groupName': groupNameController.text,
        'lastMessage': '',
        'timestamp': currentTime,
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('successfully'),
            content: Text('successfully your group is created'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      // Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please select participants for the group chat.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
            "assets/images/3d-smartphone-function-icon-illustration-png.webp",
            height: 70,
          ),
          Text('Create Group Chat'),
        ]),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Select Participants'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () async {
              List<String> selected = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectParticipantsScreen(
                    initialParticipants: selectedParticipants,
                  ),
                ),
              );
              if (selected != null) {
                setState(() {
                  selectedParticipants = selected;
                });
              }
            },
          ),
          selectedParticipants.isEmpty
              ? Container()
              : Column(
                  children: selectedParticipants
                      .map(
                        (participant) => ListTile(
                          title: Text(participant),
                          trailing: IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                selectedParticipants.remove(participant);
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: TextField(
              controller: groupNameController,
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              width: 300,
              height: 45,
              child: ElevatedButton(
                onPressed: createGroupChat,
                child: Text('Create Group Chat'),
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(255, 96, 62, 191),
                  // Colors.white,
                  onPrimary: Colors.white,
                  textStyle: TextStyle(fontSize: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectParticipantsScreen extends StatefulWidget {
  final List<String> initialParticipants; // New parameter

  SelectParticipantsScreen({required this.initialParticipants});

  @override
  _SelectParticipantsScreenState createState() =>
      _SelectParticipantsScreenState(initialParticipants: initialParticipants);
}

class _SelectParticipantsScreenState extends State<SelectParticipantsScreen> {
  List<String> participants = [];

  _SelectParticipantsScreenState({required List<String> initialParticipants}) {
    participants.addAll(initialParticipants); // Initialize participants list
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
            "assets/images/3d-smartphone-function-icon-illustration-png.webp",
            height: 70,
          ),
          Text('Select Participants')
        ]),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, participants);
            },
            child: Text('Done'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          List<String> existingParticipants = participants;

          List<QueryDocumentSnapshot> userDocs = snapshot.data!.docs;
          List<String> userList =
              userDocs.map((userDoc) => userDoc['email'] as String).toList();

          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              String user = userList[index];
              bool isSelected = existingParticipants.contains(user);

              return ListTile(
                title: Text(user),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (isSelected) {
                        existingParticipants.remove(user);
                      } else {
                        existingParticipants.add(user);
                      }
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String generateGroupId(List<String> participants) {
  participants.sort();
  return participants.join('_');
}










////////////////////////////////////////////////////////////////////////

