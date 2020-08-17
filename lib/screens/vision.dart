import 'package:flutter/material.dart';
import 'package:esp32_project_flutter_app/constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:mlkit/mlkit.dart';
import 'dart:async';
import 'package:esp32_project_flutter_app/camdata.dart';
import 'dart:typed_data';
import 'dart:convert';

DatabaseReference _dataRef =
    FirebaseDatabase.instance.reference().child('esp32-cam');

class Vision extends StatefulWidget {
  static const String id = 'vision';
  //final File _file ;

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
  List<VisionLabel> _currentLabelLabels = <VisionLabel>[];
  String _base64;

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
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder(
                stream: _dataRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      !snapshot.hasError &&
                      snapshot.data.snapshot.value != null) {
                    print(
                        "snapshot data:${snapshot.data.snapshot.value['photo'].toString()}");
                    var _photo =
                        CamData.fromJson(snapshot.data.snapshot.value['photo']);
                    _base64 = _photo.data;
                    print("imagedata: $_base64");
                    return buildImagebase64(context);
                  } else {
                    return Center(
                      child: Text("No data yet"),
                    );
                  }
                }),
            Text(
              message == null ? "No message" : message,
              style: kVisionMsgTextStyle,
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
            Row(
              children: [
                MaterialButton(
                  color: bstream ? Colors.grey : Colors.blue,
                  textColor: Colors.white,
                  splashColor: Colors.blueGrey,
                  height: 20,
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
                  height: 20,
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
                  height: 20,
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
                  height: 20,
                  onPressed: () {
                    brecognise = !brecognise;
                    onCMDSEND("recognise");
                  },
                  child: const Text('RECOGNISE'),
                ),
              ],
            ),
            Text(
              'Captured Faces',
              style: kCapFaceTextStyle,
            ),
            Text(
              'Should be ListView',
              style: kCapFaceTextStyle,
            ),
            MaterialButton(
              color: bdeleteall ? Colors.grey : Colors.blue,
              textColor: Colors.white,
              splashColor: Colors.blueGrey,
              height: 20,
              onPressed: () {
                bdeleteall = !bdeleteall;
                onCMDSEND("delete_all");
              },
              child: const Text('DELETE ALL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget addFaceToScreen(personname) {
    return ListView.builder(itemBuilder: null);
  }

  Widget buildImagebase64(BuildContext context) {
    if (_base64 == null) return new Container();
    Uint8List bytes = base64.decode(_base64);
    return new Scaffold(
      appBar: new AppBar(title: new Text('Example App')),
      body: new ListTile(
        leading: new Image.memory(bytes),
        title: new Text("image"),
      ),
    );
  }

  Widget buildImage(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(color: Colors.black),
        child: Center(
            /*child: widget._file == null
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
                  ),*/
            ),
      ),
    );
  }

  void onCMDSEND(String cmd) {
    //send the command to firebase database
  }

  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = Completer<Size>();
    /*image.image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble())));*/
    return completer.future;
  }
}

class LabelDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionLabel> _labels;
  LabelDetectDecoration(List<VisionLabel> labels, Size originalImageSize)
      : _labels = labels,
        _originalImageSize = originalImageSize;

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _LabelDetectPainter(_labels, _originalImageSize);
  }
}

class _LabelDetectPainter extends BoxPainter {
  final List<VisionLabel> _labels;
  final Size _originalImageSize;
  _LabelDetectPainter(labels, originalImageSize)
      : _labels = labels,
        _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    print("labels:${_labels}");
    /*for (var label in _labels) {
      final _rect = Rect.fromLTRB(
          offset.dx + label.rect.left / _widthRatio,
          offset.dy + label.rect.top / _heightRatio,
          offset.dx + label.rect.right / _widthRatio,
          offset.dy + label.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    canvas.restore();*/
  }
}
