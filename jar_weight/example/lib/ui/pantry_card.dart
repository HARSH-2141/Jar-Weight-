import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PantryCard extends StatelessWidget {
  final String title;
  final String weight;
  final double percent;
  final int expiryDays;

  const PantryCard({
    super.key,
    required this.title,
    required this.weight,
    required this.percent,
    required this.expiryDays,
  });

  /// Main Color Logic
  Color getMainColor() {
    if (percent <= 0.3) {
      return const Color(0xFFE54245);
    } else if (percent <= 0.60) {
      return const Color(0xFFFDB532);
    } else {
      return const Color(0xFF3CB340);
    }
  }

  /// Light Background Color
  Color getLightColor() {
    if (percent <= 0.3) {
      return const Color(0xFFFFE6E7);
    } else if (percent <= 0.60) {
      return const Color(0xFFFFF2DB);
    } else {
      return const Color(0xFFDEFFDF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = getMainColor();
    final lightColor = getLightColor();

    // 👇 1. Clean logic to figure out the exact expiry text!
    String getExpiryText() {
      if (expiryDays < 0) return "Expired";
      if (expiryDays == 0) return "Expires today"; // The fix!
      if (expiryDays < 7) return "Expires in $expiryDays days";
      return "All Good";
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFCACACA),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0xFFCACACA),
            blurRadius: 1,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Percentage
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      weight,
                      style: const TextStyle(
                        color: Color(0xFF2F3E46),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Container(
                  height: 20,
                  width: 45,
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      "${(percent * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Progress Bar (Dynamic Color)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(mainColor),
            ),
          ),

          const Spacer(),

          /// Expiry Box (Color depends on expiry)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // Simplified the color logic here too!
              color: expiryDays < 7
                  ? const Color(0xFFFFE6E7) // expired or expiring soon (includes 0)
                  : const Color(0xFFDEFFDF), // safe
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (expiryDays < 7)
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 14,
                  ),

                if (expiryDays < 7) const SizedBox(width: 3),

                Expanded(
                  child: Center(
                    child: Text(
                      getExpiryText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2F3E46),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}