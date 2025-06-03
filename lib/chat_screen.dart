import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final String? doctorId;
  final String? doctorName;
  final String? patientId;
  final String? patientName;

  ChatScreen({
    this.doctorId,
    this.doctorName,
    this.patientId,
    this.patientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _chatListDatabase =
  FirebaseDatabase.instance.ref().child('ChatList');
  final DatabaseReference _chatDatabase =
  FirebaseDatabase.instance.ref().child('Chat');
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserId;

  bool get isDoctor => _currentUserId == widget.doctorId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      String message = _messageController.text.trim();
      String chatId = _chatDatabase.push().key!;
      String timeStamp = DateTime.now().toIso8601String();

      String senderUid;
      String receiverUid;

      if (isDoctor) {
        senderUid = _currentUserId!;
        receiverUid = widget.patientId!;
      } else {
        senderUid = _currentUserId!;
        receiverUid = widget.doctorId!;
      }

      _chatDatabase.child(chatId).set({
        'message': message,
        'receiver': receiverUid,
        'sender': senderUid,
        'timestamp': timeStamp,
      });

      _chatListDatabase.child(senderUid).child(receiverUid).set({
        'id': receiverUid,
      });

      _chatListDatabase.child(receiverUid).child(senderUid).set({
        'id': senderUid,
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? chatPartnerName = isDoctor ? widget.patientName : widget.doctorName;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF6F35A5).withOpacity(0.2),
              child: Icon(
                isDoctor ? Icons.person : Icons.medical_services,
                color: Color(0xFF6F35A5),
              ),
            ),
            SizedBox(width: 12),
            Text(
              chatPartnerName ?? 'Chat',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/chat_bg.png'), // Add your own subtle pattern
                  fit: BoxFit.cover,
                  opacity: 0.05,
                ),
              ),
              child: StreamBuilder(
                stream: _chatDatabase.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start the conversation',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  Map<dynamic, dynamic> messagesMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Map<String, dynamic>> messagesList = [];

                  messagesMap.forEach((key, value) {
                    if ((value['sender'] == _currentUserId &&
                        value['receiver'] == widget.doctorId) ||
                        (value['sender'] == widget.doctorId &&
                            value['receiver'] == _currentUserId) ||
                        (value['sender'] == _currentUserId &&
                            value['receiver'] == widget.patientId) ||
                        (value['sender'] == widget.patientId &&
                            value['receiver'] == _currentUserId)) {
                      messagesList.add({
                        'message': value['message'],
                        'sender': value['sender'],
                        'timestamp': value['timestamp'],
                      });
                    }
                  });
                  messagesList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    reverse: false,
                    itemCount: messagesList.length,
                    itemBuilder: (context, index) {
                      bool isMe = messagesList[index]['sender'] == _currentUserId;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe)
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFF6F35A5).withOpacity(0.2),
                                child: Icon(
                                  isDoctor ? Icons.person : Icons.medical_services,
                                  size: 14,
                                  color: Color(0xFF6F35A5),
                                ),
                              ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Color(0xFF6F35A5)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: isMe
                                        ? Radius.circular(18)
                                        : Radius.circular(4),
                                    bottomRight: isMe
                                        ? Radius.circular(4)
                                        : Radius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  messagesList[index]['message'],
                                  style: GoogleFonts.poppins(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        hintText: 'Type your message...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.emoji_emotions_outlined,
                              color: Colors.grey[600]),
                          onPressed: () {
                            // Add emoji picker functionality
                          },
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      maxLines: null,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6F35A5),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}