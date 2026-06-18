import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../core/utils/notification_helper.dart';
import 'reservation_step2.dart';

class ReservationStep1 extends StatefulWidget {
  const ReservationStep1({super.key});

  @override
  State<ReservationStep1> createState() => _ReservationStep1State();
}

class _ReservationStep1State extends State<ReservationStep1> {
  bool _isLoading = true;
  List<dynamic> _etablissements = [];
  int _selectedEstablishmentIndex = 0;
  bool _isBlocked = false;
  
  int _peopleCount = 4;
  
  List<DateTime> _dates = [];
  int _selectedDateIndex = 0;
  
  List<String> _timeSlots = [];
  String _selectedTime = "";
  String _selectedService = "Déjeuner";

  List<String> get _breakfastSlots {
    return _timeSlots.where((t) {
      final hour = int.tryParse(t.split(':')[0]) ?? 0;
      return hour < 12;
    }).toList();
  }

  List<String> get _lunchSlots {
    return _timeSlots.where((t) {
      final hour = int.tryParse(t.split(':')[0]) ?? 0;
      return hour >= 12 && hour < 18;
    }).toList();
  }

  List<String> get _dinnerSlots {
    return _timeSlots.where((t) {
      final hour = int.tryParse(t.split(':')[0]) ?? 0;
      return hour >= 18;
    }).toList();
  }

  final Map<int, String> _weekdayNames = {
    1: 'LUN',
    2: 'MAR',
    3: 'MER',
    4: 'JEU',
    5: 'VEN',
    6: 'SAM',
    7: 'DIM',
  };

  final Map<int, String> _monthNames = {
    1: 'Janvier',
    2: 'Février',
    3: 'Mars',
    4: 'Avril',
    5: 'Mai',
    6: 'Juin',
    7: 'Juillet',
    8: 'Août',
    9: 'Septembre',
    10: 'Octobre',
    11: 'Novembre',
    12: 'Décembre',
  };

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadEtablissements();
  }

  void _generateDates() {
    final now = DateTime.now();
    for (int i = 0; i < 14; i++) {
      _dates.add(now.add(Duration(days: i)));
    }
  }

  Future<void> _loadEtablissements() async {
    try {
      final dio = Dio();
      final response = await dio.get('${ApiConfig.baseUrl}${ApiConfig.etablissements}');
      
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _etablissements = response.data;
          _isLoading = false;
        });
        _checkReservationStatus();
        _updateTimeSlots();
      }
    } catch (e) {
      debugPrint("Error loading establishments: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkReservationStatus() async {
    if (_etablissements.isEmpty) return;
    try {
      final etabId = _etablissements[_selectedEstablishmentIndex]['id'];
      final dio = Dio();
      final response = await dio.get('${ApiConfig.baseUrl}/reservations/status/$etabId');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _isBlocked = response.data == true;
        });
      }
    } catch (e) {
      debugPrint("Error checking reservation status: $e");
    }
  }

  void _updateTimeSlots() {
    if (_etablissements.isEmpty) return;
    final etab = _etablissements[_selectedEstablishmentIndex];
    final selectedDate = _dates[_selectedDateIndex];
    
    // 6 = Samedi, 7 = Dimanche
    final bool isWeekend = selectedDate.weekday == DateTime.saturday || selectedDate.weekday == DateTime.sunday;
    final String? schedule = isWeekend ? etab['horaireWeekend'] : etab['horaireSemaine'];
    
    setState(() {
      List<String> rawSlots = _generateTimeSlots(schedule);
      
      // Filtrer les heures passées si la date sélectionnée est aujourd'hui
      final now = DateTime.now();
      if (selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day) {
        rawSlots.removeWhere((t) {
          final parts = t.split(':');
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          // Garde une marge de 30 min (facultatif, ici on bloque strictement les heures passées)
          return h < now.hour || (h == now.hour && m <= now.minute);
        });
      }

      _timeSlots = rawSlots;
      
      if (_timeSlots.isNotEmpty) {
        // Dynamically adjust selected service if current is empty
        if (_selectedService == "Petit Déjeuner" && _breakfastSlots.isEmpty) {
          _selectedService = _lunchSlots.isNotEmpty ? "Déjeuner" : "Dîner";
        } else if (_selectedService == "Déjeuner" && _lunchSlots.isEmpty) {
          _selectedService = _dinnerSlots.isNotEmpty ? "Dîner" : (_breakfastSlots.isNotEmpty ? "Petit Déjeuner" : "Déjeuner");
        } else if (_selectedService == "Dîner" && _dinnerSlots.isEmpty) {
          _selectedService = _lunchSlots.isNotEmpty ? "Déjeuner" : (_breakfastSlots.isNotEmpty ? "Petit Déjeuner" : "Dîner");
        }

        // Ensure selected time is within the selected service!
        List<String> activeSlots = [];
        if (_selectedService == "Petit Déjeuner") activeSlots = _breakfastSlots;
        else if (_selectedService == "Déjeuner") activeSlots = _lunchSlots;
        else if (_selectedService == "Dîner") activeSlots = _dinnerSlots;

        if (activeSlots.isNotEmpty) {
          if (!activeSlots.contains(_selectedTime)) {
            _selectedTime = activeSlots[0];
          }
        } else {
          _selectedTime = _timeSlots[0];
        }
      } else {
        _selectedTime = "";
      }
    });
  }

  List<String> _generateTimeSlots(String? schedule) {
    if (schedule == null || schedule.isEmpty || !schedule.contains('-')) {
      // Fallback par défaut si pas d'horaire défini
      return ["12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "19:00", "19:30", "20:00", "20:30", "21:00"];
    }
    try {
      final parts = schedule.split('-');
      final startStr = parts[0].trim();
      final endStr = parts[1].trim();
      
      final startHour = int.parse(startStr.split(':')[0]);
      final startMin = int.parse(startStr.split(':')[1]);
      final endHour = int.parse(endStr.split(':')[0]);
      final endMin = int.parse(endStr.split(':')[1]);
      
      List<String> slots = [];
      var current = DateTime(2026, 1, 1, startHour, startMin);
      var end = DateTime(2026, 1, 1, endHour, endMin);
      
      // Si l'heure de fin est avant ou égale à l'heure de début (ex: fermeture à 00:00 ou 02:00)
      if (end.isBefore(current) || end.isAtSameMomentAs(current)) {
        end = DateTime(2026, 1, 2, endHour, endMin);
      }
      
      while (current.isBefore(end)) {
        final hourStr = current.hour.toString().padLeft(2, '0');
        final minStr = current.minute.toString().padLeft(2, '0');
        slots.add('$hourStr:$minStr');
        current = current.add(const Duration(minutes: 30));
      }
      
      if (slots.isEmpty) {
        return ["12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "19:00", "19:30"];
      }
      return slots;
    } catch (e) {
      debugPrint('Error parsing schedule: $e');
      return ["12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "19:00", "19:30"];
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? selectedEtab = _etablissements.isNotEmpty 
        ? _etablissements[_selectedEstablishmentIndex] 
        : null;

    final String heroImg = (selectedEtab != null && selectedEtab['image'] != null && selectedEtab['image'].toString().startsWith('http'))
        ? selectedEtab['image']
        : 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=1000';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeroHeader(context, heroImg),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _sectionTitle('ÉTABLISSEMENT'),
                        ),
                        const SizedBox(height: 15),
                        _buildEstablishmentList(),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _buildPeopleSelector(),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _buildDatePicker(),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _sectionTitle('HEURE D\'ARRIVÉE'),
                        ),
                        const SizedBox(height: 15),
                        _buildServiceTabs(),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _buildTimeGrid(),
                        ),
                        const SizedBox(height: 30),
                        if (!_isLoading && _etablissements.isNotEmpty) _buildNextButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
      floatingActionButton: CustomBottomNav.buildCartFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeroHeader(BuildContext context, String bgImage) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(bgImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Dark Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Text('ÉTAPE 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text(' • /4', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('ÉTAPE 1 · OÙ & QUAND', style: TextStyle(color: Color(0xFFF8A11C), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                const Text('Réservez\nvotre table', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, fontFamily: 'Serif', height: 1.1)),
                const SizedBox(height: 25),
                // Progress dashes
                Row(
                  children: List.generate(4, (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFFF8A11C) : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));
  }

  Widget _buildEstablishmentList() {
    if (_etablissements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Text("Aucun établissement disponible", style: TextStyle(color: Colors.grey)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: List.generate(_etablissements.length, (index) {
          final etab = _etablissements[index];
          final String title = etab['nom'] ?? 'Établissement';
          final String sub = etab['adresse'] ?? 'Adresse';
          final String img = (etab['image'] != null && etab['image'].toString().startsWith('http'))
              ? etab['image']
              : 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=400&q=80';
          
          return _buildEstablishmentCard(index, title, sub, img);
        }),
      ),
    );
  }

  Widget _buildEstablishmentCard(int index, String title, String sub, String img) {
    bool isSelected = _selectedEstablishmentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEstablishmentIndex = index;
        });
        _checkReservationStatus();
        _updateTimeSlots();
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9F9F8) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? AppColors.primary.withOpacity(0.5) : Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                  child: Image.network(img, height: 110, width: double.infinity, fit: BoxFit.cover),
                ),
                if (isSelected)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFF8A11C), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleSelector() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Convives', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 17)),
                SizedBox(height: 2),
                Text('Table pour le groupe', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                _counterBtn(Icons.remove, () => setState(() => _peopleCount > 1 ? _peopleCount-- : null)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text('$_peopleCount', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                ),
                _counterBtn(Icons.add, _incrementPeopleCount, isAdd: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _incrementPeopleCount() {
    if (_etablissements.isEmpty) return;
    final etab = _etablissements[_selectedEstablishmentIndex];
    // On récupère la capacité max d'une table pour cet établissement. Si null, on utilise 10 par défaut.
    final maxCapacity = etab['capaciteMaxTable'] ?? 10; 
    final phone = etab['telephone'] ?? 'l\'établissement';

    if (_peopleCount >= maxCapacity) {
      NotificationHelper.showWarning(
        context,
        title: 'Capacité Max Atteinte',
        message: 'Pour plus de $maxCapacity personnes, veuillez réserver par téléphone au $phone.',
      );
    } else {
      setState(() {
        _peopleCount++;
      });
    }
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: isAdd ? const Color(0xFFF8A11C) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isAdd ? Colors.white : Colors.grey, size: 18),
      ),
    );
  }

  Widget _buildDatePicker() {
    final selectedDate = _dates[_selectedDateIndex];
    final String currentMonthYear = "${_monthNames[selectedDate.month]} ${selectedDate.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Row(
              children: [
                Text(currentMonthYear, style: const TextStyle(color: Color(0xFFF8A11C), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFF8A11C), size: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_dates.length, (index) {
              final date = _dates[index];
              bool isSelected = _selectedDateIndex == index;
              final String weekdayName = _weekdayNames[date.weekday] ?? '';
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateIndex = index;
                  });
                  _updateTimeSlots();
                },
                child: Container(
                  width: 55, height: 55,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF132B49) : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? const Color(0xFF132B49) : Colors.grey.shade100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(weekdayName, style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${date.day}', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF132B49), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTabs() {
    final hasBreakfast = _breakfastSlots.isNotEmpty;
    final hasLunch = _lunchSlots.isNotEmpty;
    final hasDinner = _dinnerSlots.isNotEmpty;

    return Row(
      children: [
        _buildServiceTabButton("Petit Déjeuner", Icons.coffee_rounded, hasBreakfast),
        const SizedBox(width: 10),
        _buildServiceTabButton("Déjeuner", Icons.restaurant_rounded, hasLunch),
        const SizedBox(width: 10),
        _buildServiceTabButton("Dîner", Icons.dinner_dining_rounded, hasDinner),
      ],
    );
  }

  Widget _buildServiceTabButton(String label, IconData icon, bool hasSlots) {
    final bool isSelected = _selectedService == label;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedService = label;
            List<String> slots = [];
            if (label == "Petit Déjeuner") slots = _breakfastSlots;
            else if (label == "Déjeuner") slots = _lunchSlots;
            else if (label == "Dîner") slots = _dinnerSlots;
            
            if (slots.isNotEmpty) {
              _selectedTime = slots[0];
            } else {
              _selectedTime = "";
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF132B49) // brand navy blue
                : (hasSlots ? const Color(0xFFF8F9FA) : const Color(0xFFF1F5F9).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF132B49)
                  : (hasSlots ? Colors.grey.shade200 : Colors.grey.shade100),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFFF8A11C) // golden orange accent
                    : (hasSlots ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? Colors.white
                      : (hasSlots ? const Color(0xFF1E293B) : Colors.grey.shade400),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeGrid() {
    List<String> activeSlots = [];
    if (_selectedService == "Petit Déjeuner") {
      activeSlots = _breakfastSlots;
    } else if (_selectedService == "Déjeuner") {
      activeSlots = _lunchSlots;
    } else if (_selectedService == "Dîner") {
      activeSlots = _dinnerSlots;
    }

    if (activeSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 10),
            Text(
              "Aucun horaire disponible pour ce service",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: activeSlots.map((t) {
        bool isSelected = _selectedTime == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: (MediaQuery.of(context).size.width - 86) / 4,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFF8A11C), Color(0xFFE6891F)], // premium golden-orange brand gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF8A11C).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Center(
              child: Text(
                t,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton() {
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
        onPressed: (_selectedTime.isEmpty || _isBlocked)
            ? null
            : () {
                final etab = _etablissements[_selectedEstablishmentIndex];
                final date = _dates[_selectedDateIndex];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReservationStep2(
                      etablissement: etab,
                      date: date,
                      heure: _selectedTime,
                      nbPersonnes: _peopleCount,
                    ),
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isBlocked ? Colors.red.shade400 : AppColors.secondary,
          disabledBackgroundColor: Colors.grey.shade200,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: (_selectedTime.isNotEmpty && !_isBlocked) ? 5 : 0,
          shadowColor: AppColors.secondary.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isBlocked ? 'RÉSERVATIONS SUSPENDUES' : 'ÉTAPE SUIVANTE', 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 10),
            if (!_isBlocked) const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            if (_isBlocked) const Icon(Icons.block, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
