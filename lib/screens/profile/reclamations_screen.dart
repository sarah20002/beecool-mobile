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
  List<dynamic> _reclamations = [];

  @override
  void initState() {
    super.initState();
    _loadReclamations();
  }

  Future<void> _loadReclamations() async {
    try {
      final feedbacks = await FeedbackService().getMesFeedbacks();
      
      // Filter out only reclamations (those with less than 3 stars)
      // FeedbackResponse structure has nbreEtoiles, message, dateHeure, commandeId, reclamationStatut, reclamationCommentaire
      final recs = feedbacks.where((fb) {
        final stars = fb['nbreEtoiles'] as int? ?? 5;
        return stars < 3;
      }).toList();

      // Sort by date (most recent first)
      recs.sort((a, b) {
        final dateA = DateTime.tryParse(a['dateHeure']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['dateHeure']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _reclamations = recs;
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
      return '${dt.day} $monthStr · ${dt.hour}:$minutesStr';
    } catch (e) {
      return '';
    }
  }

  Widget _buildStatusBadge(String? status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'CLOTUREE':
        bgColor = AppColors.success.withOpacity(0.12);
        textColor = AppColors.success;
        label = 'TRAITÉE';
        break;
      case 'EN_TRAITEMENT':
        bgColor = const Color(0xFFFC9910).withOpacity(0.12);
        textColor = const Color(0xFFFC9910);
        label = 'EN COURS';
        break;
      case 'OUVERTE':
      default:
        bgColor = AppColors.error.withOpacity(0.12);
        textColor = AppColors.error;
        label = 'OUVERTE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes réclamations',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFC9910)),
            )
          : _reclamations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey.shade300),
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
                        'Vous n\'avez soumis aucune réclamation.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _reclamations.length,
                  itemBuilder: (context, index) {
                    final rec = _reclamations[index];
                    final String rawCmdId = rec['commandeId']?.toString() ?? '';
                    final String displayId = rawCmdId.length > 4 ? rawCmdId.substring(rawCmdId.length - 4).toUpperCase() : rawCmdId;
                    final String date = _formatDate(rec['dateHeure']?.toString());
                    final String clientMessage = rec['message']?.toString() ?? 'Aucun message';
                    final String? managerResponse = rec['reclamationCommentaire']?.toString();
                    final String? status = rec['reclamationStatut']?.toString();
                    final int stars = rec['nbreEtoiles'] as int? ?? 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (Commande + Status)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cmd #$displayId',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          
                          // Client's feedback
                          const Text(
                            'Votre avis',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                Icons.star_rounded,
                                color: i < stars ? Colors.amber : Colors.grey.shade300,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '"$clientMessage"',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          // Manager's Response
                          if (managerResponse != null && managerResponse.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC), // Very light grey-blue
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF0F172A)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Réponse du restaurant',
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    managerResponse,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
