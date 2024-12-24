
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTextSheet extends StatefulWidget {
  AddTextSheet({super.key});

  @override
  State<AddTextSheet> createState() => _AddTextSheetState();
}
class _AddTextSheetState extends State<AddTextSheet> {
  final List<String> googleFontFamilies = GoogleFonts.asMap().keys.toList();
  final _textControllor = TextEditingController();
  Color colorText = Colors.white;
  String text="";
  String selectionFont ="";
  @override
  void initState() {
    // TODO: implement initState
    selectionFont=googleFontFamilies[0];
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(20),
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 ColorIndicator(
                   onSelectFocus: true,
                   color: colorText,
                   onSelect: () async {
                     final Color pickedColor = await showColorPickerDialog(
                       context,
                       colorText,
                       showColorCode: false,
                       showColorName: false,
                       pickersEnabled: const <ColorPickerType, bool>{
                         ColorPickerType.primary: false,
                         ColorPickerType.wheel: true,
                         ColorPickerType.accent: false,
                         ColorPickerType.custom: false,
                       },
                       width: 40,
                       height: 40,
                       borderRadius: 10,
                       spacing: 10,
                       runSpacing: 10,
                       wheelDiameter: 190,
                       enableOpacity: true,
                     );

                     if (pickedColor != null) {
                       setState(() {
                         colorText = pickedColor;
                       });
                     }
                   },
                 ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Done",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ],
              ),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        softWrap: true,
                        style: GoogleFonts.getFont(selectionFont, color: colorText, fontSize: 30),
                  
                      ),
                    ],
                  ),
                ),
              ),
              _ListFonts(),
              SizedBox(height: 10,),
              Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[800],
                  ),
                  child: TextField(
                      controller: _textControllor,
                      onChanged: (text1){
                        setState(() {
                          text=_textControllor.text;
                        });

                      },

                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Add text",
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.only(left: 20, top: 5, bottom: 5, right: 20),
                      )))
            ],
          ),
        ),
      ),
    );
  }

  Widget _ListFonts() {
    return Container(
      height: 35,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: googleFontFamilies.length <= 10
                  ? googleFontFamilies.length
                  : 10,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    _FontItemWidgets(index),
                    SizedBox(
                      width: 10,
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _FontItemWidgets(int index) {
    return InkWell(
      child: Container(
        width: 60,
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: selectionFont.contains(googleFontFamilies[index])
              ? Border.all(width: 1, color: Colors.grey)
              : Border.all(width: 0),
          color: Colors.grey[800],
        ),
        child: Center(
          child: Text(
            "Aa",
            style: GoogleFonts.getFont(googleFontFamilies[index],
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
      onTap: () {
        setState(() {
          selectionFont = googleFontFamilies[index];
        });
      },
    );
  }
}
