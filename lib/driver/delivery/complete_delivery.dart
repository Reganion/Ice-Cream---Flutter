import 'package:flutter/material.dart';
import 'package:ice_cream/driver/delivery/cd_photo.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CompleteDeliveryPage extends StatefulWidget {
  const CompleteDeliveryPage({super.key});

  @override
  State<CompleteDeliveryPage> createState() => _CompleteDeliveryPageState();
}

class _CompleteDeliveryPageState extends State<CompleteDeliveryPage> {
  bool _forceShowFullCard = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetSizeChange);
  }

  void _onSheetSizeChange() {
    if (mounted) {
      if (_sheetController.isAttached && _sheetController.size > 0.2) {
        _forceShowFullCard = false;
      }
      setState(() {});
    }
  }

  void _expandSheet() {
    setState(() => _forceShowFullCard = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        0.74,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _collapseSheet() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final minSize = isLandscape ? 0.18 : 0.11;
    setState(() => _forceShowFullCard = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        minSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openTakePhotoFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const CompleteDeliveryPhotoPage(),
      ),
    );
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChange);
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, 18),
              child: Image.asset(
                'lib/client/order/images/map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 13,
            child: Material(
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Symbols.arrow_back,
                    size: 24,
                    color: Color(0xFF414141),
                    fill: 1,
                    weight: 200,
                    grade: 200,
                    opticalSize: 24,
                  ),
                ),
              ),
            ),
          ),

       DraggableScrollableSheet(
  controller: _sheetController,
  // ✅ FIX: landscape needs a taller collapsed height
  minChildSize: MediaQuery.of(context).orientation == Orientation.landscape ? 0.18 : 0.11,
  initialChildSize: 0.74,
  maxChildSize: 0.74,
  builder: (context, scrollController) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final minSize = isLandscape ? 0.18 : 0.11;
    final isCompact = !isLandscape && MediaQuery.of(context).size.height < 760;
    final detailsHorizontalPadding = screenWidth < 360 ? 12.0 : screenWidth < 420 ? 14.0 : 16.0;
    final detailsVerticalPadding = screenWidth < 360 ? 10.0 : isCompact ? 12.0 : 14.0;
    final detailsRadius = screenWidth < 360 ? 14.0 : 16.0;

    // ✅ FIX: collapsed detection based on actual min size (prevents weird states)
    final isCollapsed = _sheetController.isAttached &&
        _sheetController.size <= (minSize + 0.02);

    final showFullCard = !isCollapsed || _forceShowFullCard;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        top: false,
        // ✅ keeps content above system gesture bar in landscape
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment:
              isCollapsed ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // ✅ FIX: make handle tighter (and optional in collapsed to save height)
            if (!isCollapsed)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _collapseSheet,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: EdgeInsets.only(top: isCompact ? 8 : 12, bottom: isCompact ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D0D0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: isCompact ? 4 : 6),

            // Compact bar: only visible when collapsed
            if (isCollapsed)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 2, 20, isCompact ? 6 : 8), // ✅ add a tiny bottom padding
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ACLC College of Mandaue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // ✅ avoids overflow in narrow landscape
                            style: TextStyle(
                              fontSize: isCompact ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1B1F),
                            ),
                          ),
                          const SizedBox(height: 2), // ✅ tighter
                          Text(
                            '30 km   20 min',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 13 : 14,
                              color: Color(0xFF606060),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.black, width: 1),
                      ),
                      elevation: 1,
                      child: InkWell(
                        onTap: _expandSheet,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: EdgeInsets.all(isCompact ? 5 : 6),
                          child: Icon(
                            Symbols.keyboard_arrow_up_rounded,
                            size: isCompact ? 30 : 34,
                            color: const Color(0xFF1C1B1F),
                            fill: 1,
                            weight: 100,
                            grade: 200,
                            opticalSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (showFullCard)
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                        padding: EdgeInsets.fromLTRB(20, 0, 20, isCompact ? 10 : 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expected on: 21 Nov, 12:30 pm',
                      style: TextStyle(
                        fontSize: isCompact ? 21 : 23,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1B1F),
                      ),
                    ),

                    SizedBox(height: isCompact ? 4 : 6),

                    // ✅ METRICS (EXACT: 3 columns in one row)
                    Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: _CompleteMetricItem(
                            icon: Symbols.deployed_code,
                            value: '#32456124',
                            label: 'Transaction ID',
                            alignCenter: false,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: _CompleteMetricItem(
                            value: '30 km',
                            label: 'Distance',
                            alignCenter: false,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: _CompleteMetricItem(
                            value: '20 min',
                            label: 'Travel time',
                            alignCenter: false,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isCompact ? 8 : 11),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
                    SizedBox(height: isCompact ? 8 : 11),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: isCompact ? 15 : 16,
                                  color: const Color(0xFF606060),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                'Pyang Generalao',
                                style: TextStyle(
                                  fontSize: isCompact ? 17 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1B1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isCompact ? 8 : 10),
                        const _CompleteActionIconButton(icon: Symbols.chat_bubble),
                        SizedBox(width: isCompact ? 8 : 10),
                        const _CompleteActionIconButton(icon: Symbols.call),
                      ],
                    ),

                    SizedBox(height: isCompact ? 8 : 12),

                    Text(
                      'Delivery address:',
                      style: TextStyle(
                        fontSize: isCompact ? 15.5 : 16.5,
                        color: const Color(0xFF606060),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    Text(
                      'ACLC College of Mandaue, Briones St., Maguikay, Mandaue City, Cebu',
                      style: TextStyle(
                        fontSize: isCompact ? 17 : 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1B1F),
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: isCompact ? 8 : 12),

                    // Order details card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: detailsHorizontalPadding,
                        vertical: detailsVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(detailsRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _CompleteOrderRow(label: 'Quantity:', value: '1'),
                          _CompleteOrderRow(label: 'Size:', value: '2 Gal'),
                          _CompleteOrderRow(label: 'Order:', value: 'Strawberry'),
                          _CompleteOrderRow(label: 'Order Type:', value: 'Special Flavor'),
                          _CompleteOrderRow(label: 'Cost:', value: '₱1,900'),
                          _CompleteOrderRow(label: 'Down Payment:', value: '₱500'),
                          _CompleteOrderRow(label: 'Balance:', value: '₱1,400'),
                          _CompleteOrderRow(label: 'Customer Number:', value: '09123456789'),
                        ],
                      ),
                    ),

                    SizedBox(height: isCompact ? 12 : 17),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _openTakePhotoFlow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00AE2A),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: isCompact ? 13 : 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Complete delivery',
                                    style: TextStyle(
                                      fontSize: isCompact ? 15 : 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
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
  },
),


          if (_sheetController.isAttached && _sheetController.size <= 0.2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _expandSheet,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompleteMetricItem extends StatelessWidget {
  final IconData? icon;
  final String value;
  final String label;
  final bool alignCenter;

  const _CompleteMetricItem({
    this.icon,
    required this.value,
    required this.label,
    required this.alignCenter,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 760;

    if (icon != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 32 : 36,
            height: isCompact ? 32 : 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: isCompact ? 16 : 18, color: const Color(0xFF1C1B1F)),
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 17 : 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1B1F),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 0),
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 15,
                  color: Color(0xFF575757),
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isCompact ? 16 : 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1B1F),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 0),
        Text(
          label,
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            color: Color(0xFF8B8B8B),
            fontWeight: FontWeight.w400,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _CompleteOrderRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompleteOrderRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 760;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 4 : 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 13.5 : 14.5,
                color: const Color(0xFF7A7A7A),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: isCompact ? 13.5 : 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1B1F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteActionIconButton extends StatelessWidget {
  final IconData icon;

  const _CompleteActionIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 760;

    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.black, width: 1),
      ),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: isCompact ? 44 : 48,
          height: isCompact ? 44 : 48,
          child: Icon(
            icon,
            size: isCompact ? 20 : 22,
            color: const Color(0xFF1C1B1F),
            fill: 1,
            weight: 300,
            grade: 200,
            opticalSize: 24,
          ),
        ),
      ),
    );
  }
}
