import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhraseSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedPhrases;
  const PhraseSelectionScreen({super.key, this.initialSelectedPhrases = const []});

  @override
  State<PhraseSelectionScreen> createState() => _PhraseSelectionScreenState();
}

class _PhraseSelectionScreenState extends State<PhraseSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _quotes;
  final List<String> _selectedPhrases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedPhrases.addAll(widget.initialSelectedPhrases);
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final String response = await rootBundle.loadString('assets/quotes.json');
      final data = await json.decode(response);
      setState(() {
        _quotes = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading quotes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSelection(String phrase) {
    setState(() {
      if (_selectedPhrases.contains(phrase)) {
        _selectedPhrases.remove(phrase);
      } else {
        _selectedPhrases.add(phrase);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Phrases', style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedPhrases),
            child: const Text('Done', style: TextStyle(color: Color(0xFFFF5261), fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF5261),
          labelColor: const Color(0xFFFF5261),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Motivational'),
            Tab(text: 'Self Affirmation'),
            Tab(text: 'Short'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5261)))
          : _quotes == null
              ? const Center(child: Text('Error loading phrases', style: TextStyle(color: Colors.white)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPhraseList('motivational'),
                    _buildPhraseList('self_affirmation'),
                    _buildPhraseList('short'),
                  ],
                ),
    );
  }

  Widget _buildPhraseList(String category) {
    final List<dynamic> phrases = _quotes![category] ?? [];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: phrases.length,
      itemBuilder: (context, index) {
        final phrase = phrases[index] as String;
        final isSelected = _selectedPhrases.contains(phrase);
        return GestureDetector(
          onTap: () => _toggleSelection(phrase),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF5261).withValues(alpha: 0.1) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFFFF5261) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    phrase,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFFFF5261), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
