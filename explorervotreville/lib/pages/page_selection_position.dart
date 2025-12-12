import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PageSelectionPosition extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;

  const PageSelectionPosition({
    super.key,
    required this.initialCenter,
    this.initialZoom = 12,
  });

  @override
  State<PageSelectionPosition> createState() => _PageSelectionPositionState();
}

class _PageSelectionPositionState extends State<PageSelectionPosition> {
  LatLng? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une position'),
        actions: [
          TextButton(
            onPressed: _selected == null
                ? null
                : () {
                    Navigator.pop(context, _selected);
                  },
            child: const Text('Valider'),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.initialCenter,
          initialZoom: widget.initialZoom,
          onTap: (tapPosition, point) {
            setState(() {
              _selected = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
            retinaMode: true,
            subdomains: const ['a', 'b', 'c', 'd'],
          ),
          MarkerLayer(
            markers: [
              if (_selected != null)
                Marker(
                  point: _selected!,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.place, size: 40, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _selected == null
              ? "Touchez la carte pour placer le marqueur."
              : "Position sélectionnée : ${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
