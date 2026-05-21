import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import 'reservation_step4.dart';

class ReservationStep3 extends StatefulWidget {
  final Map<String, dynamic> etablissement;
  final DateTime date;
  final String heure;
  final int nbPersonnes;
  final String nomReservation;
  final String telephone;
  final String email;
  final String demandeSpeciale;
  final bool occasionSpeciale;

  const ReservationStep3({
    super.key,
    required this.etablissement,
    required this.date,
    required this.heure,
    required this.nbPersonnes,
    required this.nomReservation,
    required this.telephone,
    required this.email,
    required this.demandeSpeciale,
    required this.occasionSpeciale,
  });

  @override
  State<ReservationStep3> createState() => _ReservationStep3State();
}

class _ReservationStep3State extends State<ReservationStep3> {
  List<dynamic> _floors = [];
  Map<String, dynamic>? _selectedFloor;
  Map<String, dynamic>? _selectedSector;
  bool _isLoading = true;
  
  // Table selection state
  String? _selectedTableId;
  int _selectedTableNumber = -1;
  int _selectedTableCapacity = 0;

  static const Color vibrantNavy = Color(0xFF132B49); // Custom exact navy blue color
  static const Color colorFree = Color(0xFF4CAF50);
  static const Color colorSelected = AppColors.secondary;
  static const Color colorOccupied = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final String monthStr = widget.date.month.toString().padLeft(2, '0');
      final String dayStr = widget.date.day.toString().padLeft(2, '0');
      final String datePart = "${widget.date.year}-$monthStr-$dayStr";
      final String dateHeureStr = "${datePart}T${widget.heure}:00";

      final dio = Dio();
      final response = await dio.get(
        '${ApiConfig.baseUrl}/infrastructure/plan',
        queryParameters: {
          'etablissementId': widget.etablissement['id'].toString(),
          'dateHeure': dateHeureStr,
          'nbPersonnes': widget.nbPersonnes,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> planData = response.data;
        setState(() {
          _floors = planData;
          if (_floors.isNotEmpty) {
            _selectedFloor = _floors[0];
            final List<dynamic> sectors = _selectedFloor!['secteurs'] ?? [];
            if (sectors.isNotEmpty) {
              _selectedSector = sectors[0];
            }
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération du plan de salle : $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _currentTables {
    if (_selectedSector == null) return [];
    return _selectedSector!['tables'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildCustomHeader(context),
          const SizedBox(height: 10),
          _isLoading
              ? const SizedBox(height: 40)
              : _buildCompactZoneTabs(),
          const SizedBox(height: 15),
          _buildLegendRow(),
          const SizedBox(height: 15),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _buildFloorPlanBox(),
                  ),
          ),
          if (_selectedTableId != null && !_isLoading)
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _buildSelectedTableCard(),
            ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(25, MediaQuery.of(context).padding.top + 10, 25, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2A47), size: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: const Row(
              children: [
                Text('ÉTAPE 3', style: TextStyle(color: Color(0xFF1A2A47), fontWeight: FontWeight.bold, fontSize: 12)),
                Text('  •  /4', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactZoneTabs() {
    if (_floors.isEmpty) return const SizedBox.shrink();

    // 1. Floor (Étage) List
    final floorWidgets = _floors.map<Widget>((floor) {
      final bool isSelected = _selectedFloor != null && _selectedFloor!['etageId'] == floor['etageId'];
      final etageNum = floor['numeroEtage']?.toString() ?? '0';
      final String label = etageNum == '0' ? 'Rez-de-Chaussée (RDC)' : 'Étage $etageNum';

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFloor = floor;
            final List<dynamic> sectors = floor['secteurs'] ?? [];
            if (sectors.isNotEmpty) {
              _selectedSector = sectors[0];
            } else {
              _selectedSector = null;
            }
            _selectedTableId = null;
            _selectedTableNumber = -1;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? vibrantNavy : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [if (isSelected) BoxShadow(color: vibrantNavy.withOpacity(0.15), blurRadius: 8)],
            border: Border.all(color: isSelected ? vibrantNavy : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.layers_outlined,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // 2. Sector (Secteur) List for current Floor
    final List<dynamic> sectors = _selectedFloor != null ? (_selectedFloor!['secteurs'] ?? []) : [];
    final sectorWidgets = sectors.map<Widget>((sector) {
      final bool isSelected = _selectedSector != null && _selectedSector!['id'] == sector['id'];
      final String label = sector['nom'] ?? 'Zone';

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedSector = sector;
            _selectedTableId = null;
            _selectedTableNumber = -1;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFC9910) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFFFC9910) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Étage
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 4),
          child: Text(
            'CHOISIR L\'ÉTAGE',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(children: floorWidgets),
        ),
        const SizedBox(height: 10),
        // Title Secteur
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 4),
          child: Text(
            'CHOISIR LE SECTEUR',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(children: sectorWidgets),
        ),
      ],
    );
  }

  Widget _buildLegendRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _legendItem(colorFree, 'Libre'),
          _legendItem(colorSelected, 'Sélection'),
          _legendItem(colorOccupied, 'Occupée'),
        ],
      ),
    );
  }

  Widget _buildFloorPlanBox() {
    final tables = _currentTables;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F8),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: vibrantNavy, borderRadius: BorderRadius.circular(15)),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, color: AppColors.secondary, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'PLAN : ${_selectedSector != null ? _selectedSector!['nom'] : ''}'.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          if (tables.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.table_bar_rounded, color: Colors.grey.shade300, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "Aucune table disponible dans cette zone",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Hint indicator for dragging
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pinch_rounded, color: Colors.grey.shade400, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Pincez pour zoomer · Glissez pour déplacer le plan',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Pan/Zoom Floor Plan Container
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(100),
                    minScale: 0.5,
                    maxScale: 2.0,
                    constrained: false, // Set to false to allow the inner child canvas to be larger
                    child: Container(
                      width: 720,
                      height: 440,
                      color: Colors.white,
                      child: Builder(
                        builder: (context) {
                          final double parentWidth = 720.0;
                          final double parentHeight = 440.0;

                          final List<Widget> planWidgets = [];

                          for (int index = 0; index < tables.length; index++) {
                            final t = tables[index];
                            final double posX = double.tryParse(t['posX']?.toString() ?? '0') ?? 0.0;
                            final double posY = double.tryParse(t['posY']?.toString() ?? '0') ?? 0.0;
                            final int capacity = t['capacite'] ?? 4;

                            if (capacity == 0) {
                              // Décor element
                              String qrCode = t['qrCode']?.toString() ?? '';
                              String label = t['nom']?.toString() ?? 'DÉCOR';
                              double w = 60.0;
                              double h = 60.0;

                              if (qrCode.contains('|')) {
                                final parts = qrCode.split('|');
                                label = parts[0];
                                w = double.tryParse(parts[1]) ?? 60.0;
                                h = double.tryParse(parts[2]) ?? 60.0;
                              }

                              // Scale down slightly for mobile screen fitting
                              final double scaledW = w * 0.7;
                              final double scaledH = h * 0.7;

                              final double left = (posX / 100.0) * (parentWidth - scaledW);
                              final double top = (posY / 100.0) * (parentHeight - scaledH);

                              planWidgets.add(
                                Positioned(
                                  left: left.clamp(0.0, parentWidth - scaledW),
                                  top: top.clamp(0.0, parentHeight - scaledH),
                                  width: scaledW,
                                  height: scaledH,
                                  child: _buildDecorItem(label),
                                ),
                              );
                            } else {
                              // Normal Table
                              final String tableId = t['id'].toString();
                              final int tableNumber = t['numeroPhysique'] ?? (index + 1);
                              final bool isOccupied = !(t['disponible'] as bool? ?? true);
                              
                              final double tableW = 56.0;
                              final double tableH = 56.0;

                              final double left = (posX / 100.0) * (parentWidth - tableW);
                              final double top = (posY / 100.0) * (parentHeight - tableH);

                              planWidgets.add(
                                Positioned(
                                  left: left.clamp(0.0, parentWidth - tableW),
                                  top: top.clamp(0.0, parentHeight - tableH),
                                  width: tableW,
                                  height: tableH,
                                  child: _buildTableItem(
                                    tableId: tableId,
                                    num: tableNumber,
                                    capacity: capacity,
                                    isOccupied: isOccupied,
                                  ),
                                ),
                              );
                            }
                          }

                          return Stack(
                            children: planWidgets,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDecorItem(String label) {
    final String upperLabel = label.toUpperCase();
    
    IconData iconData = Icons.widgets_rounded;
    if (upperLabel.contains('ENTREE') || upperLabel.contains('ENTRÉE')) {
      iconData = Icons.door_sliding_rounded;
    } else if (upperLabel.contains('CUISINE')) {
      iconData = Icons.soup_kitchen_rounded;
    } else if (upperLabel.contains('BAR')) {
      iconData = Icons.local_bar_rounded;
    } else if (upperLabel.contains('JARDIN') || upperLabel.contains('PLANTE') || upperLabel.contains('VERT')) {
      iconData = Icons.spa_rounded;
    } else if (upperLabel.contains('TOILETTE') || upperLabel.contains('WC')) {
      iconData = Icons.wc_rounded;
    }

    return CustomPaint(
      painter: DashedRectPainter(
        color: const Color(0xFFCBD5E1), // soft slate grey
        strokeWidth: 1.5,
        borderRadius: 16,
        dashLength: 5,
        gap: 3,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: const Color(0xFF94A3B8), // slate grey
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              upperLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8), // slate grey
                fontSize: 8,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableItem({
    required String tableId,
    required int num,
    required int capacity,
    required bool isOccupied,
  }) {
    bool isSelected = _selectedTableId == tableId;
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color dotColor = colorFree;
    
    if (isSelected) {
      bgColor = colorSelected;
      borderColor = colorSelected;
      dotColor = Colors.white;
    } else if (isOccupied) {
      bgColor = colorOccupied.withOpacity(0.1);
      borderColor = colorOccupied.withOpacity(0.2);
      dotColor = colorOccupied;
    }

    final Color txtColor = isSelected ? Colors.white : const Color(0xFF1E293B);
    final Color capColor = isSelected ? Colors.white70 : Colors.grey.shade500;

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () => setState(() {
                _selectedTableId = tableId;
                _selectedTableNumber = num;
                _selectedTableCapacity = capacity;
              }),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorSelected
                : (isOccupied ? colorOccupied.withOpacity(0.3) : Colors.grey.shade300),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'T${num.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: txtColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$capacity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: capColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTableCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [vibrantNavy, Color(0xFF2C3E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: vibrantNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                const Text('TABLE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                Text(
                  _selectedTableNumber < 10 ? '0$_selectedTableNumber' : '$_selectedTableNumber',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Table idéale pour votre groupe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, color: Colors.white70, size: 14),
                    const SizedBox(width: 5),
                    Text('Capacité : $_selectedTableCapacity personnes', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Text('•', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 10),
                    Text(
                      _selectedSector != null ? _selectedSector!['nom']?.toString() ?? '' : '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    bool isEnabled = _selectedTableId != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReservationStep4(
                      etablissement: widget.etablissement,
                      date: widget.date,
                      heure: widget.heure,
                      nbPersonnes: widget.nbPersonnes,
                      nomReservation: widget.nomReservation,
                      telephone: widget.telephone,
                      email: widget.email,
                      demandeSpeciale: widget.demandeSpeciale,
                      occasionSpeciale: widget.occasionSpeciale,
                      numeroTable: _selectedTableNumber,
                      tableId: _selectedTableId,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          disabledBackgroundColor: Colors.grey.shade200,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: isEnabled ? 5 : 0,
          shadowColor: AppColors.secondary.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isEnabled ? 'VALIDER LA TABLE & CONTINUER' : 'SÉLECTIONNEZ UNE TABLE',
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isEnabled) const SizedBox(width: 10),
            if (isEnabled) const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedRectPainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    ));

    final Path dashedPath = Path();
    double distance = 0.0;

    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final double next = distance + dashLength;
        dashedPath.addPath(
          metric.extractPath(distance, next < metric.length ? next : metric.length),
          Offset.zero,
        );
        distance = next + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gap != oldDelegate.gap ||
      dashLength != oldDelegate.dashLength ||
      borderRadius != oldDelegate.borderRadius;
}
