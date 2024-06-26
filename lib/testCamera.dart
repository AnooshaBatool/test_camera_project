import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'main.dart';
import 'package:permission_handler/permission_handler.dart';


class detectionPage extends StatefulWidget {
  const detectionPage({Key? key}) : super(key: key);

  @override
  State<detectionPage> createState() => _detectionPageState();
}

class _detectionPageState extends State<detectionPage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';

  @override
  void initState()
  {
    super.initState();
    requestPermissions();
    loadCamera();
    loadTfModel();
  }
  Future<void> requestPermissions() async {
    if (await Permission.camera.request().isGranted) {
      // Permission is granted, start using the camera
      print("Permission Granted");
    } else {
      // Handle the case when the permission is not granted
      print("Permission not Granted");
    }
  }

  loadCamera ()
  {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value){
      if(!mounted){
        return;
      }
      else{
        setState(() {
          cameraController!.startImageStream((imageStream){
            cameraImage = imageStream;
            print("Camera is loaded!");
            runModel();
            print("After running model!");
          });
        });
      }
    });
  }
  runModel() async {
    if(cameraImage != null)
    {
      var predictions = await Tflite.runModelOnFrame(bytesList: cameraImage!.planes.map((plane){
        return plane.bytes;
      }).toList(),
          imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      print("Before running model.");
      predictions!.forEach((element) {
        setState(() {
          output = element['label'];
          print("We have completed running model.");
        });
      });
    }
    else
    {
      print("No input!");
    }
  }
  loadTfModel() async{
    String? res = await Tflite.loadModel(
      model: "assets/tflite_model.tflite",
      labels: "assets/labels.txt",
    );
    print("Model loaded: $res");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Acne Detection")),
      body: Column(
        children: [
          Padding(padding:
          EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height*0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized?
              Container():
              AspectRatio(aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!,),
              ),
            ),),
          Text('Output: $output',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20
            ),)
        ],
      ),
    );
  }
}
