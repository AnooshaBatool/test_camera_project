import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class TestGalCam extends StatefulWidget {
  const TestGalCam({Key? key}) : super(key: key);

  @override
  State<TestGalCam> createState() => _TestGalCamState();
}

class _TestGalCamState extends State<TestGalCam> {
  Uint8List? _image;
  File? selectedImage;
  String _result = '';

  @override
  void initState() {
    super.initState();
    loadTfModel();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  Future<void> loadTfModel() async {
    String? res = await Tflite.loadModel(
      model: "assets/tflite_model.tflite",
      labels: "assets/labels.txt",
    );
    print("Model loaded: $res");
  }

  Future<void> classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 2,
      threshold: 0.1,
      asynch: true,
    );
    setState(() {
      _result = output != null && output.isNotEmpty
          ? output.map((e) => e['label']).join(', ')
          : 'No results';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Center(
        child: Stack(
          children: [
            _image != null
                ? CircleAvatar(
                radius: 100, backgroundImage: MemoryImage(_image!))
                : const CircleAvatar(
              radius: 100,
              backgroundImage: NetworkImage(
                  "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png"),
            ),
            Positioned(
                bottom: -0,
                left: 140,
                child: IconButton(
                    onPressed: () {
                      showImagePickerOption(context);
                    },
                    icon: const Icon(Icons.add_a_photo))),
            if (_result.isNotEmpty)
              Positioned(
                bottom: 70,
                left: 40,
                child: Text(
                  'Result: $_result',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.blue[100],
      context: context,
      builder: (builder) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 4.5,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pickImageFromGallery();
                    },
                    child: const SizedBox(
                      child: Column(
                        children: [
                          Icon(
                            Icons.image,
                            size: 70,
                          ),
                          Text("Gallery")
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pickImageFromCamera();
                    },
                    child: const SizedBox(
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 70,
                          ),
                          Text("Camera")
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;
    setState(() {
      selectedImage = File(pickedImage.path);
      _image = File(pickedImage.path).readAsBytesSync();
    });
    classifyImage(selectedImage!);
    Navigator.of(context).pop(); // close the modal sheet
  }

  Future<void> _pickImageFromCamera() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage == null) return;
    setState(() {
      selectedImage = File(pickedImage.path);
      _image = File(pickedImage.path).readAsBytesSync();
    });
    classifyImage(selectedImage!);
    Navigator.of(context).pop(); // close the modal sheet
  }
}
