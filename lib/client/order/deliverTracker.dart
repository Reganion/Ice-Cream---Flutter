import 'package:flutter/material.dart';
import 'package:ice_cream/client/messages/messages.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DeliveryTrackerPage extends StatelessWidget {
  const DeliveryTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    const double mapTop = 30;
    const double mapHeight = 300;

    return Scaffold(
      body: Stack(
        children: [
          // Map background
          Positioned(
            top: mapTop,
            left: 0,
            right: 0,
            height: mapHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'lib/client/order/images/map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // X (close) button - top right of map
          Positioned(
            top: mapTop + 12,
            right: 18,
            child: _mapOverlayButton(
              icon: Icons.close,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          // + and - zoom buttons - bottom right of map
          Positioned(
            top: mapTop + mapHeight - 24 - 48 - 20 - 46,
            right: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapOverlayButton(icon: Icons.add, onTap: () {}),
                const SizedBox(height: 10),
                _mapOverlayButton(icon: Icons.remove, onTap: () {}),
              ],
            ),
          ),
          // Bottom sheet panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height:
                  MediaQuery.of(context).size.height * 0.58, // adjust height
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, // horizontal padding
                      vertical: 14, // keeps vertical spacing
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Your content here (same as your current Column)
                        Row(
                          children: const [
                            Text(
                              'Estimated on: 21 Nov, 12:30 PM',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          
                          ],
                        ),

                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF2F2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Symbols.deployed_code,
                                    size: 18,
                                    color: const Color(0xFF1C1B1F),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '#32456124',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Transaction ID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF575757),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7051C7),
                                minimumSize: const Size(
                                  93,
                                  30,
                                ), // <-- width, height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Driving',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // LEFT - Shipped By
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF1C1B1F),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Kyley Reganion',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            // CENTER - Order Cost
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 8,
                                  ), // moves only "Created:" left
                                  child: Text(
                                    'Order Cost',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1C1B1F),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '\$300.00',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: 28,
                                  ), // moves only "Created:" left
                                  child: Text(
                                    'Created',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1C1B1F),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '10/14/2025',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'Quantity:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF606060),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '3',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'Size:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF606060),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '3.5 Gal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'Flavor:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF606060),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Strawberry',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'Flavor cost:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF606060),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱1,700',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),
                               Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'Gallon cost:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF606060),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱200',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'Down payment:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF606060),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱500',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      'Contact number:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF606060),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '09785485214',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 9.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Message Driver button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ChatPage(phoneNumber: '09785485214'),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 55, // same as Check Out
                                  decoration: BoxDecoration(
                                    color: Colors.white, // white background
                                    borderRadius: BorderRadius.circular(
                                      35,
                                    ), // rounded corners
                                    border: Border.all(
                                      color: Color(0xFF8B8B8B),
                                    ), // border color
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Message Driver",
                                      style: TextStyle(
                                        color: Color(0xFF494949), // text color
                                        fontSize: 16, // same size as Check Out
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 13),

                            // Call icon button
                            Container(
                              height: 55, // same height as button
                              width:
                                  55, // slightly bigger circle like Check Out add icon
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Color(0xFF8B8B8B)),
                              ),
                              child: const Icon(
                                Icons.call, // updated icon
                                color: Color(0xFF494949),
                                size: 28, // same as add icon
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

Widget _mapOverlayButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.2),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF1C1B1F), size: 24),
      ),
    ),
  );
}
