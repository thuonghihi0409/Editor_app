import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PickerService {
  final ImagePicker _picker = ImagePicker();

  Future<List<String>> generateThumbnails(String videoPath, ) async {
    List<String> thumbnailPaths = [];
    Directory? directory = await getExternalStorageDirectory();
    for (int i = 0; i < 10; i++) {
      String thumbnailPath = '$directory/thumbnail_$i.jpg';
      String command = '-i $videoPath -vf "select=eq(n\\,$i)" -vframes 1 $thumbnailPath';
      await FFmpegKit.execute(command);
      thumbnailPaths.add(thumbnailPath);
    }
    return thumbnailPaths;
  }
  void requestStoragePermission() async {
    // Kiểm tra hệ điều hành và yêu cầu quyền tương ứng
    if (Platform.isAndroid) {
      // Kiểm tra nếu là Android 11 trở lên
      if (await Permission.manageExternalStorage.isGranted) {
        print("Quyền quản lý bộ nhớ đã được cấp");
      } else {
        var status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          print("Quyền quản lý bộ nhớ đã được cấp");
        } else if (status.isPermanentlyDenied) {
          // Nếu quyền bị từ chối vĩnh viễn, mở cài đặt
          openAppSettings();
        }
      }
    } else if (Platform.isIOS) {
      // Đối với iOS, yêu cầu quyền lưu trữ nếu cần
      if (await Permission.photos.request().isGranted) {
        print("Quyền truy cập vào thư viện ảnh đã được cấp");
      } else {
        print("Quyền truy cập vào thư viện ảnh bị từ chối");
      }
    }
  }

  Future<List<String>> pickMultipleFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp4'],
    );

    if (result != null) {
      log("${result.paths[0]}");
      return result.paths.where((path) => path != null).cast<String>().toList();
    } else {
      print('Người dùng đã không chọn tệp nào.');
      return [];
    }
  }

  Future<String> createVideoFromImages(List<String> filePaths) async {
    log("==================1");
    requestStoragePermission();

    Directory? directory = await getExternalStorageDirectory();
    log("==================1");
    if (directory == null) {
      print('Không thể truy cập thư mục bộ nhớ ngoài.');
      return "";
    }
    String outputPath = '${directory.path}/output_video.mp4';

    //String outputPath = '/data/user/0/com.example.editor_app/cache/file_picker/output_video.mp4';

    if (filePaths.isEmpty) {
      print('Danh sách tệp trống, không thể tạo video.');
      return "";
    }

    try {
      String inputs = filePaths.map((path) => '-i "$path"').join(' ');
      log("==================1");
      String command =
          '$inputs -filter_complex "[0:v:0]concat=n=${filePaths.length}:v=1:a=0[outv]" -map "[outv]" "$outputPath"';

      await FFmpegKit.execute(command);
      print('Video đã được tạo tại: $outputPath');

      return outputPath;
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
}
