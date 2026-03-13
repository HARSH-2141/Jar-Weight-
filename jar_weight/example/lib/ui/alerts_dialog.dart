import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../model/jar_model.dart'; // Ensure this path is correct

class AlertsDialog extends StatelessWidget {
  final JarModel jar;

  const AlertsDialog({super.key, required this.jar});

  @override
  Widget build(BuildContext context) {

    // Calculate Expiry
    DateTime today = DateTime.now();
    DateTime cleanToday = DateTime(today.year, today.month, today.day);
    DateTime expiryDate;
    try {
      expiryDate = DateFormat('dd MMM yyyy').parse(jar.expiryDate);
    } catch (e) {
      expiryDate = cleanToday; // Fallback
    }
    int daysLeft = expiryDate.difference(cleanToday).inDays;

    // Calculate Weight Percentage
    double percent = (jar.currentWeight / jar.capacity).clamp(0.0, 1.0);
    int gramsLeft = (jar.currentWeight * 1000).toInt();

    // Weight Logic
    Color weightColor;
    String weightText;
    if (percent <= 0.25) {
      weightColor = const Color(0xFFE54245); // Red
      weightText = "Low - ${gramsLeft}g";
    } else if (percent < 0.60) {
      weightColor = const Color(0xFFFDB532); // Yellow
      weightText = "Half - ${gramsLeft}g";
    } else {
      weightColor = const Color(0xFF3CB340); // Green
      weightText = "Full - ${jar.currentWeight.toStringAsFixed(1)} Kg";
    }

    // Expiry Logic
    Color expiryColor;
    String expiryText;
    IconData expiryIcon;
    if (daysLeft <= 3) {
      expiryColor = const Color(0xFFE54245); // Red
      expiryText = daysLeft <= 0 ? "Expired" : "Expires in $daysLeft days";
      expiryIcon = Icons.warning_rounded;
    } else if (daysLeft <= 7) {
      expiryColor = const Color(0xFFFDB532); // Yellow
      expiryText = "Expires in $daysLeft days";
      expiryIcon = Icons.warning_rounded;
    } else {
      expiryColor = const Color(0xFF3CB340); // Green
      expiryText = "Fresh - $daysLeft days";
      expiryIcon = Icons.calendar_month_rounded;
    }

    Color overallColor;
    IconData topIcon;
    String footerText;

    if (weightColor == const Color(0xFFE54245) ||
        expiryColor == const Color(0xFFE54245)) {
      overallColor = const Color(0xFFE54245);
      topIcon = Icons.error;
      footerText = expiryColor == const Color(0xFFE54245)
          ? "Expiry Alert"
          : "Replace Soon";
    } else if (weightColor == const Color(0xFFFDB532) ||
        expiryColor == const Color(0xFFFDB532)) {
      overallColor = const Color(0xFFFDB532);
      topIcon = Icons.error;
      footerText = "Running Low";
    } else {
      overallColor = const Color(0xFF3CB340);
      topIcon = Icons.check_circle;
      footerText = "All Good";
    }

    // 👇 We use Center instead of Dialog to bypass Flutter's forced minimum width!
    return Center(
      child: Material(
        color: Colors.transparent, // Keeps the background clear
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),

            // border: Border.all(color: overallColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: overallColor.withOpacity(0.4), // Slightly darker so it pops
                blurRadius: 10, // How soft the shadow is
                spreadRadius: -4, // 👈 THE TRICK: Pulls the shadow inward on all sides!
                offset: const Offset(0, 10), // 👈 Pushes the shadow straight down out of the bottom!
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP ROW: Title & Status Icon ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      jar.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F3E46),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(topIcon, color: overallColor, size: 24),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFFEFEFEF), thickness: 1),
              ),

              Row(
                children: [
                  FaIcon(FontAwesomeIcons.weightHanging, color: weightColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: weightText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: weightColor,
                            ),
                          ),
                          const TextSpan(
                            text: " left",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFFEFEFEF), thickness: 1),
              ),

              // --- BOTTOM ROW: Expiry Details ---
              Row(
                children: [
                  Icon(expiryIcon, color: expiryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expiryText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2F3E46),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- FOOTER TEXT ---
              Center(
                child: Text(
                  footerText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: overallColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}