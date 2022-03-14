import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Face Detection using API'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Selected Image storing in a Variable
  File? _selectedImage;
  // Faces Coordinates List wrt x, y, w, h
  List<List<int>> facesCoordinates = <List<int>>[];
  // Boolean value whether the face is detected or not
  bool get isFaceDetected => facesCoordinates.isEmpty ? false : true;

  Future<http.Response> getFaceCoordinate(File file, String link) async {
    ///MultiPart request
    String filename = file.path.split('/').last;
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(link),
    );
    Map<String, String> headers = {"Content-type": "multipart/form-data"};
    request.files.add(
      http.MultipartFile(
        'image',
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: filename,
      ),
    );
    request.headers.addAll(headers);
    print("request: " + request.toString());
    var res = await request.send();
    var response = await http.Response.fromStream(res);
    print("This is response:" + response.body);
    print("This is response: ${res.statusCode} ");
    print("This is response: ${res.statusCode} ");
    return response;
  }

  Future<void> _addImage() async {
    facesCoordinates.clear();
    final image =
        await ImagePicker.platform.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _selectedImage = File(image.path);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_selectedImage == null)
                  const Text(
                    'Please Select a Image',
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Image.file(File(_selectedImage!.path))),
                      TextButton(
                          onPressed: () async {
                            final res = await getFaceCoordinate(
                                File(_selectedImage!.path),
                                "https://c304-43-241-129-110.ngrok.io/face_detection");
                            debugPrint(res.body);
                            final val = jsonDecode(res.body);
                            List<List<int>> data = [];
                            for (var items in val['faces']) {
                              List<int> s = [];
                              for (var item in items as List) {
                                s.add(int.parse("$item"));
                              }
                              data.add(s);
                            }
                            debugPrint("$data");
                            facesCoordinates = data;

                            setState(() {});
                          },
                          child: const Text("Detect Face")),
                      isFaceDetected
                          ? FutureBuilder<ui.Image>(
                              future: decodeImageFromList(
                                  File(_selectedImage!.path).readAsBytesSync()),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container();
                                }
                                return SizedBox(
                                  width: snapshot.data!.width.toDouble(),
                                  height: snapshot.data!.height.toDouble(),
                                  child: CustomPaint(
                                    painter: FacePainter(
                                      snapshot.data!,
                                      facesCoordinates,
                                    ),
                                  ),
                                );
                              })
                          : const Text(
                              "No Face Detected or click Detect Face Button"),
                    ],
                  ),
              ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addImage,
        tooltip: 'Image',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<List<int>> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    debugPrint("Coordinates $faces");

    for (var i = 0; i < faces.length; i++) {
      final x = faces[i][0].toDouble();
      final y = faces[i][1].toDouble();
      final w = faces[i][2].toDouble();
      final h = faces[i][3].toDouble();
      final rect = ui.Rect.fromPoints(ui.Offset(x, y), ui.Offset(x + w, y + h));
      rects.add(rect);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const ui.Color.fromARGB(255, 255, 0, 0);

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
