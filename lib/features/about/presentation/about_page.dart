import 'package:flutter/material.dart';

import '../../../services/prediction_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const _supportedClasses = <String>[
    'Bacterial Spot',
    'Cercospora Leaf Spot',
    'Curl Virus',
    'Healthy Leaf',
    'Nutrition Deficiency',
    'White Spot',
  ];

  late Future<List<String>> _classes;

  @override
  void initState() {
    super.initState();
    _classes = PredictionService().classes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth < 360 ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('About',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(18)),
                child: const Column(
                  children: [
                    Icon(Icons.eco, size: 65, color: Colors.green),
                    SizedBox(height: 15),
                    Text('Chilli Plant Disease Detection System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text('About the System',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'This mobile application uses a deep learning image classification model to analyze chilli leaf images and identify possible leaf conditions. Chilli image validation runs before disease classification.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text('Supported Classes',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FutureBuilder<List<String>>(
                future: _classes,
                builder: (context, snapshot) {
                  final names = snapshot.data?.isNotEmpty == true
                      ? snapshot.data!
                      : _supportedClasses;
                  return Column(
                      children: names
                          .map((name) => _DiseaseItem(name: name))
                          .toList());
                },
              ),
              const SizedBox(height: 8),
              Text('Disease classifier: TFLite · 128 × 128 RGB',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiseaseItem extends StatelessWidget {
  const _DiseaseItem({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            const Icon(Icons.eco, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
                child: Text(name.replaceAll('_', ' '),
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
