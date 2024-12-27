
List<TimelineBlock> timeline = [
  TimelineBlock(start: 0, end: 2, content: 'hello',),
  TimelineBlock(start: 2, end: 4, content: 'xin chào',),
];

class TimelineBlock {
  double start;
  double end;
  String content;
  TimelineBlock({required this.start, required this.end, required this.content,});
}
