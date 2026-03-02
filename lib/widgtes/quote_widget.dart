import 'dart:math';
import 'package:flutter/material.dart';

class QuoteWidget extends StatefulWidget {
  final String? quote;
  final String? author;

  const QuoteWidget({super.key, this.quote, this.author});

  @override
  State<QuoteWidget> createState() => _QuoteWidgetState();
}

class _QuoteWidgetState extends State<QuoteWidget> {
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

  late final Map<String, String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.quote != null
        ? {'quote': widget.quote!, 'author': widget.author ?? ''}
        : _defaultQuotes[Random().nextInt(_defaultQuotes.length)];
  }

  @override
  Widget build(BuildContext context) {

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
            _selected['quote']!,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          if (_selected['author']!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${_selected['author']}',
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
