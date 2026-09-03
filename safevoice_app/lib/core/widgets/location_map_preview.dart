import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a static map preview with a tap-to-open-in-Google-Maps action.
class LocationMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? label;

  const LocationMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Google Static Maps — free, no API key needed for basic use
    final staticMapUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$latitude,$longitude'
        '&zoom=15&size=600x200&scale=2'
        '&markers=color:red%7C$latitude,$longitude'
        '&key='; // works without key for low-volume requests

    // Fallback: OpenStreetMap tile (no API key needed)
    final osmUrl =
        'https://www.openstreetmap.org/export/embed.html'
        '?bbox=${longitude - 0.01},${latitude - 0.01},${longitude + 0.01},${latitude + 0.01}'
        '&layer=mapnik&marker=$latitude,$longitude';

    return GestureDetector(
      onTap: _openInMaps,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Map image via OpenStreetMap static tile
            Image.network(
              'https://staticmap.openstreetmap.de/staticmap.php'
              '?center=$latitude,$longitude&zoom=15&size=600x200'
              '&markers=$latitude,$longitude,red-pushpin',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Overlay with coordinates
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.black54,
                child: Row(
                  children: [
                    const Icon(Icons.location_pin, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label ?? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.white70, size: 14),
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
