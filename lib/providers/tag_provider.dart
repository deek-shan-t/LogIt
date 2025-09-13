import 'package:flutter/foundation.dart';
import '../models/tag.dart';
import '../services/hive_service.dart';

class TagProvider extends ChangeNotifier {
  // Core data
  List<Tag> _tags = [];
  List<Tag> _filteredTags = [];
  
  // UI state
  bool _isLoading = false;
  String? _error;
  
  // Filter and search state
  String _searchQuery = '';
  
  // (Removed sorting & selection state)

  // Getters
  List<Tag> get tags => List.unmodifiable(_tags);
  List<Tag> get filteredTags => List.unmodifiable(_filteredTags);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _tags.isEmpty;
  
  String get searchQuery => _searchQuery;
  // Statistics (only those used externally)
  int get totalTagsCount => _tags.length;
  int get filteredTagsCount => _filteredTags.length;

  // Initialize the provider
  Future<void> initialize() async {
    await loadTags();
  }

  // CRUD Operations
  Future<void> loadTags() async {
    try {
      _setLoading(true);
      _clearError();
      
      final tags = await HiveService.getAllTags();
      _tags = tags;
  _applyFilters();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load tags: $e');
    }
  }

  Future<bool> createTag({
    required String name,
    String? colorHex,
  }) async {
    try {
      _clearError();
      
      if (name.trim().isEmpty) {
        _setError('Tag name cannot be empty');
        return false;
      }
      
      // Check for duplicate names
      if (_tags.any((tag) => tag.name.toLowerCase() == name.toLowerCase())) {
        _setError('Tag with this name already exists');
        return false;
      }
      
      final tag = Tag(
        id: _generateId(),
        name: name.trim(),
        colorHex: colorHex,
      );
      
      await HiveService.addTag(tag);
      
  // Add locally instead of full reload
  _tags.add(tag);
  _applyFilters();
      
      return true;
    } catch (e) {
      _setError('Failed to create tag: $e');
      return false;
    }
  }

  Future<bool> updateTag(Tag updatedTag) async {
    try {
      _clearError();
      
      if (updatedTag.name.trim().isEmpty) {
        _setError('Tag name cannot be empty');
        return false;
      }
      
      // Check for duplicate names (excluding current tag)
      if (_tags.any((tag) => 
          tag.id != updatedTag.id && 
          tag.name.toLowerCase() == updatedTag.name.toLowerCase())) {
        _setError('Tag with this name already exists');
        return false;
      }
      
      await HiveService.updateTag(updatedTag);
      final idx = _tags.indexWhere((t) => t.id == updatedTag.id);
      if (idx != -1) {
        _tags[idx] = updatedTag;
      }
      _applyFilters();
      
      return true;
    } catch (e) {
      _setError('Failed to update tag: $e');
      return false;
    }
  }

  Future<bool> deleteTag(String tagId) async {
    try {
      _clearError();
      
  await HiveService.deleteTag(tagId);
  _tags.removeWhere((t) => t.id == tagId);
  _applyFilters();
      
      return true;
    } catch (e) {
      _setError('Failed to delete tag: $e');
      return false;
    }
  }

  Future<bool> deleteSelectedTags() async => false; // Selection removed

  // Search and filter
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
  _applyFilters();
  }

  void clearSearch() {
    _searchQuery = '';
  _applyFilters();
  }

  // (Removed sorting & selection public API)

  // Utility methods
  // (Removed unused utility methods)

  // Private helper methods
  void _applyFilters() {
    _filteredTags = List.from(_tags);
    if (_searchQuery.isNotEmpty) {
      _filteredTags = _filteredTags.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
    }
    // Always keep alphabetical by name for consistency
    _filteredTags.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() { _error = null; notifyListeners(); }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'tag_$timestamp';
  }

  // Cleanup
  @override
  void dispose() {
    _tags.clear();
    _filteredTags.clear();
    super.dispose();
  }
}
