import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'archive_messages.dart';

class messagesPage extends StatelessWidget {
  const messagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar
            Container(
              color: Color(0xFFFAFAFA),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    "Messages",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArchiveMessagesPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Symbols.archive,
                        size: 22,
                        color: Color(0xFF1C1B1F),
                        fill: 0,
                        weight: 600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable message cards (like client messages.dart)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(phoneNumber: "+63 9123456789"),
                        ),
                      );
                    },
                    child: const _MessageCard(
                      icon: Symbols.person,
                      name: "+63 9123456789",
                      message: "Good day! Ma'am, I'm on at location.",
                      time: "5 hours ago",
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(phoneNumber: "+63 9123456789"),
                        ),
                      );
                    },
                    child: const _MessageCard(
                      icon: Symbols.person,
                      name: "+63 9123456789",
                      message: "Good day! Ma'am, I'm on at location.",
                      time: "5 hours ago",
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(phoneNumber: "+63 9123456789"),
                        ),
                      );
                    },
                    child: const _MessageCard(
                      icon: Symbols.person,
                      name: "+63 9123456789",
                      message: "Good day! Ma'am, I'm on at location. Are you there?",
                      time: "5 hours ago",
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(phoneNumber: "+63 9123456789"),
                        ),
                      );
                    },
                    child: const _MessageCard(
                      icon: Symbols.person,
                      name: "+63 9123456789",
                      message: "Good day! Ma'am, I'm on at location.",
                      time: "5 hours ago",
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showDeleteAllMessagesModal(BuildContext context) {
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
              const Text(
                "Delete all messages?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "You can't undo this later.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // TODO: clear all messages
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
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.name,
    required this.message,
    required this.time,
  });

  final IconData icon;
  final String name;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE7EA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFFE3001B),
                fill: 1,
                weight: 600,
                grade: 200,
                opticalSize: 24,
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
                    style: const TextStyle(fontSize: 12,  color: Color(0xFF616161)),
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
                          // Top: driver's message (red, right) — 12:30 pm
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center, // ✅ avatar + bubble same line
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE3001B),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          "Good day! Ma’am I’m at location.",
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
                                        color: Color(0xFFE3001B),
                                        size: 21,
                                        fill: 1,
                                        weight: 700,
                                      ),
                                    ),
                                  ],
                                ),

                                // ✅ time below bubble only (padded to start under bubble)
                                const SizedBox(height: 6),
                                const Padding(
                                  padding: EdgeInsets.only(
                                    right: (avatarRadius * 2) + 10,
                                  ),
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

                          // Bottom: other person's message (gray, left) — 12:31 pm
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundColor: Color(0xFFFFE5E5),
                                      child: Icon(
                                        Symbols.person,
                                        color: Color(0xFFE3001B),
                                        size: 21,
                                        fill: 1,
                                        weight: 700,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAEAEA),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          "Okay! On the way.",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: (avatarRadius * 2) + 10,
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
