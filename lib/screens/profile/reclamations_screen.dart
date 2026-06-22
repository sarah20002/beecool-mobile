import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/feedback_service.dart';

class ReclamationsScreen extends StatefulWidget {
  const ReclamationsScreen({super.key});

  @override
  State<ReclamationsScreen> createState() => _ReclamationsScreenState();
}

class _ReclamationsScreenState extends State<ReclamationsScreen> {
  bool _isLoading = true;
  List<dynamic> _allReclamations = [];
  int _selectedFilterIndex = 0; // 0: Tout, 1: Traitées, 2: En attente

  @override
  void initState() {
    super.initState();
    _loadReclamations();
  }

  Future<void> _loadReclamations() async {
    try {
      final feedbacks = await FeedbackService().getMesFeedbacks();
      
      // Keep only reclamations (those with less than 3 stars)
      final recs = feedbacks.where((fb) {
        final stars = fb['nbreEtoiles'] as int? ?? 5;
        return stars < 3;
      }).toList();

      recs.sort((a, b) {
        final dateA = DateTime.tryParse(a['dateHeure']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['dateHeure']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _allReclamations = recs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isTreated(String? status) {
    return status == 'CLOTUREE' || status == 'EN_TRAITEMENT';
  }

  List<dynamic> get _filteredReclamations {
    if (_selectedFilterIndex == 1) {
      return _allReclamations.where((r) => _isTreated(r['reclamationStatut']?.toString())).toList();
    } else if (_selectedFilterIndex == 2) {
      return _allReclamations.where((r) => !_isTreated(r['reclamationStatut']?.toString())).toList();
    }
    return _allReclamations;
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return '';
    try {
      final dt = DateTime.parse(rawDate);
      final months = [
        'janv', 'févr', 'mars', 'avr', 'mai', 'juin', 
        'juil', 'août', 'sept', 'oct', 'nov', 'déc'
      ];
      final monthStr = months[dt.month - 1];
      final minutesStr = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $monthStr - ${dt.hour}:${minutesStr}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int countTotal = _allReclamations.length;
    final int countTreated = _allReclamations.where((r) => _isTreated(r['reclamationStatut']?.toString())).length;
    final int countPending = countTotal - countTreated;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildHeader(context, countTotal, countTreated, countPending),
                const SizedBox(height: 35), // Space for floating tab bar
                Expanded(
                  child: _filteredReclamations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 0, bottom: 20, left: 16, right: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredReclamations.length,
                          itemBuilder: (context, index) {
                            return _buildReclamationCard(_filteredReclamations[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context, int total, int treated, int pending) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 24,
            right: 24,
            bottom: 40
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFF59E0B), // Warm rich amber
                Color(0xFFD97706), // Deep rich gold/honey
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle background decoration
              Positioned(
                top: -20,
                right: -40,
                child: Icon(
                  Icons.hexagon,
                  size: 200,
                  color: Colors.black.withOpacity(0.04),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
                        ),
                      ),
                      const Text(
                        'Mes réclamations',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 40), // Espace invisible pour équilibrer le titre
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Stats Section
                  const Text(
                    'VOS AVIS & RÉCLAMATIONS',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'messages envoyés',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$treated réponses du manager · $pending en attente',
                    style: TextStyle(
                      color: const Color(0xFF0F172A).withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
        
        // Floating Tab Bar
        Positioned(
          bottom: -25,
          left: 20,
          right: 20,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFilterTab(0, 'Tout', total),
                _buildFilterTab(1, 'Traitées', treated),
                _buildFilterTab(2, 'En attente', pending),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(int index, String title, int count) {
    final bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucune réclamation',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun message ne correspond à ce filtre.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReclamationCard(dynamic rec) {
    final String rawCmdId = rec['commandeId']?.toString() ?? '';
    final String displayId = rawCmdId.length > 4 ? rawCmdId.substring(rawCmdId.length - 4).toUpperCase() : rawCmdId;
    final String date = _formatDate(rec['dateHeure']?.toString());
    final String clientMessage = rec['message']?.toString() ?? 'Aucun message';
    final String? managerResponse = rec['reclamationCommentaire']?.toString();
    final String? status = rec['reclamationStatut']?.toString();
    final String managerName = rec['managerName']?.toString() ?? 'Équipe Beecool';
    final String managerRole = rec['managerRole']?.toString() ?? 'Service Client';
    final int stars = rec['nbreEtoiles'] as int? ?? 1;
    
    final bool isTreated = _isTreated(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$displayId',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '· Beecool',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isTreated),
            ],
          ),
          const SizedBox(height: 12),
          
          // Stars Row
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  Icons.star_rounded,
                  color: i < stars ? const Color(0xFFFC9910) : const Color(0xFFE2E8F0),
                  size: 16,
                );
              }),
              const SizedBox(width: 8),
              Text(
                '$stars/5',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Client Message Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VOTRE MESSAGE',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '« $clientMessage »',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Manager Response Box
          if (isTreated && managerResponse != null && managerResponse.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark Navy Background
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFC9910),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Name & Role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              managerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              managerRole,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge "REPONSE"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: const Color(0xFFFC9910).withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'RÉPONSE',
                          style: TextStyle(
                            color: Color(0xFFFC9910),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    managerResponse,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0), // Light greyish text
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isTreated) {
    if (isTreated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'TRAITÉ',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFC9910),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), // Dark dot
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'NON TRAITÉ',
              style: TextStyle(
                color: Color(0xFF0F172A), // Dark text
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
  }
}
