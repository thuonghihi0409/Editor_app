import 'package:editor_app/editor/screen/Crop_screen.dart';
import 'package:editor_app/editor/screen/crop_page.dart';
import 'package:editor_app/editor/service/picker_service.dart';

import 'package:editor_app/editor/widgets/add_text_widgets.dart';
import 'package:video_editor/video_editor.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  VideoEditorController? controller;
  Color colorText = Colors.white;
  PickerService pickerService = PickerService();
  List<File> _selectedFiles = [];
  File? file;
  String? outputVideoPath;
  double _start = 0.0;
  double _end = 0.0;
  bool isPlaying = false;
  List<String> _thumbnails = [];
  final double height = 60;
  ScrollController? scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();

    if (outputVideoPath != null) file = File(outputVideoPath!);
    if (file != null) {
      controller = VideoEditorController.file(
        file!,
        minDuration: const Duration(seconds: 1),
        maxDuration: const Duration(seconds: 60),
      );
      controller!
          .initialize(aspectRatio: 9 / 16)
          .then((_) => setState(() {}))
          .catchError((error) {
        // handle minumum duration bigger than video duration error
        Navigator.pop(context);
      }, test: (e) => e is VideoMinDurationError);
     // controller!.addListener(_updateScrollPosition);
    }
  }

  void dispose() {
    scrollController!.dispose();
    //controller!.removeListener(_updateScrollPosition);
    super.dispose();
  }

  void _updateScrollPosition() {
    if (controller!.isPlaying) {
      final double position =
          controller!.trimPosition * controller!.videoDuration.inSeconds * 100;

      scrollController!.animateTo(
        position,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
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
        controller == null
            ? Expanded(flex: 1, child: Container())
            : Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CropGridViewer.preview(controller: controller!),
                      AnimatedBuilder(
                        animation: controller!.video,
                        builder: (_, __) => AnimatedOpacity(
                          opacity: controller!.isPlaying ? 0 : 1,
                          duration: kThemeAnimationDuration,
                          child: GestureDetector(
                            onTap: controller!.video.play,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  if (controller != null)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (isPlaying) {
                                      controller!.video.pause();
                                    } else {
                                      controller!.video.play();
                                    }
                                    isPlaying = !isPlaying;
                                  });
                                },
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ))
                          ],
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: _trimSlider(),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                )),
                            IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.delete, color: Colors.white)),
                            IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => CropScreen(file: file!)));
                                },
                                icon: Icon(Icons.cut, color: Colors.white))
                          ],
                        ),
                        //_coverSelection()
                      ],
                    ),
                  Positioned(
                      right: 10,
                      top: 180,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                            ),
                            child: IconButton(
                                onPressed: () {
                                  _showOptions();
                                },
                                icon: Icon(Icons.add)),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                            ),
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
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                            ),
                            child: IconButton(
                                onPressed: () {
                                  _showAddText();
                                },
                                icon: Icon(Icons.text_format)),
                          ),
                        ],
                      )),
                ],
              ),
            ))
      ]),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          controller,
          controller!.video,
        ]),
        builder: (_, __) {
          final int duration = controller!.videoDuration.inSeconds;
          final double pos = controller!.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              Text(
                formatter(Duration(seconds: duration)),
                style: TextStyle(color: Colors.white),
              ),
              const Expanded(child: SizedBox()),
              AnimatedOpacity(
                opacity: controller!.isTrimming ? 1 : 0,
                duration: kThemeAnimationDuration,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatter(controller!.startTrim),
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 10),
                  Text(formatter(controller!.endTrim),
                      style: TextStyle(color: Colors.white)),
                ]),
              ),
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: controller!,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: controller!,
            padding: const EdgeInsets.only(top: 10),
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
      )
    ];
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
                if (outputVideoPath != null)
                  _thumbnails =
                      await pickerService.generateThumbnails(outputVideoPath!);
                setState(() {
                  outputVideoPath = files[0];
                  if (outputVideoPath != null) file = File(outputVideoPath!);
                  if (file != null) {
                    controller = VideoEditorController.file(
                      file!,
                      minDuration: const Duration(seconds: 1),
                      maxDuration: const Duration(seconds: 60),
                    );

                    controller!
                        .initialize(aspectRatio: 9 / 16)
                        .then((_) => setState(() {}))
                        .catchError((error) {
                      // handle minumum duration bigger than video duration error
                      Navigator.pop(context);
                    }, test: (e) => e is VideoMinDurationError);
                    controller!.addListener(_updateScrollPosition);
                  }
                  _thumbnails = _thumbnails;
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
