import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ArchiveMessagesPage extends StatelessWidget {
  const ArchiveMessagesPage({super.key});

  static const List<_ArchivedMessage> _archivedMessages = [
    _ArchivedMessage(
      phoneNumber: '+63 9123456789',
      preview: 'Delivered: Order #1001 has been completed successfully.',
      time: '1 day ago',
      conversation: [
        _ArchiveConversationMessage(
          text: 'Good day! Ma’am I’m at your location.',
          time: '10:20 am',
          isDriver: true,
        ),
        _ArchiveConversationMessage(
          text: 'Please leave it by the gate, thank you.',
          time: '10:21 am',
          isDriver: false,
        ),
        _ArchiveConversationMessage(
          text: 'Delivered na po. Order #1001 completed.',
          time: '10:27 am',
          isDriver: true,
        ),
      ],
    ),
    _ArchivedMessage(
      phoneNumber: '+63 9987654321',
      preview: 'Delivered: Order #1002 received and confirmed.',
      time: '2 days ago',
      conversation: [
        _ArchiveConversationMessage(
          text: 'Arrived at drop-off point for Order #1002.',
          time: '1:05 pm',
          isDriver: true,
        ),
        _ArchiveConversationMessage(
          text: 'Received. Thank you!',
          time: '1:08 pm',
          isDriver: false,
        ),
      ],
    ),
    _ArchivedMessage(
      phoneNumber: '+63 9276543210',
      preview: 'Completed delivery for Order #1003. Thank you!',
      time: '3 days ago',
      conversation: [
        _ArchiveConversationMessage(
          text: 'On the way na po with your order.',
          time: '3:11 pm',
          isDriver: true,
        ),
        _ArchiveConversationMessage(
          text: 'Sige po, waiting outside.',
          time: '3:13 pm',
          isDriver: false,
        ),
        _ArchiveConversationMessage(
          text: 'Order #1003 delivered successfully.',
          time: '3:22 pm',
          isDriver: true,
        ),
      ],
    ),
    _ArchivedMessage(
      phoneNumber: '+63 9171234567',
      preview: 'Delivered: Order #1004 completed at customer location.',
      time: '4 days ago',
      conversation: [
        _ArchiveConversationMessage(
          text: 'Good afternoon! I’m near your address.',
          time: '4:40 pm',
          isDriver: true,
        ),
        _ArchiveConversationMessage(
          text: 'I’ll meet you at the lobby.',
          time: '4:41 pm',
          isDriver: false,
        ),
        _ArchiveConversationMessage(
          text: 'Thanks! Delivered and marked complete.',
          time: '4:47 pm',
          isDriver: true,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Symbols.arrow_back_ios,
                      size: 22,
                      weight: 400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Archived Messages',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _archivedMessages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = _archivedMessages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchiveChatPage(
                            phoneNumber: item.phoneNumber,
                            conversation: item.conversation,
                          ),
                        ),
                      );
                    },
                    child: _ArchiveMessageCard(
                      name: item.phoneNumber,
                      message: item.preview,
                      time: item.time,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveMessageCard extends StatelessWidget {
  const _ArchiveMessageCard({
    required this.name,
    required this.message,
    required this.time,
  });

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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE7EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.inventory_2,
              size: 22,
              color: Color(0xFFE3001B),
              fill: 1,
              weight: 600,
              grade: 200,
              opticalSize: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
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
                Positioned(
                  bottom: -3,
                  right: 0,
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
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

class _ArchivedMessage {
  const _ArchivedMessage({
    required this.phoneNumber,
    required this.preview,
    required this.time,
    required this.conversation,
  });

  final String phoneNumber;
  final String preview;
  final String time;
  final List<_ArchiveConversationMessage> conversation;
}

class _ArchiveConversationMessage {
  const _ArchiveConversationMessage({
    required this.text,
    required this.time,
    required this.isDriver,
  });

  final String text;
  final String time;
  final bool isDriver;
}

class ArchiveChatPage extends StatelessWidget {
  const ArchiveChatPage({
    super.key,
    required this.phoneNumber,
    required this.conversation,
  });

  final String phoneNumber;
  final List<_ArchiveConversationMessage> conversation;

  static const double avatarRadius = 22;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Symbols.arrow_back_ios,
                      size: 22,
                      weight: 400,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                        'Completed Delivery',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ListView.separated(
                  itemCount: conversation.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (_, index) {
                    final message = conversation[index];
                    return _ArchiveChatBubble(message: message);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 0,
                left: 20,
                right: 20,
                bottom: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(fontSize: 15),
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
    );
  }
}

class _ArchiveChatBubble extends StatelessWidget {
  const _ArchiveChatBubble({required this.message});

  final _ArchiveConversationMessage message;

  static const double avatarRadius = 22;

  @override
  Widget build(BuildContext context) {
    if (message.isDriver) {
      return Align(
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
                      color: const Color(0xFFE3001B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: (avatarRadius * 2) + 10),
              child: Text(
                message.time,
                style: const TextStyle(fontSize: 11, color: Color(0xFF1C1B1F)),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
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
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: (avatarRadius * 2) + 10),
            child: Text(
              message.time,
              style: const TextStyle(fontSize: 11, color: Color(0xFF1C1B1F)),
            ),
          ),
        ],
      ),
    );
  }
}
