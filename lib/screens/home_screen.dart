import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PHR Features POC'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: const [
          FeatureCard(
            title: 'QR Scanner',
            icon: Icons.qr_code_scanner,
            route: '/qr_scanner',
            color: Colors.purple,
          ),
          FeatureCard(
            title: 'Notifications',
            icon: Icons.notifications,
            route: '/notifications',
            color: Colors.red,
          ),
          FeatureCard(
            title: 'Location',
            icon: Icons.location_on,
            route: '/location',
            color: Colors.green,
          ),
          FeatureCard(
            title: 'PDF Handling',
            icon: Icons.picture_as_pdf,
            route: '/pdf',
            color: Colors.orange,
          ),
          FeatureCard(
            title: 'Camera',
            icon: Icons.camera_alt,
            route: '/camera',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
} 