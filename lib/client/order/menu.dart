import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:ice_cream/client/order/cart.dart';
import 'package:ice_cream/client/order/deliverTracker.dart';
import 'package:ice_cream/client/order/gcash.dart';
import 'package:ice_cream/client/order/manage_address.dart';
import 'package:intl/intl.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    this.initialFlavorName,
    this.initialItemIndex,
    this.initialDisplayName,
  });

  /// When set, opens the product detail for the item at this index in [items].
  final int? initialItemIndex;
  final String? initialFlavorName;
  /// When set, this name is shown as the product title on the detail page (e.g. from Popular slideshow).
  final String? initialDisplayName;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  Map<String, dynamic>? selectedItem;
  String selectedSize = "";
  String selectedCategory = "Plain Flavors"; // default selected
  int quantity = 0;
  String searchQuery = "";

  /// Real data from API (flavors + gallons). When set, grid and detail use these.
  List<Map<String, dynamic>>? _apiFlavors;
  List<Map<String, dynamic>>? _apiGallons;
  bool _loadingMenu = true;

  /// Cart total quantity (sum of all item quantities). Fetched from API for badge.
  int _cartCount = 0;
  AnimationController? _addBtnController;
  AnimationController? _cartBounceController;
  AnimationController? _flyController;
  Animation<double>? _addBtnScale;
  Animation<double>? _cartBounceScale;

  /// Keys to get positions for fly-to-cart animation.
  final GlobalKey _addBtnKey = GlobalKey();
  final GlobalKey _cartIconKey = GlobalKey();
  OverlayEntry? _flyOverlayEntry;

  // Big image auto slideshow (detail view)
  final PageController _bigImageController = PageController();
  Timer? _bigImageTimer;
  int _bigImageIndex = 0;
  int _bigImageCount = 0;

  void _stopBigImageAutoSlide() {
    _bigImageTimer?.cancel();
    _bigImageTimer = null;
  }

  void _startBigImageAutoSlide({required int count}) {
    _bigImageCount = count;
    _stopBigImageAutoSlide();
    if (count <= 1) return;

    _bigImageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_bigImageController.hasClients || _bigImageCount <= 1) {
        return;
      }
      final next = (_bigImageIndex + 1) % _bigImageCount;
      _bigImageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Fetches cart count (sum of quantities) from API for the cart icon badge.
  Future<void> _fetchCartCount() async {
    final token = await Auth.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _cartCount = 0);
      return;
    }
    final base = Auth.apiBaseUrl;
    try {
      final res = await http.get(
        Uri.parse('$base/cart'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() => _cartCount = 0);
        return;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final data = body?['data'] as Map<String, dynamic>?;
      final rawItems = data?['items'] as List<dynamic>? ?? [];
      int total = 0;
      for (final raw in rawItems) {
        final map = raw as Map<String, dynamic>;
        total += (map['quantity'] as num?)?.toInt() ?? 0;
      }
      setState(() => _cartCount = total);
    } catch (_) {
      if (mounted) setState(() => _cartCount = 0);
    }
  }

  /// Plays a "fly to cart" overlay: a small product image flies from the (+) button to the cart icon.
  void _playFlyToCartAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final addContext = _addBtnKey.currentContext;
      final cartContext = _cartIconKey.currentContext;
      final addBox = addContext?.findRenderObject() as RenderBox?;
      final cartBox = cartContext?.findRenderObject() as RenderBox?;
      if (addBox == null || cartBox == null || !addBox.hasSize || !cartBox.hasSize) {
        return;
      }
      final addPos = addBox.localToGlobal(Offset.zero);
      final addSize = addBox.size;
      final cartPos = cartBox.localToGlobal(Offset.zero);
      final cartSize = cartBox.size;
      final start = Offset(addPos.dx + addSize.width / 2, addPos.dy + addSize.height / 2);
      final end = Offset(cartPos.dx + cartSize.width / 2, cartPos.dy + cartSize.height / 2);

      final flySize = 56.0;
      final halfFly = flySize / 2;
      final item = selectedItem;
      final flavorImg = item?["image"] as String?;
      final isNetwork = item?["isNetworkImage"] == true;
      const fallback = "lib/client/order/images/sb.png";

      void onFlyComplete(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _flyController?.removeStatusListener(onFlyComplete);
          _flyOverlayEntry?.remove();
          _flyOverlayEntry = null;
          _fetchCartCount();
          _cartBounceController?.forward(from: 0);
        }
      }

      _flyController?.addStatusListener(onFlyComplete);
      _flyOverlayEntry = OverlayEntry(
        builder: (context) => AnimatedBuilder(
          animation: _flyController!,
          builder: (context, child) {
            final t = Curves.easeIn.transform(_flyController!.value);
            final arc = 1.0 - (2 * t - 1) * (2 * t - 1);
            final x = start.dx + (end.dx - start.dx) * t;
            final y = start.dy + (end.dy - start.dy) * t - 50 * arc;
            final scale = 1.3 - 0.95 * t;
            final opacity = (1.0 - t).clamp(0.0, 1.0);
            return Positioned(
              left: x - halfFly,
              top: y - halfFly,
              width: flySize,
              height: flySize,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE3001B).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: isNetwork && flavorImg != null && flavorImg.startsWith('http')
                            ? Image.network(
                                flavorImg,
                                fit: BoxFit.cover,
                                width: flySize,
                                height: flySize,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  fallback,
                                  fit: BoxFit.cover,
                                  width: flySize,
                                  height: flySize,
                                ),
                              )
                            : Image.asset(
                                flavorImg != null && flavorImg.isNotEmpty ? flavorImg : fallback,
                                fit: BoxFit.cover,
                                width: flySize,
                                height: flySize,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      Overlay.of(context).insert(_flyOverlayEntry!);
      _flyController?.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _stopBigImageAutoSlide();
    _bigImageController.dispose();
    _addBtnController?.dispose();
    _cartBounceController?.dispose();
    _flyController?.dispose();
    _flyOverlayEntry?.remove();
    super.dispose();
  }

  static String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    final base = Auth.apiBaseUrl.replaceAll('/api/v1', '');
    return path.startsWith('http') ? path : '$base/$path';
  }

  /// Map API category to one of the three filter options so flavors show in the grid.
  static String _normalizeCategory(String? category) {
    if (category == null || category.isEmpty) return "Plain Flavors";
    final c = category.toLowerCase().trim();
    if (c.contains("special")) return "Special Flavors";
    if (c.contains("topping")) return "Toppings";
    return "Plain Flavors";
  }

  static String _formatPrice(dynamic price) {
    if (price == null) return '₱0';
    final num? n = price is num ? price : double.tryParse(price.toString());
    if (n == null) return '₱0';
    return '₱${NumberFormat('#,##0').format(n)}';
  }

  /// Items to display: from API flavors when loaded, else fallback. Each item has name, price, image, big_image, category, isNetworkImage, id (when from API).
  List<Map<String, dynamic>> get items {
    final api = _apiFlavors;
    if (api == null || api.isEmpty) return _fallbackItems;
    return api.map((e) {
      final name = e["name"] as String? ?? "";
      final priceRaw = e["price"];
      final price = priceRaw is num
          ? priceRaw.toDouble()
          : (double.tryParse(priceRaw?.toString() ?? "0") ?? 0.0);
      final imagePath = e["image"] as String?;
      final image = _imageUrl(imagePath);
      final category = _normalizeCategory(e["category"] as String?);
      final id = e["id"];
      final map = <String, dynamic>{
        "name": name,
        "price": price,
        "image": image.isEmpty ? "lib/client/order/images/sb.png" : image,
        "big_image": image.isEmpty ? "lib/client/order/images/sbB.png" : image,
        "category": category,
        "isNetworkImage": image.isNotEmpty,
      };
      if (id != null) map["id"] = id is int ? id : int.tryParse(id.toString());
      return map;
    }).toList();
  }

  /// Whether the currently selected flavor is in the user's favorites (from API).
  bool _isFavorite = false;

  /// Fetches favorite state for [selectedItem] from API. Call when opening detail.
  Future<void> _checkFavorite() async {
    final id = selectedItem?["id"];
    if (id == null) {
      if (mounted) setState(() => _isFavorite = false);
      return;
    }
    final token = await Auth.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _isFavorite = false);
      return;
    }
    final base = Auth.apiBaseUrl;
    try {
      final res = await http.get(
        Uri.parse('$base/favorites/check').replace(queryParameters: {'flavor_id': id.toString()}),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      setState(() => _isFavorite = data?['is_favorite'] == true);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = false);
    }
  }

  /// Toggles favorite for [selectedItem] via POST /favorites. Updates [ _isFavorite] and shows SnackBar.
  Future<void> _toggleFavorite() async {
    final id = selectedItem?["id"];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This flavor cannot be added to favorites.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final token = await Auth.getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final base = Auth.apiBaseUrl;
    try {
      final res = await http.post(
        Uri.parse('$base/favorites'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'flavor_id': id is int ? id : int.tryParse(id.toString()) ?? id}),
      );
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode == 401) {
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      final isFav = data?['is_favorite'] == true;
      setState(() => _isFavorite = isFav);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFav ? 'Added to favorites.' : 'Removed from favorites.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update favorites.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  List<String> get gallonSizesList {
    final api = _apiGallons;
    if (api == null || api.isEmpty) return _fallbackGallonSizes;
    return api
        .map((e) => (e["size"] ?? e["name"] ?? e["id"] ?? "").toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Full gallon object for selected size (from API). Used for addon_price and image.
  Map<String, dynamic>? get selectedGallon {
    if (selectedSize.isEmpty) return null;
    final api = _apiGallons;
    if (api == null || api.isEmpty) return null;
    for (final e in api) {
      final sizeStr = (e["size"] ?? e["name"] ?? "").toString().trim().toLowerCase();
      if (sizeStr == selectedSize.trim().toLowerCase()) return Map<String, dynamic>.from(e);
    }
    return null;
  }

  /// Addon price for selected gallon (from API). Used in detail subtotal and checkout summary.
  double get selectedGallonAddonPrice {
    final g = selectedGallon;
    if (g == null || g.isEmpty) return 0;
    final v = g["addon_price"] ?? g["price"];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? "0") ?? 0;
  }

  /// Image URL for selected gallon (from API). Empty if no image or fallback.
  String get selectedGallonImageUrl {
    final g = selectedGallon;
    if (g == null || g.isEmpty) return "";
    return _imageUrl(g["image"] as String?);
  }

  /// Add current selection to cart via API. POST /api/v1/cart with flavor_id, gallon_id, quantity.
  Future<void> _addToCart() async {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a quantity (at least 1).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (selectedSize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gallon size.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final flavorId = selectedItem?["id"];
    final gallon = selectedGallon;
    final gallonId = gallon?["id"];
    if (flavorId == null || gallonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flavor or gallon not found. Try refreshing the menu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final token = await Auth.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add to cart.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final base = Auth.apiBaseUrl;
    final qty = quantity.clamp(1, 5);
    try {
      final res = await http.post(
        Uri.parse('$base/cart'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'flavor_id': flavorId is int ? flavorId : int.tryParse(flavorId.toString()) ?? flavorId,
          'gallon_id': gallonId is int ? gallonId : int.tryParse(gallonId.toString()) ?? gallonId,
          'quantity': qty,
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final message = data?['message'] as String? ?? 'Added to cart.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
        // Cart count and bounce are updated when fly-to-cart animation completes.
      } else {
        final message = data?['message'] as String? ?? 'Could not add to cart.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add to cart. Check your connection.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyInitialSelection() {
    if (widget.initialItemIndex != null) {
      final idx = widget.initialItemIndex!.clamp(0, items.length - 1);
      setState(() => selectedItem = items[idx]);
      return;
    }
    final name = widget.initialFlavorName?.replaceAll(" Flavor", "").trim();
    if (name != null && name.isNotEmpty) {
      final match = items.where((e) =>
          (e["name"] as String).toLowerCase() == name.toLowerCase()).toList();
      if (match.isNotEmpty) {
        setState(() => selectedItem = match.first);
      }
    }
  }

  Future<void> _loadMenuData() async {
    final base = Auth.apiBaseUrl;
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$base/flavors')),
        http.get(Uri.parse('$base/gallons')),
      ]);
      if (!mounted) return;
      List<Map<String, dynamic>>? flavorsList;
      List<Map<String, dynamic>>? gallonsList;
      if (results[0].statusCode == 200) {
        final body = jsonDecode(results[0].body) as Map<String, dynamic>?;
        final data = body?['data'];
        if (data is List) {
          flavorsList = data.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
        }
      }
      if (results[1].statusCode == 200) {
        final body = jsonDecode(results[1].body) as Map<String, dynamic>?;
        final data = body?['data'];
        if (data is List) {
          gallonsList = data.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
        }
      }
      setState(() {
        _apiFlavors = flavorsList?.isNotEmpty == true ? flavorsList : null;
        _apiGallons = gallonsList?.isNotEmpty == true ? gallonsList : null;
        _loadingMenu = false;
      });
      _applyInitialSelection();
      if (selectedItem != null) _checkFavorite();
    } catch (_) {
      if (mounted) setState(() => _loadingMenu = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _addBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _addBtnScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _addBtnController!,
      curve: Curves.easeInOut,
    ));
    _cartBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cartBounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _cartBounceController!,
      curve: Curves.elasticOut,
    ));
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _loadMenuData();
    _fetchCartCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyInitialSelection();
      if (selectedItem != null) _checkFavorite();
    });
  }

  static final List<Map<String, dynamic>> _fallbackItems = [
    {
      "name": "Strawberry",
      "price": 12.99,
      "image": "lib/client/order/images/sb.png", // small image for grid
      "big_image": "lib/client/order/images/sbB.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Vanilla",
      "price": 52.99,
      "image": "lib/client/order/images/ub.png",
      "big_image": "lib/client/order/images/ub.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Strawberry",
      "price": 65.99,
      "image": "lib/client/favorite/images/sb.png",
      "big_image": "lib/client/order/images/sbB.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Vanilla",
      "price": 12.99,
      "image": "lib/client/order/images/ub.png",
      "big_image": "lib/client/order/images/ub.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Strawberry",
      "price": 12.99,
      "image": "lib/client/favorite/images/sb.png",
      "big_image": "lib/client/order/images/sbB.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Vanilla",
      "price": 12.99,
      "image": "lib/client/order/images/ub.png",
      "big_image": "lib/client/order/images/ub.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Strawberry",
      "price": 12.99,
      "image": "lib/client/favorite/images/sb.png",
      "big_image": "lib/client/order/images/sbB.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Vanilla",
      "price": 12.99,
      "image": "lib/client/order/images/ub.png",
      "big_image": "lib/client/order/images/ub.png", // big image for top
      "category": "Plain Flavors",
    },
    {
      "name": "Ube Cheese",
      "price": 12.99,
      "image": "lib/client/order/images/cc.png",
      "big_image": "lib/client/order/images/cc.png", // big image for top
      "category": "Special Flavors",
    },
    {
      "name": "Mango Graham",
      "price": 12.99,
      "image": "lib/client/order/images/mg.png",
      "big_image": "lib/client/order/images/mg.png", // big image for top
      "category": "Special Flavors",
    },
    {
      "name": "Buko Pandan",
      "price": 15.99,
      "image": "lib/client/order/images/vn.png",
      "big_image": "lib/client/order/images/vn.png", // big image for top
      "category": "Toppings",
    },
  ];

  static const List<String> _fallbackGallonSizes = [
    "2 gal",
    "3 gal",
    "3.5 gal",
    "4 gal",
    "5 gal",
    "7 gal",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // remove default back button
        title: showCheckout
            ? null // hide default title
            : (selectedItem == null
                  ? Container(
                      margin: const EdgeInsets.only(
                        left: 53,
                      ), // moves it LEFT a little
                      height: 43,
                      width: 140,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Flavors",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 15.69,
                        ),
                      ),
                    )
                  : const SizedBox()),
        flexibleSpace: showCheckout
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Text with margin only
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 9,
                          left: 10,
                        ), // for the whole column
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Move H&R slightly right
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 15,
                              ), // move H&R right
                              child: Text(
                                "H&R",
                                style: TextStyle(
                                  fontFamily: "NationalPark",
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                  color: Color(0xFFE3001B),
                                ),
                              ),
                            ),
                            // Move ICE CREAM up slightly
                            Transform.translate(
                              offset: const Offset(
                                0,
                                -8,
                              ), // move up by 3 pixels
                              child: Padding(
                                padding: const EdgeInsets.only(left: 13),
                                child: Text(
                                  "ICE CREAM",
                                  style: TextStyle(
                                    fontFamily: "NationalPark",
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE3001B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                          right: 5,
                        ), // move left little bit
                        child: GestureDetector(
                          onTap: () => setState(() => showCheckout = false),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2F2F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        leadingWidth: 43, // ensures AppBar doesn't shrink the leading slot
        leading: showCheckout
            ? const SizedBox()
            : Transform.translate(
                offset: const Offset(20, 0), // move left by 10 pixels
                child: SizedBox(
                  child: Material(
                    color: const Color(0xFFF2F2F2),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

        actions: showCheckout
            ? [] // hide shopping cart
            : [
                Container(
                  margin: const EdgeInsets.only(right: 20),
                  height: 42,
                  width: 42,
                  child: AnimatedBuilder(
                    animation: _cartBounceScale ?? const AlwaysStoppedAnimation(1.0),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _cartBounceScale?.value ?? 1.0,
                        child: child,
                      );
                    },
                    child: Badge(
                      key: _cartIconKey,
                      isLabelVisible: _cartCount > 0,
                      label: Text(
                        _cartCount >= 99 ? '99+' : '$_cartCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFFE3001B),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F2F2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartPage(),
                              ),
                            ).then((_) => _fetchCartCount());
                          },
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFFE3001B),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
      ),
      body: selectedItem == null ? buildGridUI() : buildStrawberryDetail(),
    );
  }

  Widget buildGridUI() {
    // Filter items by search query AND selected category
    final filteredItems = items
        .where(
          (item) =>
              item["name"].toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) &&
              item["category"] == selectedCategory,
        )
        .toList();

    return Column(
      children: [
        // --- SEARCH BAR ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF848484), size: 23),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    cursorColor: Colors.black,
                    style: const TextStyle(
                      fontSize: 14.18,
                      color: Color(0xFF848484),
                    ),
                    decoration: const InputDecoration(
                      hintText: "Search flavors",
                      hintStyle: TextStyle(
                        color: Color(0xFF848484),
                        fontSize: 14.18,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // --- CATEGORY SELECTOR ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryBox("Plain Flavors"),
              _buildCategoryBox("Special Flavors"),
              _buildCategoryBox("Toppings"),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // --- GRID ---
        if (_loadingMenu)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: GridView.builder(
              itemCount: filteredItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 177,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedItem = item;
                      _bigImageIndex = 0;
                    });

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _bigImageController.jumpToPage(0);
                      _startBigImageAutoSlide(count: 2);
                      _checkFavorite();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD9D9D9),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Container(
                            height: 114.36,
                            width: double.infinity,
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: item["isNetworkImage"] == true
                                    ? Image.network(
                                        item["image"] as String,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        errorBuilder: (_, __, ___) => Image.asset(
                                          "lib/client/order/images/sb.png",
                                          fit: BoxFit.cover,
                                          alignment: Alignment.topCenter,
                                        ),
                                      )
                                    : Image.asset(
                                        item["image"] as String,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            left: 10,
                            right: 10,
                          ),
                          child: Text(
                            item["name"],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatPrice(item["price"]),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE3001B),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.add,
                                  size: 19,
                                  color: const Color(0xFFE3001B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBox(String text) {
    bool isSelected = text == selectedCategory;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = text;
        });
      },
      child: Container(
        width: 100,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3001B) : Colors.white,
          border: Border.all(color: const Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF353535),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // ---------------- STRAWBERRY DETAIL PAGE -------------
  // -----------------------------------------------------
  Widget buildStrawberryDetail() {
    const fallbackBig = "lib/client/order/images/sbB.png";
    const imageHeight = 280.0;
    const carouselGap = 12.0;
    final flavorImg = selectedItem?["big_image"];
    final flavorImageSrc = (flavorImg is String && flavorImg.isNotEmpty) ? flavorImg : fallbackBig;
    final gallonUrl = selectedSize.isNotEmpty ? selectedGallonImageUrl : null;
    final showGallon = gallonUrl != null && gallonUrl.startsWith('http');
    // Carousel: slide 0 = flavor (left), slide 1 = gallon (right) when selected. Not in one frame.
    final bigImages = <String>[flavorImageSrc, if (showGallon) gallonUrl];

    bool isNetworkUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

    Widget buildOneImage(String src) {
      return isNetworkUrl(src)
          ? Image.network(
              src,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Image.asset(
                fallbackBig,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            )
          : Image.asset(
              src,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            );
    }

    // Keep timer in sync with carousel page count
    if (_bigImageCount != bigImages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bigImageIndex = 0;
        _bigImageController.jumpToPage(0);
        _startBigImageAutoSlide(count: bigImages.length);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Scrollable content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics:
                          MediaQuery.of(context).orientation ==
                              Orientation.portrait
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Carousel: flavor = first slide (left), gallon = second slide (right), gap between
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: SizedBox(
                                    height: imageHeight,
                                    width: double.infinity,
                                    child: NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        if (notification is ScrollStartNotification) {
                                          _stopBigImageAutoSlide();
                                        } else if (notification is ScrollEndNotification) {
                                          _startBigImageAutoSlide(count: bigImages.length);
                                        }
                                        return false;
                                      },
                                      child: PageView.builder(
                                        controller: _bigImageController,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: bigImages.length,
                                        onPageChanged: (i) =>
                                            setState(() => _bigImageIndex = i),
                                        itemBuilder: (context, i) {
                                          final src = bigImages[i];
                                          final isFirst = i == 0;
                                          final isLast = i == bigImages.length - 1;
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              left: isFirst ? 0 : carouselGap / 2,
                                              right: isLast ? 0 : carouselGap / 2,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(25),
                                              child: buildOneImage(src),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                // Favorite icon: unfilled by default, fill when in favorites; tap toggles
                                Positioned(
                                  top: 26,
                                  right: 14,
                                  child: GestureDetector(
                                    onTap: _toggleFavorite,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.90),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                                        size: 22,
                                        color: const Color(0xFFE3001B),
                                        fill: _isFavorite ? 1 : 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Page indicator when 2 slides
                            if (bigImages.length > 1) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(bigImages.length, (i) {
                                  final isActive = i == _bigImageIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: isActive ? 18 : 6,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFE3001B)
                                          : const Color(0xFFC7C7C7),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  );
                                }),
                              ),
                            ],
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.initialDisplayName ?? selectedItem!["name"],
                                  style: const TextStyle(
                                    fontSize: 23.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // Category is wrapped with extra bottom padding
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    selectedItem!["category"],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF898989),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 22,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "5.0",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Select Gallon size:",
                              style: TextStyle(
                                fontSize: 13.41,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF505050),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 4 gallon sizes per row
                            Column(
                              children: [
                                for (int rowStart = 0; rowStart < gallonSizesList.length; rowStart += 4) ...[
                                  if (rowStart > 0) const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      for (int col = 0; col < 4; col++) ...[
                                        if (col > 0) const SizedBox(width: 8),
                                        Expanded(
                                          child: rowStart + col < gallonSizesList.length
                                              ? GestureDetector(
                                                  onTap: () => setState(
                                                      () => selectedSize = gallonSizesList[rowStart + col]),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: selectedSize == gallonSizesList[rowStart + col]
                                                          ? const Color(0xFFE3001B)
                                                          : const Color(0xFFF5F5F5),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      gallonSizesList[rowStart + col],
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: selectedSize == gallonSizesList[rowStart + col]
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Quantity",
                              style: TextStyle(
                                fontSize: 13.41,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF505050),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      /// MINUS BUTTON
                                      GestureDetector(
                                        onTap: () {
                                          if (quantity > 0) {
                                            setState(() => quantity--);
                                          }
                                        },
                                        child: Container(
                                          height: 24.57,
                                          width: 24.57,
                                          decoration: BoxDecoration(
                                            color: quantity == 0
                                                ? const Color(
                                                    0xFFAFAFAF,
                                                  ) // disabled
                                                : const Color(
                                                    0xFF1C1B1F,
                                                  ), // active
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 20),

                                      /// QUANTITY TEXT
                                      Text(
                                        quantity.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(width: 20),

                                      /// ADD BUTTON
                                      GestureDetector(
                                        onTap: () {
                                          if (quantity < 5) {
                                            setState(() => quantity++);
                                          }
                                        },
                                        child: Container(
                                          height: 24.57,
                                          width: 24.57,
                                          decoration: BoxDecoration(
                                            color: quantity == 5
                                                ? const Color(
                                                    0xFFAFAFAF,
                                                  ) // disabled at max
                                                : const Color(
                                                    0xFF1C1B1F,
                                                  ), // active
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "Subtotal",
                                      style: TextStyle(
                                        fontSize: 13.39,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF848484),
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(
                                        (selectedItem!['price'] as num) * (quantity == 0 ? 1 : quantity)
                                            + selectedGallonAddonPrice * (quantity == 0 ? 1 : quantity),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 19.35,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Bottom checkout bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a quantity (at least 1).'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (selectedSize.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a gallon size.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          showCheckout = true;
                        });
                      },
                      child: AnimatedOpacity(
                        opacity: (quantity <= 0 || selectedSize.isEmpty) ? 0.5 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3001B),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: const Center(
                            child: Text(
                              "Check Out",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  GestureDetector(
                    key: _addBtnKey,
                    onTap: () {
                      if (quantity <= 0 || selectedSize.isEmpty) return;
                      _addBtnController?.forward(from: 0);
                      _playFlyToCartAnimation();
                      _addToCart();
                    },
                    child: AnimatedOpacity(
                      opacity: (quantity <= 0 || selectedSize.isEmpty) ? 0.5 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedBuilder(
                        animation: _addBtnScale ?? const AlwaysStoppedAnimation(1.0),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _addBtnScale?.value ?? 1.0,
                            child: child,
                          );
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Color(0xFFE3001B)),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFFE3001B),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showCheckout) buildCheckoutOverlay(),
        ],
      ),
    );
  }

  bool showCheckout = false;

  Widget buildCheckoutOverlay() {
    final item = selectedItem;
    final qty = quantity == 0 ? 1 : quantity;
    final flavorSubtotal = item != null ? (item["price"] as num) * qty : 0.0;
    final gallonAddonTotal = selectedGallonAddonPrice * qty;
    final totalSubtotal = flavorSubtotal + gallonAddonTotal;
    final gallonImageUrl = selectedGallonImageUrl;
    final flavorImage = item?["image"] as String?;
    final isFlavorNetwork = item?["isNetworkImage"] == true;

    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ---------- HEADER ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Order",
                    style: TextStyle(
                      fontSize: 17.68,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                  Text(
                    "1 Item",
                    style: const TextStyle(fontSize: 14, color: Color(0xFF505050)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    buildCheckoutOrderRow(
                      gallonImageUrl: gallonImageUrl,
                      flavorImage: flavorImage ?? "lib/client/order/images/sb.png",
                      isFlavorNetwork: isFlavorNetwork == true,
                      flavorName: item?["name"] as String? ?? "Flavor",
                      category: item?["category"] as String? ?? "",
                      size: selectedSize.isEmpty ? "—" : selectedSize,
                      quantity: qty,
                      priceDisplay: _formatPrice(flavorSubtotal + gallonAddonTotal),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ---------- STICKY SUMMARY ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 0),
                  DashedLine(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("GALLON", style: TextStyle(fontSize: 13)),
                      Text(_formatPrice(gallonAddonTotal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("DELIVERY FEE", style: TextStyle(fontSize: 13)),
                      Text("₱0"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "SUBTOTAL",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _formatPrice(totalSubtotal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // ---------- CONFIRM BUTTON ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  // Navigate to the CheckoutPage when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutPage()),
                  );
                },
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3001B),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: const Center(
                    child: Text(
                      "Confirm Order",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One order row: flavor image only (no gallon image), then flavor info. Used in checkout overlay / confirm order.
  Widget buildCheckoutOrderRow({
    required String gallonImageUrl,
    required String flavorImage,
    required bool isFlavorNetwork,
    required String flavorName,
    required String category,
    required String size,
    required int quantity,
    required String priceDisplay,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFFD9D9D9),
          strokeWidth: 1,
          gap: 4,
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(minHeight: 90, maxHeight: 90),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: flavor image only (no gallon image in confirm order)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: isFlavorNetwork && flavorImage.startsWith('http')
                    ? Image.network(
                        flavorImage,
                        height: 76,
                        width: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "lib/client/order/images/sb.png",
                          height: 76,
                          width: 76,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        flavorImage,
                        height: 76,
                        width: 76,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      flavorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12.67,
                          color: Color(0xFF898989),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      priceDisplay,
                      style: const TextStyle(
                        fontSize: 13.37,
                        color: Color(0xFFE3001B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      size,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF505050),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12),
                        children: [
                          const TextSpan(
                            text: "Quantity: ",
                            style: TextStyle(color: Color(0xFF898989)),
                          ),
                          TextSpan(
                            text: "${quantity}x",
                            style: const TextStyle(
                              color: Color(0xFF505050),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStrawberryItem() {
    return buildCheckoutOrderRow(
      gallonImageUrl: selectedGallonImageUrl,
      flavorImage: selectedItem?["image"] as String? ?? "lib/client/favorite/images/sb.png",
      isFlavorNetwork: selectedItem?["isNetworkImage"] == true,
      flavorName: selectedItem?["name"] as String? ?? "Strawberry",
      category: selectedItem?["category"] as String? ?? "Special Flavors",
      size: selectedSize.isEmpty ? "2 gal" : selectedSize,
      quantity: quantity == 0 ? 1 : quantity,
      priceDisplay: _formatPrice(
        ((selectedItem?["price"] as num?) ?? 0) * (quantity == 0 ? 1 : quantity)
            + selectedGallonAddonPrice * (quantity == 0 ? 1 : quantity),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );

    // Draw dashed line
    final dashWidth = 5.0;
    final dashSpace = gap;
    double distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final len = dashWidth;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + len),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLine extends StatelessWidget {
  final double height;
  final Color color;

  const DashedLine({
    this.height = 1,
    this.color = const Color(0xFFB2B2B2),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 5.0;
        final dashSpace = 3.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

/// Confirm Order page: shows selected cart items, then "Confirm Order" navigates to Place Order.
class ConfirmOrderPage extends StatelessWidget {
  const ConfirmOrderPage({
    super.key,
    required this.cartItems,
    required this.cartSubtotal,
  });

  final List<CartItem> cartItems;
  final double cartSubtotal;

  double get _gallonTotal =>
      cartItems.fold(0.0, (sum, e) => sum + e.gallonTotal);

  static String _formatPrice(double value) {
    return '₱${NumberFormat('#,##0').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: H&R logo left, X close button right (same style as checkout overlay)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "H&R",
                        style: TextStyle(
                          fontFamily: "NationalPark",
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          color: Color(0xFFE3001B),
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        "ICE CREAM",
                        style: TextStyle(
                          fontFamily: "NationalPark",
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE3001B),
                          height: 1.0,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable center: order items only
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "My Order",
                            style: TextStyle(
                              fontSize: 17.68,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1B1F),
                            ),
                          ),
                          Text(
                            "${cartItems.length} Item${cartItems.length == 1 ? "" : "s"}",
                            style: const TextStyle(fontSize: 14, color: Color(0xFF505050)),
                          ),
                        ],
                      ),
                    ),
                    ...cartItems.map((item) => _ConfirmOrderRow(item: item)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Fixed bottom: Gallon, Delivery Fee, Subtotal (always visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  DashedLine(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("GALLON", style: TextStyle(fontSize: 13)),
                      Text(_formatPrice(_gallonTotal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("DELIVERY FEE", style: TextStyle(fontSize: 13)),
                      const Text("₱0"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "SUBTOTAL",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _formatPrice(cartSubtotal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Confirm Order button
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(
                      cartItems: cartItems,
                      cartSubtotal: cartSubtotal,
                      cartGallonTotal: _gallonTotal,
                    ),
                  ),
                );
              },
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3001B),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: const Center(
                  child: Text(
                    "Confirm Order",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _ConfirmOrderRow extends StatelessWidget {
  final CartItem item;

  const _ConfirmOrderRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFFD9D9D9),
          strokeWidth: 1,
          gap: 4,
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(minHeight: 90, maxHeight: 90),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.isNetworkImage && item.image.startsWith('http')
                    ? Image.network(
                        item.image,
                        height: 76,
                        width: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "lib/client/order/images/sb.png",
                          height: 76,
                          width: 76,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        item.image,
                        height: 76,
                        width: 76,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₱${NumberFormat('#,##0').format(item.lineTotal)}',
                      style: const TextStyle(
                        fontSize: 13.37,
                        color: Color(0xFFE3001B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    item.size,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF505050),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        const TextSpan(
                          text: "Quantity: ",
                          style: TextStyle(color: Color(0xFF898989)),
                        ),
                        TextSpan(
                          text: "${item.quantity}x",
                          style: const TextStyle(
                            color: Color(0xFF505050),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    this.cartItems,
    this.cartSubtotal,
    this.cartGallonTotal,
  });

  final List<CartItem>? cartItems;
  final double? cartSubtotal;
  final double? cartGallonTotal;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedPayment = "";
  int selectedDownPayment = 1700;

  String get _summarySubtotal =>
      '₱${NumberFormat('#,##0').format(widget.cartSubtotal ?? 1900)}';

  String get _summaryGallon =>
      '₱${NumberFormat('#,##0').format(widget.cartGallonTotal ?? 200)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Place Order",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            color: const Color(0xFFE3001B),
            height: 4,
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 20, // horizontal padding
          right: 20, // horizontal padding
          bottom: 10, // vertical padding only at bottom
        ), // horizontal margin

        child: GestureDetector(
          onTap: () {
            // Add the same action as Confirm Order
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryTrackerPage()),
            );
          },
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFE3001B),
              borderRadius: BorderRadius.circular(35),
            ),
            child: const Center(
              child: Text(
                "Place Order",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildSection(
              title: "Address details",
              trailing: "Edit",
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Alma Fe Pepania",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "(+63) 9123456789",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1C1B1F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "ACLC COLLEGE OF MANDAUE BRIONES ST. MAGUIKAY MANDAUE CITY, CEBU",
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF1C1B1F),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            _buildSection(
              title: "Product Order",
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: widget.cartItems != null && widget.cartItems!.isNotEmpty
                  ? SizedBox(
                      height: 170,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: widget.cartItems!.asMap().entries.map((entry) {
                            final item = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key < widget.cartItems!.length - 1 ? 12 : 0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item.isNetworkImage && item.image.startsWith('http')
                                        ? Image.network(
                                            item.image,
                                            width: 55,
                                            height: 55,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Image.asset(
                                              "lib/client/order/images/sb.png",
                                              width: 55,
                                              height: 55,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Image.asset(
                                            item.image,
                                            width: 55,
                                            height: 55,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1C1B1F),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.size,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF9D9D9D),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₱${NumberFormat('#,##0').format(item.lineTotal)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFE3001B),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "x${item.quantity}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF505050),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.size,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF505050),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  :
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            "lib/client/order/images/sb.png",
                            width: 63,
                            height: 63,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Strawberry",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C1B1F),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Special Flavor",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9D9D9D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "₱1,700",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFE3001B),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              "x1",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF505050),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "3.5 gal",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF505050),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            _buildSection(
              title: "Delivery schedule",
              child: Row(
                children: [
                  Expanded(child: _datePicker()),
                  const SizedBox(width: 12),
                  Expanded(child: _timePicker()),
                ],
              ),
            ),

            _buildSection(
              title: "Down payment Amount",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dotted Line directly under title ---
                  const SizedBox(height: 0), // ← moved up (from 12 → 4)

                  LayoutBuilder(
                    builder: (context, constraints) {
                      double dotWidth = 4.1;
                      double spacing = 4;
                      int count = (constraints.maxWidth / (dotWidth + spacing)).floor();

                      return Row(
                        children: List.generate(
                          count,
                          (_) => Container(
                            width: dotWidth,
                            height: 1,
                            margin: EdgeInsets.only(right: spacing),
                            color: const Color(0xFFB2B2B2),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _priceBox(500)),
                      const SizedBox(width: 8),
                      Expanded(child: _priceBox(1000)),
                      const SizedBox(width: 8),
                      Expanded(child: _priceBox(1700)),
                      const SizedBox(width: 8),
                      Expanded(child: _priceBox(1900)),
                    ],
                  ),
                ],
              ),
            ),
            _buildSection(
              title: "Payment Method",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dotted Line directly under title ---
                  const SizedBox(height: 0), // ← moved up (from 12 → 4)

                  LayoutBuilder(
                    builder: (context, constraints) {
                      double dotWidth = 4.1;
                      double spacing = 4;
                      int count = (constraints.maxWidth / (dotWidth + spacing)).floor();

                      return Row(
                        children: List.generate(
                          count,
                          (_) => Container(
                            width: dotWidth,
                            height: 1,
                            margin: EdgeInsets.only(right: spacing),
                            color: const Color(0xFFB2B2B2),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 5,
                  ), // you can also reduce this if needed
                  // --- Payment Tiles ---
                  _paymentTile(
                    title: "Gcash",
                    subtitle: "Not linked",
                    asset: "lib/client/order/images/gcsh.png",
                    value: "gcash",
                  ),
             
                ],
              ),
            ),
            _buildSection(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Column(
                children: [
                  _summaryRow("GALLON", _summaryGallon),
                  const SizedBox(height: 6),
                  _summaryRow("DELIVERY FEE", "0"),
                  const SizedBox(height: 6),
                  _summaryRow("SUBTOTAL", _summarySubtotal),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade300, height: 1),
                  const SizedBox(height: 8),
                  _summaryRow("TOTAL PAYMENT", _summarySubtotal, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // --- Components
  // -----------------------------
  Widget _buildSection({
    String? title,
    String? trailing,
    EdgeInsets? padding,
    required Widget child,
  }) {
    bool isAddress = title == "Address details";

    // Titles that must move up
    final bool moveUpTitles =
        title == "Delivery schedule" ||
        title == "Product Order" ||
        title == "Payment Method" ||
        title == "Down payment Amount";

    // Correct font-weight logic
    FontWeight getFontWeight(String? txt) {
      if (txt == "Payment Method" || txt == "Product Order") return FontWeight.w500; // REGULAR
      if (txt == "Delivery schedule") return FontWeight.w700; // BOLD
      return FontWeight.w700;
    }

    return Container(
      // Horizontal margin set to 20 for all sections
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      padding: padding ?? EdgeInsets.all(isAddress ? 10 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: isAddress
            ? const Border(top: BorderSide(color: Color(0xFFE3001B), width: 8))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Transform.translate(
              offset: moveUpTitles ? const Offset(0, -8) : Offset.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isAddress)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.location_on,
                            size: 17,
                            color: const Color(0xFFE3001B),
                            fill: 1,
                          ),
                        ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.59,
                          fontWeight: getFontWeight(title),
                          color: isAddress
                              ? const Color(0xFFE3001B)
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageAddressPage(),
                            ),
                          );
                        },
                        child: Text(
                          trailing,
                          style: const TextStyle(
                            color: Color(0xFF0D6EFD),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Dotted line only for Address
          if (isAddress) ...[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                double dotWidth = 4.1;
                double spacing = 4;
                int count = (constraints.maxWidth / (dotWidth + spacing)).floor();

                return Row(
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: dotWidth,
                      height: 1,
                      margin: EdgeInsets.only(right: spacing),
                      color: const Color(0xFFB2B2B2),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          child,
        ],
      ),
    );
  }

  // -----------------------------
  // Date Picker
  // -----------------------------
  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        DateTime? date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(), // Fix: Ensure initialDate is provided
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFE3001B), // header color
                  onPrimary: Colors.white, // header text color
                  surface: Colors.white, // <-- CALENDAR BACKGROUND WHITE
                  onSurface: Colors.black, // text color
                ),
              ),
              child: child!,
            );
          },
        );

        if (date != null) {
          setState(() => selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              size: 20,
              color: Color(0xFF777777),
            ),
            const SizedBox(width: 12),
            Text(
              selectedDate == null
                  ? "mm/dd/yyyy"
                  : DateFormat('MM/dd/yyyy').format(selectedDate!),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Time Picker
  // -----------------------------
  Widget _timePicker() {
    return InkWell(
      onTap: () async {
        TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(), // Fix: Prefer selectedTime if available
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFE3001B),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                // ⭐ AM / PM style FIX (compatible with older Flutter)
                timePickerTheme: TimePickerThemeData(
                  dayPeriodShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: Color(0xFFE3001B), // border red
                      width: 1.5,
                    ),
                  ),

                  // Background color for AM/PM (unselected / selected)
                  dayPeriodColor: MaterialStateColor.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Color(0xFFE3001B); // selected red
                    }
                    return Colors.white; // unselected white
                  }),

                  // Text color for AM/PM (unselected / selected)
                  dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white; // selected white text
                    }
                    return Colors.black; // unselected black text
                  }),
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );

        if (time != null) setState(() => selectedTime = time);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: Color(0xFF777777)),
            const SizedBox(width: 20),
            Text(
              selectedTime == null ? "00:00 --" : selectedTime!.format(context),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile({
    required String title,
    String? subtitle,
    required String asset,
    required String value,
  }) {
    return Row(
      children: [
        Image.asset(asset, width: 40, height: 40),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF1C1B1F), fontSize: 12),
              ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => GcashDetailsPage()),
            );
          },
          child: Text(
            "Link My Account",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF007CFF),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------
  // Summary Row
  // -----------------------------
  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _priceBox(int amount) {
    final isSelected = selectedDownPayment == amount;
    return GestureDetector(
      onTap: () => setState(() => selectedDownPayment = amount),
      child: Container(
        width: 65,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3001B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFE3001B) : const Color(0xFF3F3F3F),
            width: 0.5,
          ),
        ),
        child: Text(
          "₱${NumberFormat('#,###').format(amount)}",
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF1C1B1F),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
