import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/jar_model.dart';
import '../storage/jar_storage.dart';
import '../utils/colors.dart';

class AlertsExpiryScreen extends StatefulWidget {
  const AlertsExpiryScreen({super.key});

  @override
  State<AlertsExpiryScreen> createState() => _AlertsExpiryScreenState();
}

class _AlertsExpiryScreenState extends State<AlertsExpiryScreen> {
  bool isLoading = true;
  int _selectedTabIndex = 0; // 0 for Alert (Low Stock), 1 for Expiry

  // We now have TWO separate lists to hold our UI widgets
  List<Widget> lowStockWidgets = [];
  List<Widget> expiryWidgets = [];

  @override
  void initState() {
    super.initState();
    _loadRealTimeAlerts();
  }

  Future<void> _loadRealTimeAlerts() async {
    List<JarModel> allJars = await JarStorage.getJars();

    List<Widget> tempLowStock = [];
    List<Widget> tempExpiry = [];

    DateTime today = DateTime.now();
    DateTime cleanToday = DateTime(today.year, today.month, today.day);

    for (var jar in allJars) {
      // -----------------------------------------
      // 1. EXPIRY MATH (Warn if <= 3 days left)
      // -----------------------------------------
      try {
        DateTime expiry = DateFormat('dd MMM yyyy').parse(jar.expiryDate);
        int daysLeft = expiry.difference(cleanToday).inDays;

        if (daysLeft <= 3) {
          String expiryText;
          if (daysLeft < 0) {
            expiryText = "${jar.name} expired ${daysLeft.abs()} days ago";
          } else if (daysLeft == 0) {
            expiryText = "${jar.name} expires today!";
          } else {
            expiryText = "${jar.name} expires in $daysLeft days";
          }

          tempExpiry.add(_buildExpiryRow(jar.name, expiryText));
          // Add a divider after every item for clean design
          tempExpiry.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, color: Color(0xFFC0C0C0)),
          ));
        }
      } catch (e) {
        debugPrint("Date parse error for ${jar.name}");
      }
      // -----------------------------------------
      // 2. LOW STOCK MATH (Warn if <= 25%)
      // -----------------------------------------
      double percent = (jar.currentWeight / jar.capacity).clamp(0.0, 1.0);

      if (percent <= 0.25) {
        int gramsLeft = (jar.currentWeight * 1000).toInt();

        tempLowStock.add(
            _buildLowStockRow(jar.name, "${jar.name} is running low", "(Only ${gramsLeft}g left)")
        );
        // Add a divider after every item
        tempLowStock.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Divider(height: 1, color: Color(0xFFC0C0C0)),
        ));
      }
    }

    if (tempLowStock.isNotEmpty) tempLowStock.removeLast();
    if (tempExpiry.isNotEmpty) tempExpiry.removeLast();

    setState(() {
      lowStockWidgets = tempLowStock;
      expiryWidgets = tempExpiry;
      isLoading = false;
    });
  }

  /// 🔴 UI Builder for Expiry
  Widget _buildExpiryRow(String itemName, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error, color: Color(0xFFE54245), size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Expiry Alert:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2F3E46)),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 15, color: Color(0xFF2F3E46)),
              ),
              const SizedBox(height: 4),
              const Text(
                "(Restock Needed)",
                style: TextStyle(fontSize: 15, color: Color(0xFF2F3E46)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🟠 UI Builder for Low Stock
  Widget _buildLowStockRow(String itemName, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_rounded, color: Color(0xFFFDB532), size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Low Stock:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2F3E46)),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 15, color: Color(0xFF2F3E46)),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 15, color: Color(0xFF2F3E46)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // A helper function to build the empty state based on which tab is open
  Widget _buildEmptyState() {
    bool isAlertTab = _selectedTabIndex == 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green.shade50,
            child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            "All Good!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2F3E46)),
          ),
          const SizedBox(height: 10),
          Text(
            isAlertTab
                ? "Your pantry is fully stocked.\nNo items are running low!"
                : "Nothing is expiring soon.\nGreat job reducing food waste!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    // Decide which list to show based on the toggle bar
    List<Widget> currentList = _selectedTabIndex == 0 ? lowStockWidgets : expiryWidgets;

    return Scaffold(
      backgroundColor: ColorString.BACKGROUND_COLOR,
      appBar: AppBar(
        toolbarHeight: height / 9,
        backgroundColor: ColorString.APP_BAR_COLOR,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          "Alerts & Expiry",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F7A63)))
          : Column(
        children: [
          const SizedBox(height: 20),

          /// ================= THE TOGGLE BAR =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomToggleBar(
              onTabChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          /// ================= THE DYNAMIC LIST =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: currentList.isEmpty
                  ? _buildEmptyState()
                  : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: currentList,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==============================================================
/// THE CUSTOM TOGGLE BAR WIDGET (Built right into this file!)
/// ==============================================================
class CustomToggleBar extends StatefulWidget {
  final Function(int) onTabChanged;

  const CustomToggleBar({super.key, required this.onTabChanged});

  @override
  State<CustomToggleBar> createState() => _CustomToggleBarState();
}

class _CustomToggleBarState extends State<CustomToggleBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF2F3E46),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(0, "Low Stock"),
          _buildTab(1, "Expiry"),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          widget.onTabChanged(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4E6772) : Colors.transparent, // The bright blue!
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade400,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}