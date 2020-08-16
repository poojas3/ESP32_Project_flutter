import 'package:esp32_project_flutter_app/screens/login_screen.dart';
import 'package:esp32_project_flutter_app/screens/ml_label.dart';
import 'package:flutter/material.dart';
import 'package:esp32_project_flutter_app/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esp32_project_flutter_app/components/CircleProgress.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:esp32_project_flutter_app/ult.dart';
import 'dart:async';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:core';
import 'ml_home.dart';
import 'package:esp32_project_flutter_app/getname.dart';

//import 'package:flutter_audio_player/flutter_audio_player.dart';
typedef void OnError(Exception exception);
//final _firestore = Firestore.instance;
FirebaseUser loggedInUser;
DatabaseReference _distRef =
    FirebaseDatabase.instance.reference().child('ESP32_Device');

class UltraScreen extends StatefulWidget {
  static const String id = 'ultrasonic_screen';

  @override
  _UltraScreenState createState() => _UltraScreenState();
}

class _UltraScreenState extends State<UltraScreen>
    with SingleTickerProviderStateMixin {
  final messageTextController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterTts flutterTts = FlutterTts();

  String messageText;

  bool isLoading = false;
  AnimationController progressController;
  Animation<double> distanceAnimation;
  String distWarnText;
  Timer _timer;
  String _distAudioName;
  Duration _duration = new Duration();
  Duration _position = new Duration();
  AudioPlayer advancedPlayer;
  AudioCache audioCache;
  int _count = 0;
  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "try";
  double _confidence = 1.0;
  bool _mute = false;
  double _oldreading = 0;
  bool _check = false;
  String personname;
  String oldname;
  int speaknametimes = 0;

  @override
  void initState() {
    distWarnText = "Distance remind soon...";
    //_distAudioName = 'audios/4m.m4a';
    _speech = stt.SpeechToText();
    initPlayer();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      setState(() {
        print("speak:$_distAudioName");
        print(_count.toString());
        //_listen();
        //print('first: $_text');
        //print(_text);
        if (!_mute) {
          print(_mute.toString());
          _speak(_distAudioName);
          if (personname != "") {
            if (oldname != personname && speaknametimes < 5) {
              _speak("Hello $personname");
              oldname = personname;
              speaknametimes++;
            } else if (speaknametimes > 5) {
              speaknametimes = 0;
            }
          }
        }
        //audioCache.play(_distAudioName);
      });
    });
    super.initState();

    isLoading = true;
    getCurrentUser();
  }

  void initPlayer() {
    advancedPlayer = new AudioPlayer();
    audioCache = new AudioCache(fixedPlayer: advancedPlayer);

    advancedPlayer.durationHandler = (d) => setState(() {
          _duration = d;
        });

    advancedPlayer.positionHandler = (p) => setState(() {
          _position = p;
        });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

//  void getDistance() async {
//    double distances = await _firestore.collection('distance').snapshots();
//  }

//
//  void messagesStream() async {
//    await for (var snapshot in _firestore.collection('messages').snapshots()) {
//      for (var message in snapshot.documents) {
//        print(message.data);
//      }
//    }
//  }
  _UltraScreenInit(double distance) {
    progressController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 5000)); //5s
    print('distance');
    distanceAnimation =
        Tween<double>(begin: 0.0, end: distance).animate(progressController)
          ..addListener(() {
            print('distance1');
            setState(() {});
          });

    progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Text('⚡️Visual Aid'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(
                    height: 30,
                    //child: _buildAudioPlay(),
                  ),
                  Expanded(
                    child: StreamBuilder(
                      stream: _distRef.onValue,
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            !snapshot.hasError &&
                            snapshot.data.snapshot.value != null) {
                          print(
                              "snapshot data:${snapshot.data.snapshot.value.toString()}");

                          var _dist = ULT.fromJson(
                              snapshot.data.snapshot.value['Distance']);
                          print("Distance: ${_dist.data}");
                          var person = CAM.fromJson(
                              snapshot.data.snapshot.value['MatchPerson']);
                          personname = person.data;
                          if ((_dist.data - _oldreading).abs() >= 0.5) {
                            _oldreading = _dist.data;
                            _mute = false;
                          }
                          _setAudioName(_dist);
                          //print(_distAudioName);
                          //_buildAudioPlay();
                          //_listen();
                          //print(_text);
                          return _distanceLayout(_dist);
                        } else {
                          return Center(
                            child: Text("No data yet"),
                          );
                        }
                      },
                    ),
                  ),
                  Text(
                    personname == null ? "None" : personname,
                    style: kPersonnameDecoration,
                  ),
                ],
              )
            : Text(
                'Loading...',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _distanceLayout(ULT _ult) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              "Distance",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CustomPaint(
                foregroundPainter: CircleProgress(_ult.data, true),
                child: Container(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Distance'),
                        Text(
                          '${_ult.data.toStringAsFixed(3)}',
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'cm',
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.only(top: 40, left: 5, bottom: 5),
                  child: FloatingActionButton(
                    heroTag: 'Check',
                    onPressed: () {
                      Navigator.pushNamed(context, MLHome.id);
                      /*setState(() {
                        _check = !_check;
                      });*/
                    },
                    tooltip: 'Check',
                    child: Icon(MaterialCommunityIcons.check),
                    backgroundColor:
                        _check ? Colors.amber : Colors.lightBlueAccent,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding:
                        const EdgeInsets.only(top: 40, right: 5, bottom: 5),
                    child: FloatingActionButton(
                      heroTag: 'Mute',
                      onPressed: () {
                        setState(() {
                          _mute = !_mute;
                        });
                      },
                      tooltip: 'Mute',
                      child: Icon(MaterialCommunityIcons.volume_mute),
                      backgroundColor:
                          _mute ? Colors.amber : Colors.lightBlueAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _setAudioName(ULT _ult) async {
    if (_ult.data > 300.0 && _ult.data < 400.0) {
      _distAudioName = "4m range, tap bottom right button to mute";
      //_distAudioName = '4mr.mp3';
    } else if (_ult.data >= 200.0 && _ult.data <= 300.0) {
      _distAudioName = "3m range, tap bottom right button to mute";
      //_distAudioName = '3mr.mp3';
    } else if (_ult.data >= 100.0 && _ult.data < 200.0) {
      _distAudioName = "2m range, tap bottom right button to mute";
      //_distAudioName = '2mr.mp3';
    } else if (_ult.data > 0.0 && _ult.data < 100.0) {
      _distAudioName = "1m range, tap bottom right button to mute";
      //_distAudioName = '1mr.mp3';
    } else {
      _distAudioName = "unknown, tap bottom right button to mute";
    }
    //await audioCache.play(_distAudioName);
  }

  Future _speak(String wordtosay) async {
    await flutterTts.speak(wordtosay);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
    }
  }

//  Future<dynamic> _buildAudioPlay() async {
//    print(_distAudioName);
//    return AudioPlayer.addSound(_distAudioName);
//  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});

  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0)),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
