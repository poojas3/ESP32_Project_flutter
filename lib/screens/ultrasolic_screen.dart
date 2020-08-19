import 'package:flutter/material.dart';
import 'package:esp32_project_flutter_app/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:url_launcher/url_launcher.dart';

typedef void OnError(Exception exception);
//planned to let user log in and register, but to reduce the operation, allow anonymous login
FirebaseUser loggedInUser;
//fetch data from Firebase realtime database
DatabaseReference _distRef =
    FirebaseDatabase.instance.reference().child('ESP32_Device');

class UltraScreen extends StatefulWidget {
  static const String id = 'ultrasonic_screen';

  @override
  _UltraScreenState createState() => _UltraScreenState();
}

class _UltraScreenState extends State<UltraScreen>
    with SingleTickerProviderStateMixin {
  //firebase autorization
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //text to speech
  final FlutterTts flutterTts = FlutterTts();

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
  String _text;
  double _confidence = 1.0;
  bool _mute = true;
  double _oldreading = 0;
  bool _check = false;
//camera enable
  bool camen = false;

  String personname;
  String oldname;
  int speaknametimes = 0;
  String olddistance;
  int speakdistimes = 0;

  @override
  void initState() {
    distWarnText = "Distance remind soon...";
    _speech = stt.SpeechToText();
    initPlayer();
    _speak(
        "tap bottom right button to enable distance detection, tap bottom left button to enable camera");
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        print("speak:$_distAudioName");
        print(_count.toString());
        print("speaktimes: $speaknametimes \npersonname:$personname");
        //if mutted, no voice message, else if distance changed then send voice message for five times
        if (!_mute) {
          print(_mute.toString());
          if (_distAudioName != "") {
            if (olddistance != _distAudioName) {
              olddistance = _distAudioName;
              speakdistimes = 0;
            }
            if (speakdistimes < 3) {
              _speak(_distAudioName);
              speakdistimes++;
            }
          }
          print("personname: $personname");
          //if there is no person, no voice message, else if there's a person then send voice message for five times
          if (personname != "" && personname != "None" && personname != null) {
            if (oldname != personname) {
              oldname = personname;
              speaknametimes = 0;
            }
            if (speaknametimes < 3) {
              _speak("Hello $personname");
              speaknametimes++;
            }
          }
        }
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
                          //get distance data from Firebase and parse Json data
                          var _dist = ULT.fromJson(
                              snapshot.data.snapshot.value['Distance']);
                          print("Distance: ${_dist.data}");
                          print(
                              "matper:${snapshot.data.snapshot.value['MatchPerson']}");
                          //get the person name in front of the camera
                          if (snapshot.data.snapshot.value['MatchPerson'] !=
                              null) {
                            var person = CAM.fromJson(
                                snapshot.data.snapshot.value['MatchPerson']);
                            personname = person.data;
                          } else {
                            personname = "";
                          }

                          //send voice message if the distance change more than ten
                          if ((_dist.data - _oldreading).abs() >= 10) {
                            _oldreading = _dist.data;
                          }
                          _setAudioName(_dist);
                          //sen voice message if the person appear in front ofthe camera
                          if (personname != "" &&
                              personname != "None" &&
                              personname != null &&
                              speaknametimes >= 3) {
                            oldname = "";
                            personname = "";
                            speaknametimes = 0;
                            _distRef.child('MatchPerson').remove();
                          }

//                          if (_text == "Help") {
//                            launch("tel:+16399988658");
//                          }
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
                    personname == null ? "" : personname,
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

  //display distance with animation
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
                      onCameraenable();
                      Navigator.pushNamed(context, MLHome.id);
                    },
                    tooltip: 'Check',
                    child: Icon(MaterialCommunityIcons.camera),
                    backgroundColor:
                        camen ? Colors.amber : Colors.lightBlueAccent,
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
                      child: Icon(MaterialCommunityIcons.ruler),
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

  //check the distance range to send different voice message
  _setAudioName(ULT _ult) async {
    if (_ult.data > 300.0 && _ult.data < 400.0) {
      _distAudioName = "4m range, tap bottom right button to mute";
    } else if (_ult.data >= 200.0 && _ult.data <= 300.0) {
      _distAudioName = "3m range, tap bottom right button to mute";
    } else if (_ult.data >= 100.0 && _ult.data < 200.0) {
      _distAudioName = "2m range, tap bottom right button to mute";
    } else if (_ult.data > 0.0 && _ult.data < 100.0) {
      _distAudioName = "1m range, tap bottom right button to mute";
    } else {
      _distAudioName = "unknown, tap bottom right button to mute";
    }
  }

  //convert text to speech
  Future _speak(String wordtosay) async {
    await flutterTts.speak(wordtosay);
  }

  //for future convert speech to text
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

  //camera enable
  void onCameraenable() {
    setState(() {
      camen = !camen;
    });

    _distRef.child("camen").set({
      'camen': camen,
    });
  }
}
