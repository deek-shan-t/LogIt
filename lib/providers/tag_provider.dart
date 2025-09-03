import 'package:flutter/foundation.dart';
import '../models/tag.dart';
import '../services/hive_service.dart';

enum TagSortBy {
  name,
  color,
}

enum SortOrder {
  ascending,
  descending,
}

class TagProvider extends ChangeNotifier {
  // Core data
  List<Tag> _tags = [];
  List<Tag> _filteredTags = [];
  
  // UI state
  bool _isLoading = false;
  String? _error;
  
  // Filter and search state
  String _searchQuery = '';
  
  // Sorting state
  TagSortBy _sortBy = TagSortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;
  
  // Selection state
  final Set<String> _selectedTagIds = {};

  // Getters
  List<Tag> get tags => List.unmodifiable(_tags);
  List<Tag> get filteredTags => List.unmodifiable(_filteredTags);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _tags.isEmpty;
  
  String get searchQuery => _searchQuery;
  TagSortBy get sortBy => _sortBy;
  SortOrder get sortOrder => _sortOrder;
  
  Set<String> get selectedTagIds => Set.unmodifiable(_selectedTagIds);
  bool get hasSelection => _selectedTagIds.isNotEmpty;
  int get selectionCount => _selectedTagIds.length;
  
  // Statistics
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
      _applyFiltersAndSort();
      
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
      
      // Reload all tags to ensure data consistency
      await loadTags();
      
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
      
      // Reload all tags to ensure data consistency  
      await loadTags();
      
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
      
      // Reload all tags to ensure data consistency
      await loadTags();
      _selectedTagIds.remove(tagId);
      
      return true;
    } catch (e) {
      _setError('Failed to delete tag: $e');
      return false;
    }
  }

  Future<bool> deleteSelectedTags() async {
    if (_selectedTagIds.isEmpty) return false;
    
    try {
      _clearError();
      
      // Delete from Hive
      await HiveService.deleteTags(List.from(_selectedTagIds));
      
      // Remove from local list
      _tags.removeWhere((tag) => _selectedTagIds.contains(tag.id));
      _selectedTagIds.clear();
      _applyFiltersAndSort();
      
      return true;
    } catch (e) {
      _setError('Failed to delete selected tags: $e');
      return false;
    }
  }

  // Search and filter
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFiltersAndSort();
  }

  // Sorting
  void setSortBy(TagSortBy sortBy, {SortOrder? order}) {
    _sortBy = sortBy;
    if (order != null) {
      _sortOrder = order;
    }
    _applyFiltersAndSort();
  }

  void toggleSortOrder() {
    _sortOrder = _sortOrder == SortOrder.ascending 
        ? SortOrder.descending 
        : SortOrder.ascending;
    _applyFiltersAndSort();
  }

  // Selection
  void selectTag(String tagId) {
    _selectedTagIds.add(tagId);
    notifyListeners();
  }

  void deselectTag(String tagId) {
    _selectedTagIds.remove(tagId);
    notifyListeners();
  }

  void toggleTagSelection(String tagId) {
    if (_selectedTagIds.contains(tagId)) {
      _selectedTagIds.remove(tagId);
    } else {
      _selectedTagIds.add(tagId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedTagIds.addAll(_filteredTags.map((tag) => tag.id));
    notifyListeners();
  }

  void selectAllVisible() {
    _selectedTagIds.addAll(_filteredTags.map((tag) => tag.id));
    notifyListeners();
  }

  void deselectAll() {
    _selectedTagIds.clear();
    notifyListeners();
  }

  bool isTagSelected(String tagId) {
    return _selectedTagIds.contains(tagId);
  }

  // Utility methods
  Tag? getTagById(String id) {
    try {
      return _tags.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getAvailableColors() {
    final colorSet = <String>{};
    for (final tag in _tags) {
      if (tag.colorHex != null && tag.colorHex!.isNotEmpty) {
        colorSet.add(tag.colorHex!);
      }
    }
    return colorSet.toList();
  }

  Map<String, int> getColorUsageStats() {
    final colorCounts = <String, int>{};
    for (final tag in _tags) {
      if (tag.colorHex != null && tag.colorHex!.isNotEmpty) {
        colorCounts[tag.colorHex!] = (colorCounts[tag.colorHex!] ?? 0) + 1;
      }
    }
    return colorCounts;
  }

  List<Tag> getTagsByColor(String colorHex) {
    return _tags.where((tag) => tag.colorHex == colorHex).toList();
  }

  // Private helper methods
  void _applyFiltersAndSort() {
    _filteredTags = List.from(_tags);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredTags = _filteredTags.where((tag) =>
        tag.name.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    
    // Apply sorting
    _filteredTags.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case TagSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case TagSortBy.color:
          final aColor = a.colorHex ?? '';
          final bColor = b.colorHex ?? '';
          comparison = aColor.compareTo(bColor);
          break;
      }
      
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    
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

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'tag_$timestamp';
  }

  // Cleanup
  @override
  void dispose() {
    _tags.clear();
    _filteredTags.clear();
    _selectedTagIds.clear();
    super.dispose();
  }
}
