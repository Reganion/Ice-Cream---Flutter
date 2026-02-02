import 'package:flutter/material.dart';
import 'package:ice_cream/client/favorite/favorite.dart';
import 'package:ice_cream/client/home_page.dart';
import 'package:ice_cream/client/order/all.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int selectedTab = 0; // 0 = Chats, 1 = Notifications

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      bottomNavigationBar: _bottomNavBar(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            // ---------------- TOP BAR ----------------
   Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "Messages",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      IconButton(
        icon: const Icon(
          Symbols.delete, // ✅ Material Symbols icon
          size: 25,
          color: Colors.black,

          // ✅ matches your CSS:
          fill: 0,
          weight: 200,
          grade: 200,
          opticalSize: 24,
        ),
        onPressed: () => _showDeleteAllModal(context),
      ),
    ],
  ),
),

            const SizedBox(height: 10),

            // ---------------- TABS ----------------
            Row(
              children: [
                const SizedBox(width: 20),

                // Chats tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedTab == 0
                            ? const Color(0xFFE3001B)
                            : const Color(0xFFFCE8E9), // inactive bg
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Chats",
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedTab == 0
                              ? Colors.white
                              : const Color(0xFF1C1B1F), // inactive text
                          fontWeight: selectedTab == 0
                              ? FontWeight.w400
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Notifications tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ), // add horizontal padding
                      decoration: BoxDecoration(
                        color: selectedTab == 1
                            ? const Color(0xFFE3001B)
                            : const Color(0xFFFCE8E9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Slightly left-shifted Text
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 10,
                              ), // moves text a bit to the left
                              child: Text(
                                "Notifications",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedTab == 1
                                      ? Colors.white
                                      : const Color(0xFF1C1B1F),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),

                          // Positioned Badge
                          Positioned(
                            right: -12,
                            child: Container(
                              width: 19, // smaller width
                              height: 19, // smaller height
                              decoration: BoxDecoration(
                                color: selectedTab == 1
                                    ? Colors.white
                                    : const Color(0xFFE3001B),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "1",
                                style: TextStyle(
                                  color: selectedTab == 1
                                      ? const Color(0xFFE3001B)
                                      : Colors.white,
                                  fontSize: 10, // smaller font
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (selectedTab == 0) ...[
                    // ----------------- CHATS -----------------
                    messageCard(
                      icon: Icons.support_agent,
                      name: "Chat Assistant",
                      message: "Yes! This is Available.",
                      time: "4 hours ago",
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ChatPage(phoneNumber: '+639123456789'),
                          ),
                        );
                      },
                      child: messageCard(
                        icon: Icons.person,
                        name: "+63 9123456789",
                        message: "Good day! Ma’am, I’m on at location.",
                        time: "5 hours ago",
                      ),
                    ),

                    const SizedBox(height: 10),
                    messageCard(
                      icon: Icons.person,
                      name: "+63 9123456789",
                      message: "Good day! Ma’am, I’m on at location.",
                      time: "5 hours ago",
                    ),
                    const SizedBox(height: 10),
                    messageCard(
                      icon: Icons.person,
                      name: "+63 9123456789",
                      message: "Good day! Ma’am, I’m on at location.",
                      time: "5 hours ago",
                    ),
                    const SizedBox(height: 10),
                    messageCard(
                      icon: Icons.person,
                      name: "+63 9123456789",
                      message:
                          "Good day! Ma’am, I’m on at location. Are you there?",
                      time: "5 hours ago",
                    ),
                    const SizedBox(height: 10),
                    messageCard(
                      icon: Icons.person,
                      name: "+63 9123456789",
                      message: "Good day! Ma’am, I’m on at location.",
                      time: "5 hours ago",
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    notificationCard(
                      message:
                          "Your order Strawberry has been successfully delivered.",
                      time: "1 minute ago",
                      isFirst: true,
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Mango Graham has been cancelled.",
                      time: "4 hours ago",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your personal has been updated.",
                      time: "4:15 pm",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Ube Cheese has been cancelled.",
                      time: "6 hours ago",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Mango Graham has been cancelled.",
                      time: "4 hours ago",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your personal has been updated.",
                      time: "4:15 pm",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Ube Cheese has been cancelled.",
                      time: "6 hours ago",
                    ),
                    const SizedBox(height: 13),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAllModal(BuildContext context) {
    // Determine the correct title based on active tab
    String title = selectedTab == 1
        ? "Delete all notifications?"
        : "Delete all messages?";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),

              const SizedBox(height: 5),

              // Subtitle
              const Text(
                "You can’t undo this later.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 30),

              // DELETE ALL button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Add your delete logic (messages or notifications)
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3001B),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Delete All",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // KEEP THEM button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Keep Them",
                    style: TextStyle(
                      color: Color(0xFF414141),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ---------------- BOTTOM NAV BAR ----------------
  Widget _bottomNavBar(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomIcon(
              icon: Symbols.home,
              label: "Home",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.local_mall,
              label: "Order",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.favorite,
              label: "Favorite",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritePage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.chat,
              label: "Messages",
              active: true,
              onTap: () {},
              fillColor: const Color(0xFFE3001B),
            ),
          ],
        ),
      ),
    );
  }

  Widget messageCard({
    required IconData icon,
    required String name,
    required String message,
    required String time,
  })

{
  // Determine icon, size, fill, and padding based on passed icon
  IconData displayedIcon;
  double iconSize;
  double containerPadding;

  // Material Symbols variations
  double iconFill;
  double iconWeight;
  double iconGrade;
  double iconOpticalSize;

  if (icon == Icons.person) {
    // ✅ Person in Material Symbols style (FILL 1, wght 700, GRAD 200, opsz 24)
    displayedIcon = Symbols.person;
    iconSize = 22;
    containerPadding = 14;

    iconFill = 1;
    iconWeight = 600;
    iconGrade = 200;
    iconOpticalSize = 24;
  } else {
    displayedIcon = Symbols.nest_mini;
    iconSize = 24;
    containerPadding = 12;

    // keep your other icon style (adjust if you want)
    iconFill = 1;
    iconWeight = 600;
    iconGrade = 0;
    iconOpticalSize = 24;
  }

  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-4, 0),
          child: Container(
            padding: EdgeInsets.all(containerPadding),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE7EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              displayedIcon,
              size: iconSize,
              color: const Color(0xFFE3001B),

              // ✅ Material Symbols variations (matches your CSS)
              fill: iconFill,
              weight: iconWeight,
              grade: iconGrade,
              opticalSize: iconOpticalSize,
            ),
          ),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: const Offset(0, -4),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C1B1F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -3,
                right: 0,
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget notificationCard({
    required String message,
    required String time,
    bool isFirst = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Transform.translate(
      offset: const Offset(-4, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE7EA),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Symbols.notifications_active,
          size: 22,
          color: Color(0xFFE3001B),

          // ✅ matches your CSS
          fill: 1,
          weight: 600,
          grade: 0,
          opticalSize: 24,
        ),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: SizedBox(
        height: 52,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C1B1F),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? fillColor; // New parameter for custom fill color

  const _BottomIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.fillColor, // Allow fillColor to be passed
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = active ? Color(0xFFE3001B) : const Color(0xFF969696);
    final double fillValue = (active && fillColor != null) ? 1 : 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: fillColor != null && active ? fillColor : iconColor,
              fill: fillValue,
              weight: 100,
              grade: 200,
              opticalSize: 24,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final String phoneNumber;
  const ChatPage({super.key, required this.phoneNumber});

  static const double avatarRadius = 22; // Match all to the AppBar avatar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // ✅ PAGE BACKGROUND
      // Custom AppBar moved lower below status bar, as if "appbar is part of the body" (not using Scaffold appBar)
      body: SafeArea(
        child: Column(
          children: [
            // Simulates the AppBar, but inside the body and further down.
            const SizedBox(
              height: 15,
            ), // Add extra space to move appbar further downward
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: IconButton(
                      icon: const Icon(
                        Symbols.arrow_back_ios,
                        size: 22,
                        weight: 400,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 0),
                  const CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Color(0xFFFFE5E5),
                    child: Icon(
                      Symbols.person,
                      color: Color(0xFFE3001B),
                      size: 21,
                      fill: 1, // ✅ filled
                      weight: 700, // ✅ bold
                    ),
                  ),

                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phoneNumber,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Unknown',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center, // ✅ avatar + bubble same line
                                  children: [
                                    const CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundColor: Color(0xFFFFE5E5),
                                      child: Icon(
                                        Symbols.person,
                                        color: Color(0xFFE3001B),
                                        size: 21,
                                        fill: 1, // ✅ filled
                                        weight: 700, // ✅ bold
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // ✅ bubble
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAEAEA),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          "Good day! Ma’am I’m at location.",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // ✅ time below bubble only (padded to start under bubble)
                                const SizedBox(height: 6),
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: (avatarRadius * 2) + 10,
                                  ), // avatar diameter + gap
                                  child: Text(
                                    "12:30 pm",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1C1B1F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE3001B),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          "Okay! On the way.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundColor: Color(0xFFFFE5E5),
                                      child: Icon(
                                        Symbols.person,
                                         color: Color(0xFFE3001B) ,
                                        size: 21,
                                        fill: 1, // ✅ filled
                                        weight: 700, // ✅ bold
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),
                                const Padding(
                                  padding: EdgeInsets.only(
                                    right: (avatarRadius * 2) + 10,
                                  ),
                                  child: Text(
                                    "12:31 pm",
                                    style: TextStyle(
                                      fontSize: 11,
                                       color: Color(0xFF1C1B1F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MESSAGE INPUT (moved up a little with bottom padding removed and top padding added)
                    Padding(
                      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: "Message",
                                hintStyle: const TextStyle(
                                  color: Color(0xFF464646),
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF1F1F1),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFE3001B),
                              child: Icon(
                                Symbols.send,
                                color: Colors.white,
                                size: 22,
                                weight: 600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
