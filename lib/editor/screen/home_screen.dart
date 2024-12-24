import 'package:editor_app/editor/service/picker_service.dart';
import 'package:editor_app/editor/utils/screen_size.dart';
import 'package:editor_app/editor/widgets/add_text_widgets.dart';
import 'package:editor_app/editor/widgets/video_player_widget.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:video_editor/video_editor.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoEditorController controller;
  Color colorText = Colors.white;
  PickerService pickerService = PickerService();
  List<File> _selectedFiles = [];
  File? file;
  String? outputVideoPath;

  @override
  void initState() {
    super.initState();
    if (outputVideoPath != null) file = File(outputVideoPath!);
    if (file != null) {
      controller = VideoEditorController.file(
        file!,
        minDuration: const Duration(seconds: 1),
        maxDuration: const Duration(seconds: 60),
      );
      controller.initialize(aspectRatio: 9/16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(""),
        actions: [
          IconButton(
            icon: Icon(
              Icons.light,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          IconButton(
              icon: Icon(
                Icons.cancel,
                color: Colors.white,
              ),
              onPressed: () {})
        ],
      ),
      body: Column(children: [
        Expanded(
            child: Container(
          color: Colors.black,
          child: file == null
              ? Container()
              : CropGridViewer.edit(controller: controller),
        )),
        Expanded(
            child: Column(
              children: [
                Slider(value: controller.videoPosition.inSeconds.toDouble() ?? 0.0, onChanged: (double second){
                 // controller.

                }),
                Container(
                          color: Colors.black,
                          child: Stack(
                children: [
                  Container(
                    child: Container(),
                  ),
                  Positioned(
                      right: 10,
                      top: 100,
                      child: Column(
                        children: [
                          Container(
                            color: Colors.white,
                            child: IconButton(
                                onPressed: () {
                                  _showAddText();
                                },
                                icon: Icon(Icons.abc)),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            color: Colors.white,
                            child: IconButton(
                                onPressed: () {
                                  _showOptions();
                                },
                                icon: Icon(Icons.music_note_outlined)),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            color: Colors.white,
                            child: IconButton(
                                onPressed: () {
                                  _showOptions();
                                },
                                icon: Icon(Icons.add)),
                          )
                        ],
                      )),
                ],
                          ),
                        ),
              ],
            ))
      ]),
    );
  }

  void _showAddText() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return AddTextSheet();
      },
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                _selectedFiles
                    .add(File(await pickerService.captureImageFromCamera()));
                outputVideoPath = await pickerService.createVideoFromImages(
                    _selectedFiles.map((st) => st.path).toList());
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam),
              title: Text('Quay video'),
              onTap: () async {
                Navigator.pop(context);
                _selectedFiles.add(File(await pickerService.captureVideo()));
                outputVideoPath = await pickerService.createVideoFromImages(
                    _selectedFiles.map((st) => st.path).toList());
              },
            ),
            ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('Tải lên nhiều tệp'),
              onTap: () async {
                Navigator.pop(context);
                final files = await pickerService.pickMultipleFiles();
                _selectedFiles
                    .addAll(files.map((files) => (File(files))).toList());
                outputVideoPath = await pickerService.createVideoFromImages(
                    _selectedFiles.map((st) => st.path).toList());
                setState(() {
                  outputVideoPath = files[0];
                  if (outputVideoPath != null) file = File(outputVideoPath!);
                  if (file != null) {
                    controller = VideoEditorController.file(
                      file!,
                      minDuration: const Duration(seconds: 1),
                      maxDuration: const Duration(seconds: 60),
                    );
                    controller.initialize(aspectRatio: 9/16);
                  }
                  //  outputVideoPath = outputVideoPath;
                });
                outputVideoPath = outputVideoPath;
              },
            ),
          ],
        );
      },
    );
  }
}
