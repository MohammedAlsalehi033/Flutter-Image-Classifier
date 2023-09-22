import 'dart:ffi';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(Home());
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? finalImage;
  bool isBusy = false;
  List  results = [];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  Future<void> pickImage(ImageSource imageSource) async {
    var image = await ImagePicker().pickImage(source: imageSource);
    if (image != null) {
      setState(() {
        finalImage = File(image.path);
      });
    }
  }

  Future<void> detectImage() async {
    if (isBusy || finalImage == null) {
      debugPrint("No image selected or interpreter is busy");
      return;
    }

    setState(() {
      isBusy = true;
    });

    var output = await Tflite.runModelOnImage(
      path: finalImage!.path,
      imageMean: 0.0,
      imageStd: 255.0,
      threshold: 0.2,
      asynch: true,
    );



    setState(() {
      isBusy = false;
      results = output!;
      debugPrint(results[0].toString());
    });
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();

  }

  String showResult2 (String input){
    int Start = input.indexOf("label");
    String output = input.substring(Start + 5 , input.length-1);
    return output;
  }
  double showResult(String input) {
    double output = 0;
    String confidence = "";

    for (int i = 0; i < input.length; i++) {

      if (input[i] == ':' && input[i + 1] == ' ') {
        // Start extracting the value after the colon
        int j = i + 1;

        while (j < input.length && input[j] != ',' && input[j] != '}') {

          confidence += input[j];
          j++;
        }

        break; // Stop the loop after extracting the confidence value
      }
    }

    output =  double.parse(confidence.substring(0,5))*100;
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("pornography Detector"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [if (finalImage != null)
              Image.file(finalImage!,width: 400,height: 400,)
            else
              Text("No image selected"),
              results.isNotEmpty ? Text("this Image is "+ showResult2(results[0].toString())+ " Confidence: "+showResult(results[0].toString()).toString() + "%") : Text("the data will be showm here"),

              ElevatedButton(
                onPressed: () => pickImage(ImageSource.gallery),
                child: Text("Pick Image form gallery"),
              ),
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.camera),
                child: Text("Take a photo"),
              ),
              ElevatedButton(
                onPressed: detectImage,
                child: Text("Check"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
