import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing/chat_screen.dart';
import 'package:testing/doctor/model/patient.dart';

class DoctorChatlistPage extends StatefulWidget {
  const DoctorChatlistPage({super.key});

  @override
  State<DoctorChatlistPage> createState() => _DoctorChatlistPageState();
}

class _DoctorChatlistPageState extends State<DoctorChatlistPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _chatListDatabase = FirebaseDatabase.instance.ref().child('ChatList');
  final DatabaseReference _patientsDatabase = FirebaseDatabase.instance.ref().child('Patients');
  List<Patient> _chatList = [];
  bool _isLoading =  true;
  late String doctorId;

  @override
  void initState() {
    super.initState();
    doctorId = _auth.currentUser?.uid ?? '';
    _fetchChatList();
  }

  Future<void> _fetchChatList() async {
    if(doctorId.isNotEmpty){
      try{
        final DatabaseEvent event = await _chatListDatabase.child(doctorId).once();
        DataSnapshot snapshot = event.snapshot;
        List<Patient> tempChatList = [];

        if(snapshot.value != null){
          Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

          for( var userId in values.keys){
            final DatabaseEvent patientEvent = await _patientsDatabase.child(userId).once();
            DataSnapshot patientSnapshot = patientEvent.snapshot;
            if(patientSnapshot.value != null){
              Map<dynamic, dynamic> patientMap = patientSnapshot.value as Map<dynamic, dynamic>;
              tempChatList.add(Patient.fromMap(Map<String, dynamic>.from(patientMap)));
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
          'Your Conversations',
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
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
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
          final patient = _chatList[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF6F35A5).withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 30,
                color: Color(0xFF6F35A5),
              ),
            ),
            title: Text(
              '${patient.firstName} ${patient.lastName}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Tap to chat',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    doctorId: doctorId,
                    patientId: patient.uid,
                    patientName: '${patient.firstName} ${patient.lastName}',
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