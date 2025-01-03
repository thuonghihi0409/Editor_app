import 'dart:io';

import 'package:editor_app/editor/screen/crop_page.dart';
import 'package:editor_app/editor/service/export_service.dart';
import 'package:editor_app/editor/widgets/export_widgets.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoEditor extends StatefulWidget {
  const VideoEditor({super.key, required this.file});

  final File file;

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  late final VideoEditorController _controller = VideoEditorController.file(
    widget.file,
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    _controller
        .initialize(aspectRatio: 9 / 16)
        .then((_) => setState(() {}))
        .catchError((error) {
      // handle minumum duration bigger than video duration error
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
  }

  @override
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    ExportService.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );

  void _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;

    final config = VideoFFmpegVideoEditorConfig(
      _controller,
      // format: VideoExportFormat.gif,
      // commandBuilder: (config, videoPath, outputPath) {
      //   final List<String> filters = config.getExportFilters();
      //   filters.add('hflip'); // add horizontal flip

      //   return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
      // },
    );

    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        _exportingProgress.value = config.getFFmpegProgress(stats.getTime().toInt());
      },
      onError: (e, s) => _showErrorSnackBar("Error on export video :("),
      onCompleted: (file) {
        _isExporting.value = false;
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(video: file),
        );
      },
    );
  }

  void _exportCover() async {
    final config = CoverFFmpegVideoEditorConfig(_controller);
    final execute = await config.getExecuteConfig();
    if (execute == null) {
      _showErrorSnackBar("Error on cover exportation initialization.");
      return;
    }

    await ExportService.runFFmpegCommand(
      execute,
      onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
      onCompleted: (cover) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => CoverResultPopup(cover: cover),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                 // _topNavBar(),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: TabBarView(
                              physics:
                              const NeverScrollableScrollPhysics(),
                              children: [

                                CoverViewer(controller: _controller)
                              ],
                            ),
                          ),
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(top: 10),
                            child: Column(
                              children: [
                                TabBar(
                                  tabs: [
                                    Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: const [
                                          Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Icon(
                                                  Icons.content_cut)),
                                          Text('Trim')
                                        ]),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: const [
                                        Padding(
                                            padding: EdgeInsets.all(5),
                                            child:
                                            Icon(Icons.video_label)),
                                        Text('Cover')
                                      ],
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: _trimSlider(),
                                      ),
                                      _coverSelection(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: _isExporting,
                            builder: (_, bool export, Widget? child) =>
                                AnimatedSize(
                                  duration: kThemeAnimationDuration,
                                  child: export ? child : null,
                                ),
                            child: AlertDialog(
                              title: ValueListenableBuilder(
                                valueListenable: _exportingProgress,
                                builder: (_, double value, __) => Text(
                                  "Exporting video ${(value * 100).ceil()}%",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left),
                tooltip: 'Rotate unclockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right),
                tooltip: 'Rotate clockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => CropPage(controller: _controller),
                  ),
                ),
                icon: const Icon(Icons.crop),
                tooltip: 'Open crop screen',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: PopupMenuButton(
                tooltip: 'Open export menu',
                icon: const Icon(Icons.save),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: _exportCover,
                    child: const Text('Export cover'),
                  ),
                  PopupMenuItem(
                    onTap: _exportVideo,
                    child: const Text('Export video'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final int duration = _controller.videoDuration.inSeconds;
          final double pos = _controller.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              Text(formatter(Duration(seconds: pos.toInt()))),
              const Expanded(child: SizedBox()),
              AnimatedOpacity(
                opacity: _controller.isTrimming ? 1 : 0,
                duration: kThemeAnimationDuration,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatter(_controller.startTrim)),
                  const SizedBox(width: 10),
                  Text(formatter(_controller.endTrim)),
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
          controller: _controller,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }

  Widget _coverSelection() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _controller,
            size: height + 10,
            quantity: 8,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Editor with Thumbnails',
      home: VideoEditorPage(),
    );
  }
}

class VideoEditorPage extends StatefulWidget {
  @override
  _VideoEditorPageState createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  double startValue = 0.0; // Giá trị bắt đầu
  double endValue = 6.0; // Giá trị kết thúc
  double maxDuration = 6.0; // Thời gian video tối đa (giả lập)
  List<String?> thumbnails = []; // Danh sách đường dẫn thumbnail
  final String videoPath = 'assets/sample_video.mp4'; // Đường dẫn video

  @override
  void initState() {
    super.initState();
    _generateThumbnails();
  }

  // Tạo danh sách thumbnails từ video
  Future<void> _generateThumbnails() async {
    final tempDir = await getTemporaryDirectory();
    for (int i = 0; i < 20; i++) {
      // Lấy thumbnail tại các khung khác nhau
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        timeMs: (i * 300).toInt(), // Lấy mỗi 300ms
        quality: 50,
      );

      setState(() {
        thumbnails.add(thumbnailPath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Vùng hiển thị video/hình ảnh
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.grey[900],
                  child: Center(
                    child: Text(
                      'Video/Photo Preview',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thanh timeline (TrimSlider)
          Container(
            height: 150,
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hiển thị thumbnails
                Container(
                  height: 60,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: thumbnails.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 50,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: thumbnails[index] != null
                            ? Image.file(File(thumbnails[index]!))
                            : Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),

                // Thanh kéo chỉnh thời gian
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RangeSlider(
                    values: RangeValues(startValue, endValue),
                    min: 0.0,
                    max: maxDuration,
                    divisions: 60, // Số bước chia nhỏ
                    activeColor: Colors.orange,
                    inactiveColor: Colors.grey,
                    labels: RangeLabels(
                      startValue.toStringAsFixed(1),
                      endValue.toStringAsFixed(1),
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        startValue = values.start;
                        endValue = values.end;
                      });
                    },
                  ),
                ),

                // Hiển thị thời gian bắt đầu và kết thúc
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start: ${startValue.toStringAsFixed(1)}s',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'End: ${endValue.toStringAsFixed(1)}s',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Thanh công cụ
          Container(
            color: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () {
                    // Xử lý nút Delete
                  },
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    // Xử lý nút Edit
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


//////////
// if (controller != null)
// Column(
// children: [
// Row(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// IconButton(
// onPressed: () {
// setState(() {
// if (isPlaying) {
// controller!.video.pause();
// } else {
// controller!.video.play();
// }
// isPlaying = !isPlaying;
// });
// },
// icon: Icon(
// isPlaying ? Icons.pause : Icons.play_arrow,
// color: Colors.white,
// ))
// ],
// ),
// Expanded(
// child: Column(
// mainAxisAlignment: MainAxisAlignment.start,
// children: _trimSlider(),
// ),
// ),
// Row(
// children: [
// IconButton(
// onPressed: () {},
// icon: Icon(
// Icons.arrow_back_ios,
// color: Colors.white,
// )),
// IconButton(
// onPressed: () {},
// icon: Icon(Icons.delete, color: Colors.white)),
// IconButton(
// onPressed: () {
// Navigator.push(
// context,
// MaterialPageRoute(
// builder: (context) => CropScreen(file: file!)));
// },
// icon: Icon(Icons.cut, color: Colors.white))
// ],
// ),
// //_coverSelection()
// ],
// ),
