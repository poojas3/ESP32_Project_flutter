import 'package:flutter/material.dart';
import 'package:esp32_project_flutter_app/constants.dart';
import 'package:firebase_database/firebase_database.dart';

DatabaseReference _dataRef =
FirebaseDatabase.instance.reference().child('ESP32_Device');

class Vision extends StatefulWidget {
  @override
  _VisionState createState() => _VisionState();
}

class _VisionState extends State<Vision> {
  String message;
  String personname;
  bool bstream = false;
  bool bdetect = false;
  bool bcapture = false;
  bool brecognise = false;
  bool bdeleteall = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Camera Vision"),
      ),
      body: Column(
        children: <Widget>[
          StreamBuilder(
    stream: _dataRef.onValue,
    builder: (context, snapshot) {
    if (snapshot.hasData &&
    !snapshot.hasError &&
    snapshot.data.snapshot.value != null) {
      print(
          "snapshot data:${snapshot.data.snapshot.value.toString()}");
    }}
    ),
          buildImage(context),
          SizedBox(
            height: 10.0,
          ),
          Text(
            message,
            style: kVisionMsgTextStyle,
          ),
          SizedBox(
            height: 8.0,
          ),
          TextField(
            obscureText: true,
            textAlign: TextAlign.center,
            onChanged: (value) {
              bcapture = false;
              personname = value;
            },
            decoration: kTextFieldDecoration.copyWith(
                hintText: 'Enter the person' 's name'),
          ),
          SizedBox(
            height: 24.0,
          ),
          Row(
            children: [
              MaterialButton(
                color: bstream ? Colors.grey : Colors.blue,
                textColor: Colors.white,
                splashColor: Colors.blueGrey,
                height: 100,
                onPressed: () {
                  bstream = !bstream;
                  onCMDSEND("stream");
                },
                child: const Text('STREAM'),
              ),
              MaterialButton(
                color: bdetect ? Colors.grey : Colors.blue,
                textColor: Colors.white,
                splashColor: Colors.blueGrey,
                height: 100,
                onPressed: () {
                  bdetect = !bdetect;
                  onCMDSEND("detect");
                },
                child: const Text('DETECT'),
              ),
            ],
          ),
          Row(
            children: [
              MaterialButton(
                color: bcapture ? Colors.grey : Colors.blue,
                textColor: Colors.white,
                splashColor: Colors.blueGrey,
                height: 100,
                onPressed: () {
                  bcapture = !bcapture;
                  onCMDSEND("capture: $personname");
                },
                child: const Text('CAPTURE'),
              ),
              MaterialButton(
                color: brecognise ? Colors.grey : Colors.blue,
                textColor: Colors.white,
                splashColor: Colors.blueGrey,
                height: 100,
                onPressed: () {
                  brecognise = !brecognise;
                  onCMDSEND("recognise");
                },
                child: const Text('RECOGNISE'),
              ),
            ],
          ),
          SizedBox(
            height: 24.0,
          ),
          Text(
            'Captured Faces',
            style: kCapFaceTextStyle,
          ),
          ListView.builder(),
          SizedBox(
            height: 24.0,
          ),
          MaterialButton(
            color: bdeleteall ? Colors.grey : Colors.blue,
            textColor: Colors.white,
            splashColor: Colors.blueGrey,
            height: 100,
            onPressed: () {
              bdeleteall = !bdeleteall;
              onCMDSEND("delete_all");
            },
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }
  
  Widget addFaceToScreen(personname){
    return ListView.builder(itemBuilder: null)
  }

  Widget buildImage(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
          decoration: BoxDecoration(color: Colors.black),
          child: Center(
            child: widget._file == null
                ? Text('No Image')
                : FutureBuilder<Size>(
                    future: _getImageSize(
                        Image.file(widget._file, fit: BoxFit.fitWidth)),
                    builder:
                        (BuildContext context, AsyncSnapshot<Size> snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                            foregroundDecoration: LabelDetectDecoration(
                                _currentLabelLabels, snapshot.data),
                            child:
                                Image.file(widget._file, fit: BoxFit.fitWidth));
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
          )),
    );
  }

  void onCMDSEND(String cmd) {
    //send the command to firebase database
  }
}
