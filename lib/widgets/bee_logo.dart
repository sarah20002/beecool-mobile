import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class BeeIllustration extends StatelessWidget {
  final double height;
  const BeeIllustration({super.key, this.height = 40});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <defs>
          <linearGradient id="beeGradLogo" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stop-color="#f4a027" />
            <stop offset="100%" stop-color="#e6891f" />
          </linearGradient>
        </defs>
        <g transform="translate(50, 50)">
          <ellipse cx="0" cy="0" rx="32" ry="24" fill="url(#beeGradLogo)" />
          <path d="M -15 -20 Q -15 0 -15 20" stroke="#1a1a1a" stroke-width="5" fill="none" stroke-linecap="round" />
          <path d="M 0 -22 Q 0 0 0 22" stroke="#1a1a1a" stroke-width="5" fill="none" stroke-linecap="round" />
          <path d="M 15 -20 Q 15 0 15 20" stroke="#1a1a1a" stroke-width="5" fill="none" stroke-linecap="round" />
          <ellipse cx="-5" cy="-22" rx="18" ry="12" fill="#ffffff" opacity="0.7" transform="rotate(-25 -5 -22)" />
          <circle cx="-28" cy="-5" r="10" fill="#1a1a1a" />
        </g>
      </svg>
      ''',
      height: height,
    );
  }
}

class BeeTextLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  const BeeTextLogo({super.key, this.fontSize = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Bee',
            style: GoogleFonts.outfit(
              color: color ?? const Color(0xFF2A2A2A),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'كول',
            style: GoogleFonts.amiri(
              color: const Color(0xFFE6891F),
              fontSize: fontSize + 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
