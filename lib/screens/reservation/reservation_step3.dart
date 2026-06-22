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
  bool _showSectors = true; // Added state for toggling between floors and sectors

  static const Color vibrantNavy = Color(0xFF132B49);
  static const Color colorFree = Color(0xFF10B981); // Vert émeraude
  static const Color colorSelected = Color(0xFFF59E0B); // Orange
  static const Color colorOccupied = Color(0xFFEF4444); // Rouge

  String _formatDate(DateTime d) {
    List<String> days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    List<String> months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    String dayName = days[d.weekday - 1];
    String monthName = months[d.month - 1];
    return '$dayName ${d.day} $monthName';
  }

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
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisir une table',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(widget.date)} • ${widget.heure} • ${widget.nbPersonnes} Personnes',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const SizedBox(height: 40)
              : Column(
                  children: [
                    _buildCompactZoneTabs(),
                    const SizedBox(height: 15),
                    _buildLegendRow(),
                  ],
                ),
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
                    child: Column(
                      children: [
                        _buildFloorPlanBox(),
                        if (_selectedTableId != null && !_isLoading) ...[
                          const SizedBox(height: 15),
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            child: _buildSelectedTableCard(),
                          ),
                        ],
                        const SizedBox(height: 15),
                        _buildNextButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
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

    if (!_showSectors) {
      // 1. Show Floors
      final floorWidgets = _floors.map<Widget>((floor) {
        final bool isSelected = _selectedFloor != null && _selectedFloor!['etageId'] == floor['etageId'];
        final etageNum = floor['numeroEtage']?.toString() ?? '0';
        final String label = etageNum == '0' ? 'Rez-de-Chaussée' : 'Étage $etageNum';

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
              _showSectors = true; // Switch to sectors view
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
              border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers_rounded,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 4),
            child: Text(
              'ÉTAGE',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
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
        ],
      );
    } else {
      // 2. Show Sectors for selected Floor
      final List<dynamic> sectors = _selectedFloor != null ? (_selectedFloor!['secteurs'] ?? []) : [];
      
      final List<Widget> sectorWidgets = [];
      
      // Add Back Button
      sectorWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _showSectors = false; // Go back to floors view
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
          ),
        ),
      );

      // Add Sector items
      sectorWidgets.addAll(sectors.map<Widget>((sector) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colorSelected : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isSelected ? colorSelected : const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: isSelected ? [BoxShadow(color: colorSelected.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
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
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList());

      final etageNum = _selectedFloor?['numeroEtage']?.toString() ?? '0';
      final String floorLabel = etageNum == '0' ? 'RDC' : 'Étage $etageNum';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
            child: Text(
              'SECTEURS  •  $floorLabel'.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
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
  }

  Widget _buildLegendRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(colorFree, 'Disponible'),
          _legendItem(colorOccupied, 'Occupé'),
          _legendItem(colorSelected, 'Sélectionné'),
        ],
      ),
    );
  }

  Widget _buildFloorPlanBox() {
    final tables = _currentTables;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: tables.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
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
          : SizedBox(
              height: 480,
              width: double.infinity,
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(50),
                minScale: 0.5,
                maxScale: 2.5,
                constrained: false,
                child: Container(
                  width: 800,
                  height: 600,
                  color: Colors.white,
                  child: CustomPaint(
                    painter: DottedGridPainter(),
                    child: Builder(
                      builder: (context) {
                        final double parentWidth = 800.0;
                        final double parentHeight = 600.0;

                        final List<Widget> planWidgets = [];

                        for (int index = 0; index < tables.length; index++) {
                          final t = tables[index];
                          final double posX = double.tryParse(t['posX']?.toString() ?? '0') ?? 0.0;
                          final double posY = double.tryParse(t['posY']?.toString() ?? '0') ?? 0.0;
                          final int capacity = t['capacite'] ?? 4;
                          String labelStr = t['nom']?.toString() ?? 'T${t['numeroPhysique'] ?? (index + 1)}';

                          if (capacity == 0) {
                            // Décor element
                            String qrCode = t['qrCode']?.toString() ?? '';
                            double w = 90.0;
                            double h = 30.0;

                            if (qrCode.contains('|')) {
                              final parts = qrCode.split('|');
                              labelStr = parts[0];
                              if (parts.length > 1) w = double.tryParse(parts[1]) ?? 90.0;
                              if (parts.length > 2) h = double.tryParse(parts[2]) ?? 30.0;
                            }

                            // Scale down slightly to fit mobile screen proportions as done previously
                            final double scaledW = w * 0.8;
                            final double scaledH = h * 0.8;

                            final double left = (posX / 100.0) * (parentWidth - scaledW);
                            final double top = (posY / 100.0) * (parentHeight - scaledH);

                            planWidgets.add(
                              Positioned(
                                left: left.clamp(0.0, parentWidth - scaledW),
                                top: top.clamp(0.0, parentHeight - scaledH),
                                width: scaledW,
                                height: scaledH,
                                child: _buildDecorItem(labelStr),
                              ),
                            );
                          } else {
                            // Normal Table
                            final String tableId = t['id'].toString();
                            final int tableNumber = t['numeroPhysique'] ?? (index + 1);
                            final bool isOccupied = !(t['disponible'] as bool? ?? true);
                            
                            double tableW = 45.0;
                            final double tableH = 35.0;
                            if (labelStr.toLowerCase().contains('vip') || labelStr.toLowerCase().contains('grande') || labelStr.toLowerCase() == 't1' || labelStr.toLowerCase() == 't4') {
                              tableW = 110.0;
                            } else if (labelStr.length > 2) {
                              tableW = 70.0;
                            }

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
                                  label: labelStr,
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
            ),
    );
  }

  Widget _buildDecorItem(String label) {
    final String upperLabel = label.toUpperCase();
    IconData iconData = Icons.widgets_rounded;

    if (upperLabel.contains('ENTR') || upperLabel.contains('ENTREE')) {
      iconData = Icons.door_sliding_rounded;
    } else if (upperLabel.contains('CUISINE')) {
      iconData = Icons.restaurant_rounded;
    } else if (upperLabel.contains('BAR')) {
      iconData = Icons.local_bar_rounded;
    } else if (upperLabel.contains('JARDIN') || upperLabel.contains('PLANTE') || upperLabel.contains('VERT')) {
      iconData = Icons.spa_rounded;
    } else if (upperLabel.contains('TOILETTE') || upperLabel.contains('WC')) {
      iconData = Icons.wc_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD4E4FC), // Le bleu clair de la maquette
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: const Color(0xFF1E3A8A), size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w800, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableItem({
    required String tableId,
    required String label,
    required int num,
    required int capacity,
    required bool isOccupied,
  }) {
    bool isSelected = _selectedTableId == tableId;
    Color bgColor = colorFree;
    Color borderColor = colorFree;
    
    if (isSelected) {
      bgColor = colorSelected;
      borderColor = colorSelected;
    } else if (isOccupied) {
      bgColor = colorOccupied;
      borderColor = colorOccupied;
    }

    final Color txtColor = Colors.white;

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () => setState(() {
                if (_selectedTableId == tableId) {
                  _selectedTableId = null;
                  _selectedTableNumber = -1;
                  _selectedTableCapacity = 0;
                } else {
                  _selectedTableId = tableId;
                  _selectedTableNumber = num;
                  _selectedTableCapacity = capacity;
                }
              }),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorSelected.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: txtColor,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, color: txtColor.withOpacity(0.8), size: 10),
                  const SizedBox(width: 2),
                  Text(
                    capacity.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: txtColor.withOpacity(0.9),
                      fontSize: 9,
                    ),
                  ),
                ],
              )
            ],
          ),
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
                    Text('Capacité : $_selectedTableCapacity pers.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedSector != null ? _selectedSector!['nom']?.toString() ?? '' : '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
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
            Flexible(
              child: Text(
                isEnabled ? 'VALIDER LA TABLE' : 'SÉLECTIONNEZ UNE TABLE',
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isEnabled) const SizedBox(width: 8),
            if (isEnabled) const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14, 
          height: 14, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(3),
          )
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double spacing = 30.0;
    for (double i = spacing / 2; i < size.width; i += spacing) {
      for (double j = spacing / 2; j < size.height; j += spacing) {
        canvas.drawPoints(PointMode.points, [Offset(i, j)], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
