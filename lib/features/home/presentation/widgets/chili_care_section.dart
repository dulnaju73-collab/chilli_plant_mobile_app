import 'package:flutter/material.dart';

class _ChiliCareCopy {
  const _ChiliCareCopy({
    required this.sectionTitle,
    required this.aboutTitle,
    required this.aboutDesc,
    required this.diseasesTitle,
  });

  final String sectionTitle;
  final String aboutTitle;
  final String aboutDesc;
  final String diseasesTitle;
}

class _ChiliDiseaseInfo {
  const _ChiliDiseaseInfo({
    required this.nameEn,
    required this.nameSin,
    required this.descEn,
    required this.descSin,
    required this.icon,
    this.iconColor = Colors.redAccent,
    this.assetImage,
    this.imageUrl,
  });

  final String nameEn;
  final String nameSin;
  final String descEn;
  final String descSin;
  final IconData icon;
  final Color iconColor;
  final String? assetImage;
  final String? imageUrl;
}

/// Interactive Chili Care guide section displayed on the Home screen with
/// localized English / Sinhala descriptions scoped strictly to this section.
class ChiliCareSection extends StatefulWidget {
  const ChiliCareSection({super.key});

  @override
  State<ChiliCareSection> createState() => _ChiliCareSectionState();
}

class _ChiliCareSectionState extends State<ChiliCareSection> {
  bool _isEnglish = true;

  static const _ChiliCareCopy _copyEn = _ChiliCareCopy(
    sectionTitle: 'Chili Care',
    aboutTitle: 'About Chili Plants',
    aboutDesc:
        'Chili plants (Capsicum species) are warm-season herbaceous crops cultivated worldwide for their pungent and flavorful fruits. They thrive in well-drained, nutrient-rich soil with plenty of direct sunlight. While relatively easy to grow, they are highly susceptible to several viral, fungal, and bacterial diseases that can devastate yields.',
    diseasesTitle: 'Common Diseases',
  );

  static const _ChiliCareCopy _copySin = _ChiliCareCopy(
    sectionTitle: 'මිරිස් වගාව',
    aboutTitle: 'මිරිස් ශාකය පිළිබඳව',
    aboutDesc:
        'මිරිස් ශාකය (Capsicum spp.) යනු එහි සැර සහ රසවත් ඵල සඳහා ලොව පුරා වගා කරන ජනප්‍රිය උණුසුම් දේශගුණික බෝගයකි. ඒවා හොඳින් ජලය බැස යන, පෝෂ්‍යදායී පසෙහි සහ හොඳින් හිරු එළිය ලැබෙන ස්ථානවල සාර්ථකව වර්ධනය වේ. වගා කිරීමට පහසු වුවද, අස්වැන්නට දැඩි ලෙස හානි කළ හැකි වෛරස්, දිලීර සහ බැක්ටීරියා රෝග කිහිපයකට මෙම ශාකය පහසුවෙන් ගොදුරු වේ.',
    diseasesTitle: 'ප්‍රධාන මිරිස් රෝග',
  );

  static const String _heroImageUrl =
      'https://encrypted-tbn3.gstatic.com/licensed-image?q=tbn:ANd9GcSNEw5Slre5UIdQr72ADNfUVW9lFuKt_ed7x6EuxEWTRftS-pL25nF5WmvFWnnMt6Cr2t7-pUZRAYG8OD8';

  static const List<_ChiliDiseaseInfo> _diseases = [
    _ChiliDiseaseInfo(
      nameEn: 'White Spot',
      nameSin: 'සුදු ලප (White Spot)',
      descEn:
          'White Spot is a leaf condition where small white or pale-coloured spots appear on chilli leaves. These spots may spread and affect the normal appearance of the leaves. Different factors, including fungal infections and pest damage, may cause similar symptoms.',
      descSin:
          'White Spot යනු මිරිස් කොළ මත කුඩා සුදු පැහැති හෝ ලා පැහැති ලප ඇතිවන තත්ත්වයකි. මෙම ලප ක්‍රමයෙන් වැඩි විය හැකි අතර කොළවල සාමාන්‍ය පෙනුම වෙනස් කරයි. දිලීර ආසාදන සහ කෘමි හානි ඇතුළු විවිධ හේතු නිසා මෙවැනි ලක්ෂණ ඇති විය හැක.',
      assetImage: 'assets/images/chili_care/white_spot.jpg',
      icon: Icons.warning_amber_rounded,
    ),
    _ChiliDiseaseInfo(
      nameEn: 'Nutrition Deficiency',
      nameSin: 'පෝෂක ඌනතාවය (Nutrition Deficiency)',
      descEn:
          'Nutrition Deficiency occurs when chilli plants do not receive enough essential nutrients for healthy growth. It can affect leaf colour, shape, and plant development.',
      descSin:
          'මිරිස් පැළවල නිරෝගී වර්ධනය සඳහා අවශ්‍ය පෝෂක ද්‍රව්‍ය ප්‍රමාණවත් ලෙස නොලැබීම පෝෂක ඌනතාවය ලෙස හැඳින්වේ. මෙය කොළවල වර්ණය, හැඩය සහ පැළයේ වර්ධනයට බලපායි.',
      assetImage: 'assets/images/chili_care/nutrition_deficiency.jpg',
      icon: Icons.eco_outlined,
      iconColor: Colors.orange,
    ),
    _ChiliDiseaseInfo(
      nameEn: 'Healthy Leaf',
      nameSin: 'නිරෝගී මිරිස් කොළ (Healthy Leaf)',
      descEn:
          'A healthy chilli leaf has a natural green colour and normal shape. It does not show visible disease symptoms such as unusual spots, yellowing, or abnormal curling. Healthy leaves help plants produce energy through photosynthesis.',
      descSin:
          'නිරෝගී මිරිස් කොළ ස්වභාවික කොළ පැහැයෙන් සහ සාමාන්‍ය හැඩයෙන් යුක්ත වේ. එහි අසාමාන්‍ය ලප, කහ පැහැ වීම හෝ කොළ ඇඹරීම වැනි රෝග ලක්ෂණ දක්නට නොලැබේ. ප්‍රභාසංශ්ලේෂණ ක්‍රියාවලිය මගින් ශාකයට අවශ්‍ය ශක්තිය නිපදවීමට නිරෝගී කොළ උපකාරී වේ.',
      assetImage: 'assets/images/chili_care/healthy_leaf.jpg',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    ),
    _ChiliDiseaseInfo(
      nameEn: 'Cercospora Leaf Spot',
      nameSin: 'සර්කොස්පෝරා පත්‍ර ලප රෝගය (Cercospora Leaf Spot)',
      descEn:
          'Cercospora Leaf Spot is a fungal disease that affects chilli leaves. It causes circular brown spots with grey or light-coloured centres. In severe cases, infected leaves may turn yellow, dry, and fall off.',
      descSin:
          'Cercospora Leaf Spot යනු මිරිස් කොළවලට බලපාන දිලීර රෝගයකි. මෙම රෝගය නිසා කොළ මත අළු හෝ ලා පැහැති මධ්‍යයක් සහිත වටකුරු දුඹුරු පැහැති ලප ඇති වේ. රෝගය උග්‍ර වූ විට කොළ කහ පැහැයට හැරී වියළී හැලී යා හැකිය.',
      assetImage: 'assets/images/chili_care/cercospora_leaf_spot.jpg',
      icon: Icons.warning_amber_rounded,
    ),
    _ChiliDiseaseInfo(
      nameEn: 'Bacterial Wilt',
      nameSin: 'බැක්ටීරියා මැලවීමේ රෝගය (Bacterial Wilt)',
      descEn:
          "A soil-borne pathogen that invades the plant's vascular system, blocking water transport. The most distinct symptom is the rapid wilting of the entire plant while the leaves still remain green, eventually leading to plant death.",
      descSin:
          'පස මගින් බෝවන මෙම රෝගය ශාකයේ ජල ප්‍රවාහන පද්ධතිය අවහිර කරයි. කොළ කොළ පැහැයෙන් තිබියදීම සම්පූර්ණ ශාකයම වේගයෙන් මැලවී ගොස් මිය යාම මෙහි ප්‍රධාන රෝග ලක්ෂණයයි.',
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTR7IsrpqNj3nDDp8koiRp-vYIRObgFDJJL67CWQ8B_yScSnURTN6E3Q9ae&s=10',
      icon: Icons.pest_control,
    ),
  ];

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = _isEnglish ? _copyEn : _copySin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final diseaseImageWidth = constraints.maxWidth < 360 ? 104.0 : 120.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & EN / Sinhala Language Toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.eco, color: Colors.green.shade300),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          copy.sectionTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: _isEnglish
                            ? 'Switch Chili Care description to Sinhala'
                            : 'Switch Chili Care description to English',
                        child: GestureDetector(
                          key: const ValueKey('chili_care_language_toggle'),
                          onTap: _toggleLanguage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade900,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLangBadge('EN', _isEnglish),
                                _buildLangBadge('සිංහල', !_isEnglish),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Image Section
                Stack(
                  children: [
                    Image.network(
                      _heroImageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 220,
                          color: Colors.green.shade800,
                          child: const Center(
                            child: Icon(
                              Icons.eco_outlined,
                              size: 40,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 220,
                        color: Colors.green.shade900,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.green.shade900.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        copy.aboutTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // About Chili Plants Card
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            copy.aboutDesc,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              height: 1.5,
                              fontSize: _isEnglish ? 15 : 13,
                              fontWeight: _isEnglish
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Common Diseases Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.pest_control,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              copy.diseasesTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      for (int i = 0; i < _diseases.length; i++)
                        _buildDiseaseCard(
                          _diseases[i],
                          imageWidth: diseaseImageWidth,
                          isLast: i == _diseases.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiseaseImage(_ChiliDiseaseInfo disease) {
    final asset = disease.assetImage;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return Image.network(
      disease.imageUrl ?? '',
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.green.shade50,
          child: Center(
            child: Icon(Icons.eco_outlined, color: Colors.green.shade300),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _buildDiseaseCard(
    _ChiliDiseaseInfo disease, {
    required double imageWidth,
    required bool isLast,
  }) {
    final name = _isEnglish ? disease.nameEn : disease.nameSin;
    final desc = _isEnglish ? disease.descEn : disease.descSin;

    return Card(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Disease Image
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: SizedBox(
                width: imageWidth,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildDiseaseImage(disease),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        radius: 14,
                        child: Icon(
                          disease.icon,
                          size: 16,
                          color: disease.iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Disease Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _isEnglish ? 16 : 14,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: _isEnglish ? 13 : 11,
                        height: 1.4,
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
  }

  Widget _buildLangBadge(String label, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : const [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green.shade800 : Colors.green.shade200,
        ),
      ),
    );
  }
}
