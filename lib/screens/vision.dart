import 'package:flutter/material.dart';
import 'package:esp32_project_flutter_app/constants.dart';

class Vision extends StatefulWidget {
  @override
  _VisionState createState() => _VisionState();
}

class _VisionState extends State<Vision> {
  String message;
  String personname;
  bool bstream = false;
  bool bdetect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Camera Vision"),
      ),
      body: Column(
        children: <Widget>[
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
            children: [],
          )
        ],
      ),
    );
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
