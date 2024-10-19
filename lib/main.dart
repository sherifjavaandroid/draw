import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: CanvasPainting()));

class CanvasPainting extends StatefulWidget {
  const CanvasPainting({Key? key}) : super(key: key);

  @override
  _CanvasPaintingState createState() => _CanvasPaintingState();
}

class _CanvasPaintingState extends State<CanvasPainting> {
  GlobalKey globalKey = GlobalKey();

  double opacity = 1.0;
  StrokeCap strokeType = StrokeCap.round;
  double strokeWidth = 3.0;
  Color selectedColor = Colors.black;

  Color backgroundColor = Colors.white;
  String selectedFont = 'Arial';
  String inputText = "";
  double fontSize = 30.0;
  ui.Image? backgroundImage;

  Offset textPosition = const Offset(20, 300);

  List<TouchPoints?> points = [];
  final bool _isTextFieldVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(TouchPoints(
              points: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = strokeType
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth,
            ));
          });
        },
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(TouchPoints(
              points: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = strokeType
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth,
            ));
          });
        },
        onPanEnd: (details) {
          setState(() {
            points.add(null);
          });
        },
        child: RepaintBoundary(
          key: globalKey,
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: Size.infinite,
                painter: MyPainter(
                  pointsList: points,
                  inputText: inputText,
                  selectedFont: selectedFont,
                  fontSize: fontSize,
                  textPosition: textPosition,
                  backgroundImage: backgroundImage,
                  backgroundColor: backgroundColor,
                ),
              ),
              if (_isTextFieldVisible)
                Positioned(
                  bottom: 80,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (text) {
                            setState(() {
                              inputText = text;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Type your text here...',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          setState(() {
                            inputText = "";
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Positioned(
                top: textPosition.dy,
                left: textPosition.dx,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      textPosition += details.delta;
                    });
                  },
                  child: Text(
                    inputText,
                    style: TextStyle(
                      fontFamily: selectedFont,
                      fontSize: fontSize,
                      color: selectedColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _takeScreenshot(),
        child: const Icon(Icons.camera_alt),
        tooltip: 'Take Screenshot',
      ),
    );
  }

  Widget colorMenuItem(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: color,
        ),
      ),
    );
  }

  Widget colorMenuItem1(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (backgroundColor == color) {
            return;
          }
          backgroundColor = color;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: color,
        ),
      ),
    );
  }

  Future<void> _takeScreenshot() async {
    try {
      // Capture the image
      RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get the app's document directory
      final directory = await getApplicationDocumentsDirectory();

      // Create the 'ma3lom' folder if it doesn't exist
      final ma3lomDir = Directory('${directory.path}/ma3lom');
      if (!await ma3lomDir.exists()) {
        await ma3lomDir.create(recursive: true);
      }

      // Generate a unique filename using current timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${ma3lomDir.path}/screenshot_$timestamp.png';

      // Save the image
      File imgFile = File(imagePath);
      await imgFile.writeAsBytes(pngBytes);

      // Send the image to the backend
      await _sendImageToBackend(imgFile);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot saved in ma3lom folder and sent to backend')),
      );
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take screenshot: $e')),
      );
    }
  }
  Future<void> _sendImageToBackend(File imageFile) async {
    var uri = Uri.parse('YOUR_BACKEND_URL_HERE');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Image sent successfully');
        }
      } else {
        if (kDebugMode) {
          print('Failed to send image. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending image: $e');
      }
    }
  }
}

class MyPainter extends CustomPainter {
  final List<TouchPoints?> pointsList;
  final String inputText;
  final String selectedFont;
  final double fontSize;
  final Offset textPosition;
  final ui.Image? backgroundImage;
  final Color backgroundColor;

  MyPainter({
    required this.pointsList,
    required this.inputText,
    required this.selectedFont,
    required this.fontSize,
    required this.textPosition,
    required this.backgroundImage,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    paint.color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage!, Offset.zero, paint);
    }

    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(pointsList[i]!.points, pointsList[i + 1]!.points,
            pointsList[i]!.paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        canvas.drawPoints(
            ui.PointMode.points, [pointsList[i]!.points], pointsList[i]!.paint);
      }
    }

    if (inputText.isNotEmpty) {
      TextSpan span = TextSpan(
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontFamily: selectedFont,
        ),
        text: inputText,
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, textPosition);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TouchPoints {
  Offset points;
  Paint paint;

  TouchPoints({required this.points, required this.paint});
}