// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/models/store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoreLocatorScreen extends StatefulWidget {
  final bool isDark;

  const StoreLocatorScreen({super.key, required this.isDark});

  @override
  State<StoreLocatorScreen> createState() => _StoreLocatorScreenState();
}

class _StoreLocatorScreenState extends State<StoreLocatorScreen> {
  bool isMapView = true;
  String? selectedProvince;
  String? selectedDistrict;

  LatLng? userLocation;
  List<LatLng> routePoints = [];
  bool _isLoadingLocation = false;

  final MapController _mapController = MapController();

  List<Store> allStores = [];
  List<Store> filteredStores = [];

  final List<String> provinces = ['Đà Nẵng', 'Hà Nội', 'Hồ Chí Minh'];
  final Map<String, List<String>> districts = {
    'Đà Nẵng': ['Hải Châu', 'Thanh Khê', 'Sơn Trà'],
    'Hà Nội': ['Nam Từ Liêm', 'Hoàn Kiếm', 'Đống Đa'],
    'Hồ Chí Minh': ['Quận 1', 'Quận 3', 'Quận 10'],
  };

  @override
  void initState() {
    super.initState();
    _fetchStores();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    if (mounted) setState(() => _isLoadingLocation = true);

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng bật GPS / Dịch vụ vị trí!')),
          );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // ✅ Bước 1: Thử lấy vị trí cũ (cached) trước - nhanh hơn nhiều
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && mounted) {
        setState(() {
          userLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
        });
        _mapController.move(userLocation!, 14);
      }

      // ✅ Bước 2: Lấy vị trí chính xác mới (không giới hạn thời gian)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Bỏ timeLimit - GPS cần thời gian cold start, không nên cắt sớm
        ),
      );

      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(userLocation!, 14);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy vị trí hiện tại.')),
        );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getRoute(LatLng destination) async {
    if (userLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đang lấy vị trí...')));
      return;
    }

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${userLocation!.longitude},${userLocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          if (mounted) {
            setState(() {
              routePoints = geometry
                  .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                  .toList();
            });
            final bounds = LatLngBounds.fromPoints([
              userLocation!,
              destination,
              ...routePoints,
            ]);
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50.0),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi kết nối tìm đường')));
    }
  }

  Future<void> _fetchStores() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stores')
        .get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        allStores = snapshot.docs
            .map((doc) => Store.fromMap(doc.data(), doc.id))
            .toList();
        filteredStores = allStores;
      });

      // Auto zoom to stores if user location is not yet known
      if (userLocation == null && filteredStores.isNotEmpty) {
        final firstStore = filteredStores.first;
        _mapController.move(LatLng(firstStore.lat, firstStore.lng), 14);
      }
    }
  }

  void filterStores() {
    setState(() {
      filteredStores = allStores.where((store) {
        bool matchProvince =
            selectedProvince == null || store.province == selectedProvince;
        bool matchDistrict =
            selectedDistrict == null || store.district == selectedDistrict;
        return matchProvince && matchDistrict;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    Color textColor = widget.isDark
        ? AppColors.textMainDark
        : AppColors.textMainLight;
    Color cardColor = widget.isDark ? AppColors.cardDark : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        // ... previous appBar code ...
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          "Cửa hàng",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                isMapView = !isMapView;
              });
            },
            icon: Icon(
              isMapView
                  ? Icons.format_list_bulleted_rounded
                  : Icons.map_rounded,
              color: AppColors.primary,
            ),
            label: Text(
              isMapView ? "Danh sách" : "Bản đồ",
              style: const TextStyle(
                color: AppColors.primary,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isMapView
          ? FloatingActionButton(
              mini: true,
              backgroundColor: cardColor,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            )
          : null,
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: bgColor),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(
                          "Tỉnh/Thành",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        value: selectedProvince,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor, fontFamily: 'Inter'),
                        items: provinces
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedProvince = val;
                            selectedDistrict = null; // reset district
                          });
                          filterStores();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(
                          "Quận/Huyện",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        value: selectedDistrict,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor, fontFamily: 'Inter'),
                        items:
                            (selectedProvince != null
                                    ? districts[selectedProvince!]!
                                    : <String>[])
                                .map<DropdownMenuItem<String>>(
                                  (String d) => DropdownMenuItem<String>(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedDistrict = val;
                          });
                          filterStores();
                        },
                      ),
                    ),
                  ),
                ),
                if (selectedProvince != null || selectedDistrict != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[500]),
                    onPressed: () {
                      setState(() {
                        selectedProvince = null;
                        selectedDistrict = null;
                      });
                      filterStores();
                    },
                  ),
              ],
            ),
          ),
          // Map or List Body
          Expanded(
            child: isMapView
                ? _buildMapView()
                : _buildListView(cardColor, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLocation ?? const LatLng(16.0667, 108.2198),
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.example.coffeeapp',
            ),
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Colors.blueAccent,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                // User location marker - chấm xanh
                if (userLocation != null)
                  Marker(
                    point: userLocation!,
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Store markers
                ...filteredStores.map((store) {
                  return Marker(
                    point: LatLng(store.lat, store.lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showStoreBottomSheet(store),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        // ✅ Loading indicator khi đang lấy vị trí
        if (_isLoadingLocation && userLocation == null)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đang lấy vị trí...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView(Color cardColor, Color textColor) {
    if (filteredStores.isEmpty) {
      return Center(
        child: Text(
          "Không có cửa hàng nào tại khu vực này.",
          style: TextStyle(color: textColor, fontFamily: 'Inter'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 100,
      ), // Padding to avoid GNav overlap
      itemCount: filteredStores.length,
      itemBuilder: (context, index) {
        final store = filteredStores[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppColors.getShadow(widget.isDark)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  store.address,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          isMapView = true;
                        });
                        _getRoute(LatLng(store.lat, store.lng));
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text(
                        "Chỉ đường",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text(
                        "Đặt hàng",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStoreBottomSheet(Store store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Dummy Image placeholder for now
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  store.image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: AppColors.primarySoft,
                      child: const Center(
                        child: Icon(
                          Icons.store,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                store.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: widget.isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      store.address,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: widget.isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Đặt hàng tại đây",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        );
      },
    );
  }
}
