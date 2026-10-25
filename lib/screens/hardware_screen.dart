// Archivo: lib/screens/hardware_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/location_service.dart';

class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  Position? _currentPosition;
  File? _capturedImage;
  bool _isLoading = false;

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _currentPosition = position);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error de hardware: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Método para Cámara (Reto 2)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() => _capturedImage = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo acceder a la imagen: $e');
    }
  }

  // Reiniciar estado (Reto 4)
  void _resetState() {
    setState(() {
      _capturedImage = null;
      _currentPosition = null;
    });
    _showMessage('Datos restablecidos correctamente.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio: GPS y Cámara'),
        actions: [
          // Icono para reiniciar el estado (Reto 4)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar datos',
            onPressed: (_capturedImage != null || _currentPosition != null)
                ? _resetState
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MÓDULO DE CÁMARA
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _capturedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_capturedImage!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Sin fotografía capturada'),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de Galería (Reto 2)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 2),

            // MÓDULO DE GEOLOCALIZACIÓN
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Datos de Geolocalización (GPS)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const CircularIndicatorWithText()
                    else if (_currentPosition != null)
                      Text(
                        // Coordenadas base + Retos 1 y 3
                        'Latitud: ${_currentPosition!.latitude}\n'
                        'Longitud: ${_currentPosition!.longitude}\n'
                        'Precisión: ${_currentPosition!.accuracy.toStringAsFixed(2)} m\n'
                        'Altitud: ${_currentPosition!.altitude.toStringAsFixed(2)} m\n'
                        'Velocidad: ${_currentPosition!.speed.toStringAsFixed(2)} m/s\n'
                        'Hora lectura: ${_currentPosition!.timestamp.toLocal().toString().split('.')[0]}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      )
                    else
                      const Text('Coordenadas no obtenidas todavía.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Obtener Posición GPS Actual'),
            ),
            const SizedBox(height: 20),

            // Botón inferior para reiniciar el estado (Reto 4)
            if (_capturedImage != null || _currentPosition != null)
              TextButton.icon(
                onPressed: _resetState,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Limpiar datos y foto',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CircularIndicatorWithText extends StatelessWidget {
  const CircularIndicatorWithText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text('Conectando con satélites GPS...'),
      ],
    );
  }
}