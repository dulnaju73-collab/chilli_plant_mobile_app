import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../core/network/api_client.dart';
import '../../../services/prediction_service.dart';

// ============================================================
// DISEASE INFORMATION MODEL
// ============================================================

class DiseaseInfo {
  final List<String> symptoms;
  final List<String> control;
  final List<String> suggestions;
  final String source;

  const DiseaseInfo({
    this.symptoms = const [],
    this.control = const [],
    this.suggestions = const [],
    required this.source,
  });
}

// ============================================================
// DISEASE INFORMATION
// ============================================================

const Map<String, DiseaseInfo> diseaseInformation = {
  'Cercospora_Leaf_Spot': DiseaseInfo(
    symptoms: [
      'Brownish circular spots with light-gray centers and yellow margins may appear on leaves, giving a "frog-eye" appearance.',
      'At later stages, leaves may turn yellow and drop.',
      'Infected leaves may wilt and roll before falling.',
      'Heavy leaf shedding can occur under high relative humidity.',
      'Brown lesions may occasionally appear on leaf stalks, pods, or branches.',
      'Lower mature leaves are usually affected first.',
      'Severe infection can also affect upper leaves.',
    ],
    control: [
      'Collect and destroy infected leaves as part of field sanitation.',
      'Use recommended plant spacing to reduce high relative humidity.',
      'Maintain good drainage.',
      'Apply the recommended amount of organic fertilizer.',
    ],
    source: 'Sri Lanka Department of Agriculture (DOA)',
  ),
  'Curl_Virus': DiseaseInfo(
    symptoms: [
      'Leaves may become yellow and the veins become clearly visible.',
      'Plants may become stunted due to shortened internode length.',
      'Excessive shoot formation may occur.',
      'Leaves may curl upward because of reduced leaf size.',
      'Pods of infected plants may be small.',
    ],
    control: [
      'Practice timely cultivation.',
      'Establish wind barriers such as maize.',
      'Destroy alternative host plants such as weeds.',
    ],
    source: 'Sri Lanka Department of Agriculture (DOA)',
  ),
  'Bacterial_spot': DiseaseInfo(
    suggestions: [
      'Use healthy or resistant chilli planting material where available.',
      'Regularly monitor plants for disease symptoms.',
      'If symptoms are observed, obtain confirmation and management advice from an Agriculture Officer.',
    ],
    source: 'Sri Lanka Department of Agriculture (DOA)',
  ),
  'Nutrition_Deficiency': DiseaseInfo(
    suggestions: [
      'Test the soil before making major fertilizer applications.',
      'Apply the recommended amount of fertilizer according to the crop requirement.',
      'Maintain proper nutrient management for healthy chilli growth.',
      'Consult an Agriculture Officer if nutrient deficiency symptoms continue or the exact deficiency is uncertain.',
    ],
    source: 'Sri Lanka Department of Agriculture (DOA)',
  ),
  'White_Spot': DiseaseInfo(
    suggestions: [
      'Detailed information is currently unavailable from the selected DOA source.',
    ],
    source: 'Sri Lanka Department of Agriculture (DOA)',
  ),
  'Healthy_Leaf': DiseaseInfo(
    suggestions: [
      'Continue regular monitoring of the chilli plant.',
      'Maintain proper watering and general crop management.',
      'Regularly check leaves for early signs of disease or nutrient problems.',
    ],
    source: 'Sri Lanka Department of Agriculture (DOA)',
  ),
};

// ============================================================
// PLANT SCAN PAGE
// ============================================================

class PlantScanPage extends StatefulWidget {
  const PlantScanPage({
    super.key,
    this.predictionService,
    this.pickImageOverride,
  });

  final PredictionService? predictionService;
  final Future<XFile?> Function(ImageSource source)? pickImageOverride;

  @override
  State<PlantScanPage> createState() => _PlantScanPageState();
}

class _PlantScanPageState extends State<PlantScanPage> {
  final ImagePicker _picker = ImagePicker();
  late final PredictionService _predictionService =
      widget.predictionService ?? PredictionService();

  File? _selectedImage;
  ImageSource _lastImageSource = ImageSource.camera;

  String? _predictionLabel;
  double? _predictionConfidence;

  bool _isPredicting = false;

  String? _errorMessage;
  String? _errorCode;
  bool _isNetworkError = false;

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    if (_isPredicting) {
      return;
    }

    _lastImageSource = source;

    try {
      final pickedFile = widget.pickImageOverride != null
          ? await widget.pickImageOverride!(source)
          : await _picker.pickImage(
              source: source,
              imageQuality: 90,
              maxWidth: 2048,
              maxHeight: 2048,
            );

      // User cancelled
      if (pickedFile == null) {
        return;
      }

      await _analyzeImage(File(pickedFile.path));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPredicting = false;
        _errorMessage = e is ApiException
            ? e.message
            : 'Could not capture image. Please try again.';
        _errorCode = e is ApiException ? e.code : null;
        _isNetworkError = e is ApiException && e.isNetworkError;
      });

      debugPrint('Image capture error: $e');
    }
  }

  // ============================================================
  // ANALYZE IMAGE
  // ============================================================

  Future<void> _analyzeImage(File imageFile) async {
    if (_isPredicting || !mounted) {
      return;
    }

    // Clear previous result
    setState(() {
      _selectedImage = imageFile;
      _predictionLabel = null;
      _predictionConfidence = null;
      _errorMessage = null;
      _errorCode = null;
      _isNetworkError = false;
      _isPredicting = true;
    });

    try {
      // The analyze route validates the image on the server before disease
      // classification, then saves and returns the authoritative result.
      final result = await _predictionService.analyze(imageFile);
      final prediction = result.disease;
      final confidence = result.confidence;

      if (prediction.isEmpty) {
        throw const ApiException('No prediction was returned by the server.');
      }

      if (!mounted) return;

      setState(() {
        _predictionLabel = prediction;
        _predictionConfidence = confidence;
        _isPredicting = false;
        _errorMessage = null;
        _errorCode = null;
        _isNetworkError = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isPredicting = false;
        _errorMessage = e.message;
        _errorCode = e.code;
        _isNetworkError = e.isNetworkError;
      });

      debugPrint(
        'API prediction error (status=${e.statusCode}, code=${e.code}): ${e.message}',
      );
    } on SocketException catch (e) {
      if (!mounted) return;

      setState(() {
        _isPredicting = false;
        _errorMessage =
            'Could not connect to the server. Please check your internet connection and try again.';
        _errorCode = null;
        _isNetworkError = true;
      });

      debugPrint('Network prediction error: $e');
    } on TimeoutException catch (e) {
      if (!mounted) return;

      setState(() {
        _isPredicting = false;
        _errorMessage =
            'The request timed out. Please check your connection and try again.';
        _errorCode = null;
        _isNetworkError = true;
      });

      debugPrint('Timeout prediction error: $e');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPredicting = false;
        _errorMessage =
            'Unable to analyze the image right now. Please try again.';
        _errorCode = null;
        _isNetworkError = false;
      });

      debugPrint('Unexpected prediction error: $e');
    }
  }

  // ============================================================
  // TRY AGAIN / RETAKE
  // ============================================================

  Future<void> _tryAgain() async {
    if (_isPredicting) {
      return;
    }

    final currentImage = _selectedImage;
    if (currentImage != null) {
      await _analyzeImage(currentImage);
      return;
    }

    await _pickImage(_lastImageSource);
  }

  Future<void> _retakePhoto() async {
    if (_isPredicting) {
      return;
    }

    await _pickImage(ImageSource.camera);
  }

  // ============================================================
  // SCAN AGAIN
  // ============================================================

  Future<void> _scanAgain() async {
    if (_isPredicting) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _selectedImage = null;
      _predictionLabel = null;
      _predictionConfidence = null;
      _errorMessage = null;
      _errorCode = null;
      _isNetworkError = false;
    });

    await _pickImage(ImageSource.gallery);
  }

  // ============================================================
  // FORMAT LABEL
  // ============================================================

  String _formatLabel(String label) {
    switch (label) {
      case 'Bacterial_spot':
        return 'Bacterial Spot';

      case 'Cercospora_Leaf_Spot':
        return 'Cercospora Leaf Spot';

      case 'Curl_Virus':
        return 'Curl Virus';

      case 'Healthy_Leaf':
        return 'Healthy Leaf';

      case 'Nutrition_Deficiency':
        return 'Nutrition Deficiency';

      case 'White_Spot':
        return 'White Spot';

      default:
        return label.replaceAll('_', ' ');
    }
  }

  // ============================================================
  // GET DISEASE INFORMATION
  // ============================================================

  DiseaseInfo _getDiseaseInfo(String label) {
    return diseaseInformation[label] ??
        const DiseaseInfo(
          suggestions: ['Detailed information is currently unavailable.'],
          source: 'Sri Lanka Department of Agriculture (DOA)',
        );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BULLET LIST
  // ============================================================

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.circle,
                  size: 7,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 15, height: 1.45),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // DISEASE DETAILS
  // ============================================================

  Widget _buildDiseaseDetails() {
    if (_predictionLabel == null) {
      return const SizedBox.shrink();
    }

    final String label = _predictionLabel!;

    final DiseaseInfo info = _getDiseaseInfo(label);

    final bool hasSymptoms = info.symptoms.isNotEmpty;

    final bool hasControl = info.control.isNotEmpty;

    final bool hasSuggestions = info.suggestions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disease Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (hasSymptoms) ...[
            _buildSectionTitle('Disease Symptoms', Icons.search),
            const SizedBox(height: 12),
            _buildBulletList(info.symptoms),
            const SizedBox(height: 10),
          ],
          if (hasControl) ...[
            const Divider(height: 30),
            _buildSectionTitle(
              'Disease Control',
              Icons.health_and_safety_outlined,
            ),
            const SizedBox(height: 12),
            _buildBulletList(info.control),
          ],
          if (hasSuggestions) ...[
            if (hasSymptoms || hasControl) const Divider(height: 30),
            _buildSectionTitle('Suggestions', Icons.lightbulb_outline),
            const SizedBox(height: 12),
            _buildBulletList(info.suggestions),
          ],
          const Divider(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Information Source: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: info.source),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureActions(double maxWidth) {
    final tryAgainButton = OutlinedButton.icon(
      key: const ValueKey('plant_scan_try_again_button'),
      icon: const Icon(Icons.refresh),
      label: const Text('Try Again'),
      onPressed: _isPredicting ? null : _tryAgain,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green.shade800,
        side: BorderSide(color: Colors.green.shade400),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    final retakeButton = ElevatedButton.icon(
      key: const ValueKey('plant_scan_retake_button'),
      icon: const Icon(Icons.camera_alt_outlined),
      label: const Text('Retake'),
      onPressed: _isPredicting ? null : _retakePhoto,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (maxWidth < 320) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tryAgainButton,
          const SizedBox(height: 10),
          retakeButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: tryAgainButton),
        const SizedBox(width: 12),
        Expanded(child: retakeButton),
      ],
    );
  }

  Widget _buildErrorBanner() {
    final isInvalidPlant = _errorCode == ApiException.invalidPlantImageCode;
    final Color backgroundColor;
    final Color borderColor;
    final Color iconColor;
    final Color textColor;
    final IconData icon;
    final String? heading;

    if (isInvalidPlant) {
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
      iconColor = Colors.orange.shade800;
      textColor = Colors.orange.shade900;
      icon = Icons.warning_amber_rounded;
      heading = 'Not a Chilli Plant Image';
    } else if (_isNetworkError) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      iconColor = Colors.red.shade700;
      textColor = Colors.red.shade800;
      icon = Icons.wifi_off_rounded;
      heading = 'Connection Issue';
    } else {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      iconColor = Colors.red.shade700;
      textColor = Colors.red.shade800;
      icon = Icons.error_outline;
      heading = null;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading != null) ...[
                  Text(
                    heading,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  _errorMessage!,
                  style: TextStyle(color: textColor, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool healthy = _predictionLabel == 'Healthy_Leaf';
    final viewport = MediaQuery.sizeOf(context);
    final previewHeight =
        (viewport.height * 0.36).clamp(220.0, 380.0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Plant Scanner')),
      body: ResponsivePage(
        maxContentWidth: 840,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(viewport.width < 360 ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Scan Plant Health',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Take a photo or select a chilli leaf image '
                'to detect possible plant diseases.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // IMAGE PREVIEW
              // ==================================================
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: _selectedImage == null
                    ? SizedBox(
                        height: previewHeight,
                        child: Container(
                          color: Colors.grey.shade100,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 70, color: Colors.grey),
                              SizedBox(height: 14),
                              Text('No image selected yet',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          SizedBox(
                            height: previewHeight,
                            width: double.infinity,
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 56,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _ScannerOverlayPainter(),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              if (_selectedImage != null || _errorMessage != null) ...[
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildCaptureActions(constraints.maxWidth),
                ),
              ],

              const SizedBox(height: 20),

              // ==================================================
              // ANALYZING
              // ==================================================
              if (_isPredicting)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        'Analyzing plant health...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Validating chilli leaf and running detection',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

              // ==================================================
              // ERROR / VALIDATION FEEDBACK
              // ==================================================
              if (_errorMessage != null && !_isPredicting)
                _buildErrorBanner(),

              // ==================================================
              // PREDICTION RESULT
              // ==================================================
              if (_predictionLabel != null && !_isPredicting)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: healthy ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          healthy ? Colors.green.shade300 : Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        healthy
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 60,
                        color: healthy
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        healthy
                            ? 'Plant Appears Healthy'
                            : 'Possible Disease Detected',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: healthy
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatLabel(_predictionLabel!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Confidence: '
                        '${(_predictionConfidence ?? 0.0).toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _buildDiseaseDetails(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Again'),
                          onPressed: _isPredicting ? null : _scanAgain,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ==================================================
              // GALLERY BUTTON
              // ==================================================
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick From Gallery'),
                onPressed: _isPredicting
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // CAMERA BUTTON
              // ==================================================
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                onPressed:
                    _isPredicting ? null : () => _pickImage(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'For better results, use a clear photo '
                'of a chilli leaf.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SCANNER OVERLAY
// ================================================================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(165)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.08,
      size.width * 0.84,
      size.height * 0.84,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      paint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(115)
      ..strokeWidth = 1;

    for (int i = 1; i <= 2; i++) {
      final dx = rect.left + rect.width / 3 * i;

      final dy = rect.top + rect.height / 3 * i;

      canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), linePaint);

      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
