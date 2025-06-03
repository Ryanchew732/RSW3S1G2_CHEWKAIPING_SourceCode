import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing/chat_screen.dart';

import '../doctor/model/doctor.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _chatListDatabase = FirebaseDatabase.instance.ref().child('ChatList');
  final DatabaseReference _doctorDatabase = FirebaseDatabase.instance.ref().child('Doctors');
  List<Doctor> _chatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatList();
  }

  Future<void> _fetchChatList() async {
    String? userId = _auth.currentUser?.uid;
    if(userId != null){
      try{
        final DatabaseEvent event = await _chatListDatabase.once();
        DataSnapshot snapshot = event.snapshot;
        List<Doctor> tempChatList = [];

        if(snapshot.value != null){
          Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
          for( var doctorId in values.keys){
            Map<dynamic, dynamic> userChats = values[doctorId];
            if(userChats.containsKey(userId)){
              final DatabaseEvent doctorEvent = await _doctorDatabase.child(doctorId).once();
              DataSnapshot doctorSnapshot = doctorEvent.snapshot;
              if(doctorSnapshot.value != null){
                Doctor doctor = Doctor.fromMap(doctorSnapshot.value as Map<dynamic, dynamic>, doctorId);
                tempChatList.add(doctor);
              }
            }
          }
        }
        setState(() {
          _chatList = tempChatList;
          _isLoading = false;
        });

      }catch (error) {
        // error message
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Doctors',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F35A5)),
        ),
      )
          : _chatList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No doctors available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 16),
        itemCount: _chatList.length,
        separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          Doctor doctor = _chatList[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF6F35A5).withOpacity(0.2),
              child: Icon(
                Icons.medical_services,
                size: 30,
                color: Color(0xFF6F35A5),
              ),
            ),
            title: Text(
              'Dr. ${doctor.firstName} ${doctor.lastName}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Specialty: ${doctor.specialty ?? 'General'}',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    doctorId: doctor.uid,
                    doctorName: 'Dr. ${doctor.firstName} ${doctor.lastName}',
                    patientId: _auth.currentUser!.uid,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}