import 'dart:developer';

import 'package:editor_app/editor/model/media.dart';
import 'package:editor_app/editor/model/time_line.dart';
import 'package:editor_app/editor/service/picker_service.dart';
import 'package:editor_app/editor/widgets/add_text_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int lastScrollTime = 0;
  int curentVideoTime = 0;
  int totalTime = 0;
  List<Media> media = [];
  bool isLoading = false;
  VideoPlayerController? videoPlayerController;
  Color colorText = Colors.white;
  PickerService pickerService = PickerService();

  // File? file;
  String? outputVideoPath;
  bool isPlaying = false;

  //List<File> _thumbnails = [];
  final double height = 60;
  ScrollController? scrollController1;
  ScrollController? scrollController2;
  int? selectedBlockIndex;
  double startValue = 0.0;
  double endValue = 6.0;
  double maxDuration = 6.0;

  //List<String?> thumbnails = [];
  double playheadPosition = 0.0;

  // double _maxDuration = 6.0;
  int _currentVideoIndex = 0;

  List<TimelineBlock> timelines = [
    TimelineBlock(
      start: 0,
      end: 2,
      content: 'hello',
    ),
    TimelineBlock(
      start: 2,
      end: 4,
      content: 'xin chào',
    ),
    TimelineBlock(
      start: 2,
      end: 4,
      content: 'xin chào',
    ),
    TimelineBlock(
      start: 2,
      end: 4,
      content: 'xin chào',
    ),
    TimelineBlock(
      start: 2,
      end: 4,
      content: 'xin chào',
    ),
    TimelineBlock(
      start: 2,
      end: 4,
      content: 'xin chào',
    ),
    TimelineBlock(
      start: 2,
      end: 4,
      content: 'xin chào',
    ),
    TimelineBlock(
      start: 2,
      end: 4,
      content: 'xin chào',
    ),
  ];

  @override
  void initState() {
    super.initState();
    scrollController1 = ScrollController();
    scrollController2 = ScrollController()..addListener(updateTimeLine);
    if (media.isNotEmpty) _initializeAndPlayVideo(_currentVideoIndex);
  }

  void _initializeAndPlayVideo(int index) {
    if (videoPlayerController != null) {
      videoPlayerController!.dispose(); // Giải phóng bộ nhớ cho controller cũ
    }
    if (index < media.length) {
      videoPlayerController = VideoPlayerController.file(
        media[index].file,
      )..initialize().then((_) async {
          print(
              "=================================================Controller initialized successfully");
          setState(() {}); // Cập nhật giao diện
          videoPlayerController!.addListener(() {
            print(
                "===============================================Duration: ${videoPlayerController!.value.position.inSeconds}");
            print(
                "===============================================Current Position: ${videoPlayerController!.value.duration.inSeconds}");
            _scrollBasedOnVideoPosition();
            if (videoPlayerController!.value.position.inSeconds >=
                videoPlayerController!.value.duration.inSeconds) {
              _playNextVideo();
            }
          });
          videoPlayerController!.play();
          isPlaying = true; // Đảm bảo video được phát
        }).catchError((error) {
          print(
              "========================================================Error during initialization: $error");
        });
    }
  }

  void _scrollBasedOnVideoPosition() {
    if (videoPlayerController != null) {
      int currentTime =
          videoPlayerController!.value.position.inSeconds + curentVideoTime;
      if (currentTime - lastScrollTime >= 1) {
        double position = scrollController2!.position.pixels + 80;
        scrollController2!.animateTo(
          position % (totalTime * 80),
          duration: const Duration(milliseconds: 30),
          curve: Curves.easeInOut,
        );

        lastScrollTime = currentTime;
      }
    }
  }

  void updateTimeLine() {
    if (scrollController1!.hasClients) {
      scrollController1!.animateTo(scrollController2!.offset,
          duration: const Duration(milliseconds: 10), curve: Curves.easeInOut);

      // if (!videoPlayerController!.value.isPlaying) {
      //   double scrollPosition = scrollController2!.offset;
      //   videoPlayerController!
      //       .seekTo(Duration(seconds: scrollPosition.toInt()));
      // }
    }
    if (lastScrollTime / 80 > totalTime) {
      setState(() {
        lastScrollTime = 0;
      });
    }
  }

  int indexOfMedia() {
    for (int i = 0; i < media.length; i++) {
      if (lastScrollTime >= media[i].start && lastScrollTime <= media[i].end)
        return i;
    }
    return -1;
  }

  void _playNextVideo() {
    if (_currentVideoIndex < media.length - 1) {
      print(
          "====================================================== curentvideoindex = $_currentVideoIndex");
      print(
          "====================================================== total = $totalTime");
      setState(() {
        curentVideoTime +=
            (media[_currentVideoIndex].end - media[_currentVideoIndex].start);
        _currentVideoIndex++;
        _initializeAndPlayVideo(_currentVideoIndex);
        videoPlayerController!.play();
        isPlaying = true;
      });
    } else {
      setState(() {
        print(
            "====================================================== curentvideoindex1 = $_currentVideoIndex");
        _currentVideoIndex = 0;
        lastScrollTime = 0;
        curentVideoTime = 0;

        _initializeAndPlayVideo(_currentVideoIndex);
        isPlaying = false;
        videoPlayerController!.pause();
        print(
            "====================================================== curentvideoindex2 = $_currentVideoIndex");
      });

      log("===================Đã phát hết danh sách video.");
    }
  }

  void dispose() {
    scrollController1!.dispose();
    scrollController2!.dispose();
    super.dispose();
  }

  Future<void> _generateThumbnails(List<File> selections) async {
    setState(() {
      isLoading = true;
    });
    final tempDir = await getTemporaryDirectory();

    for (int k = 0; k < selections.length; k++) {
      // Tạo một VideoPlayerController mới cho video hiện tại
      final tempController = VideoPlayerController.file(selections[k]);
      await tempController.initialize(); // Đảm bảo khởi tạo xong

      final int length =
          tempController.value.duration.inSeconds; // Lấy độ dài video
      print("============================================ Duration = $length");

      List<File> files = [];

      if (length > 0) {
        for (int i = 0; i < length; i++) {
          int timeMs = i * 1000;
          print("=============================================$timeMs");
          final String thumbnailFileName = 'thumbnail_${k}_${i}.png';
          final String thumbnailPath = '${tempDir.path}/$thumbnailFileName';
          final result = await VideoThumbnail.thumbnailFile(
            video: selections[k].path,
            thumbnailPath: thumbnailPath,
            imageFormat: ImageFormat.PNG,
            timeMs: timeMs,
            quality: 50,
          );

          if (result != null) {
            files.add(File(result));
            setState(() {
              // _thumbnails.add(File(result));
            });
          }
        }
      }

      media.add(Media(
        file: selections[k],
        end: totalTime + length,
        start: totalTime,
        images: files,
      ));
      totalTime += length;
      await tempController.dispose();
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(""),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.light,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          IconButton(
              icon: const Icon(
                Icons.cancel,
                color: Colors.white,
              ),
              onPressed: () {})
        ],
      ),
      body: isLoading
          ? Container(
              child: const Center(child: CircularProgressIndicator()),
            )
          : Column(children: [
              videoPlayerController == null
                  ? Expanded(flex: 1, child: Container())
                  : Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(videoPlayerController!),
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
                        Container(
                          color: Colors.black,
                          child: videoPlayerController == null
                              ? Container()
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 30,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: videoPlayerController !=
                                                        null &&
                                                    videoPlayerController!
                                                        .value.isInitialized
                                                ? () {
                                                    if (videoPlayerController!
                                                        .value.isPlaying) {
                                                      videoPlayerController!
                                                          .pause();
                                                    } else {
                                                      videoPlayerController!
                                                          .play();
                                                    }
                                                    setState(() {
                                                      isPlaying = !isPlaying;
                                                    });
                                                  }
                                                : null,
                                            icon: Icon(
                                              isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      height: 40,
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 16),
                                      child: SingleChildScrollView(
                                        physics: const NeverScrollableScrollPhysics(),
                                        scrollDirection: Axis.horizontal,
                                        controller: scrollController1,
                                        child: Row(
                                            children: [
                                          Container(
                                            width: 190,
                                          )
                                        ]..addAll(List.generate(totalTime + 5,
                                                  (index) {
                                                return Container(
                                                  width: 80,
                                                  child: Text(
                                                    "${formatTime(index.toDouble())}",
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                );
                                              }))),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      height: 60,
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 16),
                                      child: SingleChildScrollView(
                                          physics: isPlaying
                                              ? const NeverScrollableScrollPhysics()
                                              : null,
                                          scrollDirection: Axis.horizontal,
                                          controller: scrollController2,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 190,
                                              )
                                            ]..addAll(media
                                                .map((mediaItem) => Container(
                                                      child: Row(
                                                        children:
                                                            mediaItem.images
                                                                .map((image) =>
                                                                    Container(
                                                                      width: 80,
                                                                      decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                              width: 1,
                                                                              color: Colors.grey)),
                                                                      child: Image
                                                                          .file(
                                                                              image),
                                                                    ))
                                                                .toList(),
                                                      ),
                                                    ))
                                                .toList()
                                              ..add(Container(
                                                width: 200,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                    ),
                                                    const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    ),
                                                    const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    ),
                                                    const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    ),
                                                    const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    )
                                                  ],
                                                ),
                                              ))),
                                          )),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      height:
                                          200, // Giới hạn chiều cao cho ListView thứ 2
                                      child: ListView.builder(
                                        itemBuilder: (context, index) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 30,
                                                  color: Colors.yellow,
                                                  child: Center(
                                                    child: Text(
                                                      "${timelines[index].content}",
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        itemCount: timelines.length,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 1,
                          top: 40,
                          bottom: 50,
                          child: Container(
                            width: 2,
                            color: Colors.white,
                          ),
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
                                      icon: const Icon(Icons.add)),
                                ),
                                const SizedBox(
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
                                      icon: const Icon(Icons.music_note_outlined)),
                                ),
                                const SizedBox(
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
                                      icon: const Icon(Icons.text_format)),
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

  String formatTime(double seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds.toInt() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                List<File> _selectedFiles = [];
                Navigator.pop(context);
                _selectedFiles
                    .add(File(await pickerService.captureImageFromCamera()));
                outputVideoPath = await pickerService.createVideoFromImages(
                    _selectedFiles.map((st) => st.path).toList());
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Quay video'),
              onTap: () async {
                List<File> _selectedFiles = [];
                Navigator.pop(context);
                _selectedFiles.add(File(await pickerService.captureVideo()));
                outputVideoPath = await pickerService.createVideoFromImages(
                    _selectedFiles.map((st) => st.path).toList());
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Tải lên nhiều tệp'),
              onTap: () async {
                Navigator.pop(context);
                List<File> _selectedFiles = [];
                final files = await pickerService.pickMultipleFiles();
                _selectedFiles
                    .addAll(files.map((files) => (File(files))).toList());
                await _generateThumbnails(_selectedFiles);
                setState(() {
                  if (_selectedFiles.isNotEmpty) {
                    // _thumbnails = _thumbnails;
                    _initializeAndPlayVideo(_currentVideoIndex);
                  }
                  // _thumbnails = _thumbnails;
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
