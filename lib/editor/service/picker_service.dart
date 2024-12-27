import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
class PickerService {
  final ImagePicker _picker = ImagePicker();
  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Bỏ qua việc kiểm tra phiên bản SDK, luôn yêu cầu quyền storage cho Android
      if (await Permission.storage.isGranted) {
        print("Quyền lưu trữ đã được cấp.");
      } else {
        var status = await Permission.storage.request();
        if (status.isPermanentlyDenied) openAppSettings();
      }
    }
  }
  Future<List<String>> pickMultipleFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpeg','png', 'mp4'],
    );
    if (result != null) {
      log("${result.paths[0]}");
      return result.paths.whereType<String>().toList();
    } else {
      print('Người dùng đã không chọn tệp nào.');
      return [];
    }
  }

  Future<String> createVideoFromImages(List<String> filePaths) async {
    // Yêu cầu quyền truy cập bộ nhớ trước khi thực thi
    await requestStoragePermission();

    // Lấy thư mục Documents
    Directory directory = await getApplicationDocumentsDirectory();
    String outputPath = '${directory.path}/output_video.mp4';

    // Kiểm tra danh sách tệp
    if (filePaths.isEmpty) {
      print('Danh sách tệp trống, không thể tạo video.');
      return "";
    }

    try {
      // Xây dựng câu lệnh FFmpeg
      // Chúng ta sẽ đồng bộ hóa tất cả hình ảnh về cùng kích thước, ví dụ 1920x1080
      String inputs = filePaths.map((path) => '-i "$path"').join(' ');
      String filterComplex = filePaths
          .asMap()
          .map((index, path) =>
          MapEntry(index, '[${index}:v]scale=1920:1080,setdar=16/9[v$index]'))
          .values
          .join(';');

      // Câu lệnh FFmpeg
      String command =
          '$inputs -filter_complex "$filterComplex;[v0][v1]concat=n=${filePaths.length}:v=1:a=0[outv]" -map "[outv]" -c:v libx264 -preset fast -crf 23 "$outputPath"';

      // In câu lệnh để kiểm tra
      print('Câu lệnh FFmpeg: $command');

      // Thực thi câu lệnh FFmpeg
      final result = await FFmpegKit.execute(command);
      final returnCode = await result.getReturnCode();

      if (returnCode!.isValueSuccess()) {
        print('Video đã được tạo tại: $outputPath');
        return outputPath;
      } else {
        print('Lỗi khi tạo video.');
        return "";
      }
    } catch (e) {
      print('Lỗi khi tạo video: $e');
      return "";
    }
  }


  Future<String> captureImageFromCamera() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      return pickedFile.path;
    }
    return "";
  }

  Future<String> captureVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      return video.path;
    }
    return "";
  }

  Future<List<String>> generateThumbnails(String videoPath) async {
    List<String> thumbnailPaths = [];
    Directory directory = await getApplicationDocumentsDirectory();
    var duration = await FFmpegKit.execute('-i $videoPath');
    for (int i = 0; i < 10; i++) {
      String thumbnailPath = '${directory.path}/thumbnail_$i.jpg';
      double timestamp = i * (20 / 10);

      String command = '-ss ${timestamp} -i $videoPath -vframes 1 -q:v 2 $thumbnailPath';
      await FFmpegKit.execute(command);

      thumbnailPaths.add(thumbnailPath);
    }
    return thumbnailPaths;
  }


}
