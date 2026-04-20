class Store {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String image;
  final String province;
  final String district;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.image,
    required this.province,
    required this.district,
  });

  factory Store.fromMap(Map<String, dynamic> data, String documentId) {
    return Store(
      id: documentId,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      image: data['image'] ?? 'assets/images/banner/firstbanner.jpg',
      province: data['province'] ?? '',
      district: data['district'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'image': image,
      'province': province,
      'district': district,
    };
  }
}
