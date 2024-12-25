import 'package:editor_app/editor/screen/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}




// import 'dart:io';
//
// import 'package:editor_app/editor/widgets/video_player_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_editor/video_editor.dart';
//
// void main() => runApp(
//   MaterialApp(
//     title: 'Flutter Video Editor Demo',
//     debugShowCheckedModeBanner: false,
//     theme: ThemeData(
//       primarySwatch: Colors.grey,
//       brightness: Brightness.dark,
//       tabBarTheme: const TabBarTheme(
//         indicator: UnderlineTabIndicator(
//           borderSide: BorderSide(color: Colors.white),
//         ),
//       ),
//       dividerColor: Colors.white,
//     ),
//     home: const VideoEditorExample(),
//   ),
// );
//
// class VideoEditorExample extends StatefulWidget {
//   const VideoEditorExample({super.key});
//
//   @override
//   State<VideoEditorExample> createState() => _VideoEditorExampleState();
// }
//
// class _VideoEditorExampleState extends State<VideoEditorExample> {
//   final ImagePicker _picker = ImagePicker();
//
//   void _pickVideo() async {
//     final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
//
//     if (mounted && file != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute<void>(
//           builder: (BuildContext context) => VideoEditor(file: File(file.path)),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Video Picker")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text("Click on the button to select video"),
//             ElevatedButton(
//               onPressed: _pickVideo,
//               child: const Text("Pick Video From Gallery"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }