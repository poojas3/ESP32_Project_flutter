import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:mlkit/mlkit.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MLDetail extends StatefulWidget {
  static const String id = 'MLDetail_screen';
  final File _file;
  final String _scannerType;

  MLDetail(this._file, this._scannerType);

  @override
  State<StatefulWidget> createState() {
    return _MLDetailState();
  }
}

class _MLDetailState extends State<MLDetail> {
  FirebaseVisionTextDetector textDetector = FirebaseVisionTextDetector.instance;
  FirebaseVisionBarcodeDetector barcodeDetector =
      FirebaseVisionBarcodeDetector.instance;
  FirebaseVisionLabelDetector labelDetector =
      FirebaseVisionLabelDetector.instance;
  FirebaseVisionFaceDetector faceDetector = FirebaseVisionFaceDetector.instance;
  List<VisionLabel> _currentLabelLabels = <VisionLabel>[];

  Stream sub;
  StreamSubscription<dynamic> subscription;
  Timer _timer;
  final FlutterTts flutterTts = FlutterTts();
  String strspeech;

  @override
  void initState() {
    super.initState();
    sub = new Stream.empty();
    subscription = sub.listen((_) => _getImageSize)..onDone(analyzeLabels);
  }

  void analyzeLabels() async {
    try {
      var currentLabels;
      {
        currentLabels = await labelDetector.detectFromPath(widget._file.path);
        if (this.mounted) {
          setState(() {
            _currentLabelLabels = currentLabels;
          });
        }
        print("currentlabels:${currentLabels}");
      }
    } catch (e) {
      print("MyEx: " + e.toString());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget._scannerType),
        ),
        body: Column(
          children: <Widget>[
            buildImage(context),
            buildBarcodeList<VisionLabel>(_currentLabelLabels),
            Text(
              strspeech != null ? strspeech : "",
            ),
          ],
        ));
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
                      return Image.file(widget._file,
                          fit: BoxFit.fitWidth); //CircularProgressIndicator();
                    }
                  },
                ),
        ),
      ),
    );
  }

  Widget buildBarcodeList<T>(List<T> barcodes) {
    if (barcodes.length == 0) {
      return Expanded(
        flex: 1,
        child: Center(
          child: Text('Nothing detected',
              style: Theme.of(context).textTheme.subhead),
        ),
      );
    }
    return Expanded(
      flex: 1,
      child: Container(
        child: ListView.builder(
            padding: const EdgeInsets.all(1.0),
            itemCount: barcodes.length,
            itemBuilder: (context, i) {
              var text;

              final barcode = barcodes[i];

              VisionLabel res = barcode as VisionLabel;
              text = "Raw Value: ${res.label}";
              strspeech == null
                  ? strspeech = "${res.label}"
                  : strspeech += "/n${res.label}";
              _speak(strspeech);

              return _buildTextRow(text);
            }),
      ),
    );
  }

  Widget buildTextList(List<VisionText> texts) {
    if (texts.length == 0) {
      return Expanded(
          flex: 1,
          child: Center(
            child: Text('No text detected',
                style: Theme.of(context).textTheme.subhead),
          ));
    }
    return Expanded(
      flex: 1,
      child: Container(
        child: ListView.builder(
            padding: const EdgeInsets.all(1.0),
            itemCount: texts.length,
            itemBuilder: (context, i) {
              return _buildTextRow(texts[i].text);
            }),
      ),
    );
  }

  Widget _buildTextRow(text) {
    return ListTile(
      title: Text(
        "$text",
      ),
      dense: true,
    );
  }

  Future<Size> _getImageSize(Image image) {
    Completer<Size> completer = Completer<Size>();
    /*image.image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble())));*/
    return completer.future;
  }

  Future _speak(String wordtosay) async {
    await flutterTts.speak(wordtosay);
  }
}

/*
  This code uses the example from azihsoyn/flutter_mlkit
  https://github.com/azihsoyn/flutter_mlkit/blob/master/example/lib/main.dart
*/

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
  }
}
