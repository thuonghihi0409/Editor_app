import 'dart:io';

import 'package:flutter/material.dart';

class Timeline extends StatefulWidget {
  final List<String> thumbnails;
  const Timeline({super.key, required this.thumbnails});

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.thumbnails.length,
        itemBuilder: (context, index) {
          return Container(
            width: 50,
            margin: EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              border:
              Border.all(color: Colors.white, width: 1),
            ),
            child: widget.thumbnails[index] != null
                ? Image.file(File(widget.thumbnails[index]!))
                : Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
