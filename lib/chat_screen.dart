import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import './chat_message.dart';
import './text_composer.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  FirebaseUser _currentuser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        _currentuser = user;
      });
    });
  }

  Future<FirebaseUser> _getUser() async {
    if (_currentuser != null) return _currentuser;

    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final FirebaseUser user = authResult.user;

      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMessage({String text, File imgFile}) async {
    final FirebaseUser user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: const Text('Não foi possível fazer o login. Tente novamente'),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      "uid": user.uid,
      "senderName": user.displayName,
      "senderPhoto": user.photoUrl,
      'time': Timestamp.now(),
    };

    if (imgFile != null) {
      StorageUploadTask task = FirebaseStorage.instance
          .ref()
          .child('imgChat')
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imgFile);

          setState(() {
            _isLoading = true;
          });

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
      setState(() {
        _isLoading = false;
      });
    }

    if (text != null) {
      data['text'] = text;
    }

    Firestore.instance.collection('mensagens').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentuser != null
            ? 'Olá. ${_currentuser.displayName}'
            : 'Chat App'),
        elevation: 0,
        actions: <Widget>[
          _currentuser != null
              ? IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    _scaffoldKey.currentState.showSnackBar(SnackBar(
                      content: const Text('Você saiu!'),
                    ));
                  },
                )
              : Container(),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection('mensagens').orderBy('time').snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data.documents.reversed.toList();
                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        return ChatMessage(documents[index].data,
                        documents[index].data['uid'] == _currentuser?.uid
                        );
                      },
                    );
                }
              },
            ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
