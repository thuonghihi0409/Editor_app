import 'dart:io';

class Media {
  final File file;
  final int end;
  final int start;
  final List<File> images;
  Media( {required this.images,required this.file, required this.end, required this.start});

}