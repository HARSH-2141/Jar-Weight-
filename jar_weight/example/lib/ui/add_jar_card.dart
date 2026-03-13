import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class AddJarCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddJarCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: Colors.grey.shade400,
        strokeWidth: 1.5,
        dashPattern: [4, 2], // dash length, space length
        borderType: BorderType.RRect,
        radius:  Radius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color:  Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:  [
                Icon(
                  Icons.add_circle_rounded,
                  color: Color(0xFFCACACA),
                  size: 30,
                ),
                SizedBox(height: 10),
                Text(
                  "Add Jar",
                  style: TextStyle(
                    color: Color(0xFFCACACA),
                    fontSize: 16,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
