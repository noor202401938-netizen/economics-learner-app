import 'dart:math';
import 'package:flutter/material.dart';

class QuoteWidget extends StatelessWidget {
  final String? quote;
  final String? author;

  const QuoteWidget({super.key, this.quote, this.author});

  static const List<Map<String, String>> _defaultQuotes = [
    {
      'quote': 'Economics is everywhere, and understanding economics can help you make better decisions.',
      'author': 'Tyler Cowen',
    },
    {
      'quote': 'The curious task of economics is to demonstrate to men how little they really know about what they imagine they can design.',
      'author': 'Friedrich Hayek',
    },
    {
      'quote': 'Education is the most powerful weapon which you can use to change the world.',
      'author': 'Nelson Mandela',
    },
    {
      'quote': 'An investment in knowledge pays the best interest.',
      'author': 'Benjamin Franklin',
    },
    {
      'quote': 'The only way to do great work is to love what you do.',
      'author': 'Steve Jobs',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selected = quote != null
        ? {'quote': quote!, 'author': author ?? ''}
        : _defaultQuotes[Random().nextInt(_defaultQuotes.length)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4169E1).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF4169E1).withValues(alpha: 0.5),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            color: const Color(0xFF4169E1).withValues(alpha: 0.4),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            selected['quote']!,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          if (selected['author']!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${selected['author']}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
