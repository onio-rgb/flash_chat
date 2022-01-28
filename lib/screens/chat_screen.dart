import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late User logginUser;
  late String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        logginUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  // void getMessages() async {
  //   final response = await _firestore.collection('messages').get();
  //   final messages = response.docs;
  //   for (var m in messages) {
  //     print(m.data());
  //   }
  // }
  void messageStream() async {
    await for (var messages in _firestore.collection('messages').snapshots()) {
      for (var message in messages.docs) {
        print(message.data());
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('time', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  String currentChatMember = "-";
                  int i = 0;
                  final messages = snapshot.data!.docs;
                  List<MessageBubble> messagewidgets = [];
                  for (var message in messages) {
                    final text = message.data()['text'];
                    String sender = message.data()['sender'];
                    final messageWidget;
                    print("$i No $currentChatMember vs $sender");
                    if (sender == logginUser.email) {
                      messageWidget = MessageBubble(
                        sender: sender,
                        text: text,
                        color: Colors.blue,
                        align: CrossAxisAlignment.end,
                        radius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30)),
                        showSender: false,
                      );
                    } else {
                      messageWidget = MessageBubble(
                        sender: sender,
                        text: text,
                        color: Colors.white,
                        align: CrossAxisAlignment.start,
                        radius: BorderRadius.only(
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30)),
                        showSender:
                            (currentChatMember == sender) ? (false) : (true),
                        //true,
                      );
                    }

                    messagewidgets.add(messageWidget);
                    currentChatMember = "$sender";
                    i = i + 1;
                  }
                  currentChatMember = "-";
                  return Expanded(
                    child: ListView(
                      reverse: true,
                      children: messagewidgets.reversed.toList(),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      controller: controller,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      controller.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': logginUser.email,
                        'time': Timestamp.now()
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  String? sender;
  String text;
  CrossAxisAlignment align;
  Color color;
  BorderRadius radius;
  bool showSender;

  MessageBubble(
      {this.sender,
      required this.text,
      required this.color,
      required this.align,
      required this.radius,
      required this.showSender});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        (showSender) ? (Text(sender!)) : (Container()),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            borderRadius: radius,
            color: color,
            elevation: 7.0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  text,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
