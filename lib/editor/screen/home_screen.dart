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
  int totalTime = 0;
  List<Media> media = [];
  bool isLoading = false;
  VideoPlayerController? videoPlayerController;
  Color colorText = Colors.white;
  PickerService pickerService = PickerService();
  List<File> _selectedFiles = [];
  File? file;
  String? outputVideoPath;
  bool isPlaying = false;
  List<File> _thumbnails = [];
  final double height = 60;
  ScrollController? scrollController1;
  ScrollController? scrollController2;
  int? selectedBlockIndex;
  double startValue = 0.0;
  double endValue = 6.0;
  double maxDuration = 6.0;

  //List<String?> thumbnails = [];
  double playheadPosition = 0.0;
  double _maxDuration = 6.0;
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
    if (_selectedFiles.isNotEmpty) _initializeAndPlayVideo(_currentVideoIndex);
  }

  void _initializeAndPlayVideo(int index) {
    if (videoPlayerController != null) {
      videoPlayerController!.dispose(); // Giải phóng bộ nhớ cho controller cũ
    }
    if (_selectedFiles[index] != null) {
      videoPlayerController = VideoPlayerController.file(
        _selectedFiles[index],
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
          videoPlayerController!.play(); // Đảm bảo video được phát
        }).catchError((error) {
          print(
              "========================================================Error during initialization: $error");
        });
    }
  }

  void _scrollBasedOnVideoPosition() {
    if (videoPlayerController != null) {
      int currentTime = videoPlayerController!.value.position.inSeconds;
      if (currentTime - lastScrollTime >= 1) {
        double position = scrollController2!.position.pixels + 50;
        scrollController2!.animateTo(
          position,
          duration: Duration(milliseconds: 0),
          curve: Curves.easeInOut,
        );

        lastScrollTime = currentTime;
      }
    }
  }

  void updateTimeLine() {
    if (scrollController1!.hasClients) {
      scrollController1!.animateTo(scrollController2!.offset,
          duration: Duration(milliseconds: 10), curve: Curves.easeInOut);
      double scrollPosition = scrollController2!.offset;
      videoPlayerController!.seekTo(Duration(seconds: scrollPosition.toInt()));
      //scrollController1!.jumpTo(scrollController2!.offset);
    }
  }

  void _playNextVideo() {
    if (_currentVideoIndex < _selectedFiles.length - 1) {
      setState(() {
        _currentVideoIndex++;
        _initializeAndPlayVideo(_currentVideoIndex);
      });

      _initializeAndPlayVideo(_currentVideoIndex);
      videoPlayerController!.play();
    } else {
      setState(() {
        videoPlayerController!.pause();
        _currentVideoIndex = 0;
      });
      lastScrollTime = 0;
      log("===================Đã phát hết danh sách video.");
    }
  }

  void dispose() {
    scrollController1!.dispose();
    scrollController2!.dispose();

    //controller!.removeListener(_updateScrollPosition);
    super.dispose();
  }

  Future<void> _generateThumbnails() async {
    setState(() {
      isLoading = true;
    });
    final tempDir = await getTemporaryDirectory();

    for (int k = 0; k < _selectedFiles.length; k++) {
      // Tạo một VideoPlayerController mới cho video hiện tại
      final tempController = VideoPlayerController.file(_selectedFiles[k]);
      await tempController.initialize(); // Đảm bảo khởi tạo xong

      final int length =
          tempController.value.duration.inSeconds; // Lấy độ dài video
      print("============================================ Duration = $length");

      List<File> files = [];
      totalTime += length;

      if (length > 0) {
        for (int i = 0; i < length; i++) {
          // Lấy thumbnail tại mỗi giây (timeMs = i * 1000)
          int timeMs = i * 1000; // Lấy thumbnail mỗi giây
          print("=============================================$timeMs");

          // Tạo tên file duy nhất cho mỗi thumbnail
          final String thumbnailFileName =
              'thumbnail_${k}_${i}.png'; // Tên file thumbnail duy nhất
          final String thumbnailPath = '${tempDir.path}/$thumbnailFileName';

          // Tạo thumbnail và lưu vào file
          final result = await VideoThumbnail.thumbnailFile(
            video: _selectedFiles[k].path,
            thumbnailPath: thumbnailPath,
            imageFormat: ImageFormat.PNG,
            timeMs: timeMs,
            quality: 50,
          );

          if (result != null) {
            files.add(File(result));
            setState(() {
              _thumbnails.add(File(result));
            });
          }
        }
      }

      // Lưu thông tin media
      media.add(Media(
        file: _selectedFiles[k],
        end: totalTime,
        start: totalTime + length,
        images: files,
      ));

      // Giải phóng controller sau khi dùng xong
      await tempController.dispose();
    }

    setState(() {
      isLoading = false;
    });
  }

  // void _updateScrollPosition() {
  //   if (videoPlayerController!.value.isPlaying) {
  //     final double position =
  //         controller!.trimPosition * controller!.videoDuration.inSeconds * 100;
  //     scrollController!.animateTo(
  //       position,
  //       duration: Duration(milliseconds: 200),
  //       curve: Curves.easeOut,
  //     );
  //   }
  // }

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
      body: isLoading
          ? Container(
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(children: [
              videoPlayerController == null
                  ? Expanded(flex: 1, child: Container())
                  : Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(videoPlayerController!),
                            AnimatedBuilder(
                              animation: videoPlayerController!,
                              builder: (_, __) => AnimatedOpacity(
                                opacity: videoPlayerController!.value.isPlaying
                                    ? 0
                                    : 1,
                                duration: kThemeAnimationDuration,
                                child: GestureDetector(
                                  onTap: videoPlayerController!.value.isPlaying
                                      ? videoPlayerController!.pause
                                      : videoPlayerController!.play,
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
                                            // Không hoạt động nếu videoPlayerController chưa được khởi tạo
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
                                    SizedBox(height: 5),
                                    Container(
                                      height: 40,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      child: SingleChildScrollView(
                                        physics: NeverScrollableScrollPhysics(),
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
                                                  width: 50,
                                                  child: Text(
                                                    "$index",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                );
                                              }))),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      height: 60,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      child: SingleChildScrollView(
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
                                                                      width: 50,
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
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    ),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    ),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    ),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 30,
                                                      color: Colors.white,
                                                    )
                                                  ],
                                                ),
                                              ))),
                                          )),
                                    ),
                                    SizedBox(height: 10),
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
                                                      style: TextStyle(
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
                await _generateThumbnails();
                setState(() {
                  if (_selectedFiles.isNotEmpty) {
                    _thumbnails = _thumbnails;
                    _initializeAndPlayVideo(_currentVideoIndex);
                  }
                  _thumbnails = _thumbnails;
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
