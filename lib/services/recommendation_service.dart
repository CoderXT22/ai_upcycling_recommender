import '../mock/mock_data.dart';
import '../models/contamination_warning.dart';
import '../models/diy_guide.dart';
import '../models/disposal_guide.dart';
import '../models/recommendation_result.dart';
import '../models/recycling_centre.dart';
import '../models/sustainability_event.dart';
import '../models/waste_item.dart';
import '../repositories/centre_repository.dart';
import '../repositories/contamination_warning_repository.dart';
import '../repositories/diy_repository.dart';
import '../repositories/disposal_guide_repository.dart';
import '../repositories/event_repository.dart';

class RecommendationService {
  RecommendationService({
    DiyRepository? diyRepository,
    CentreRepository? centreRepository,
    EventRepository? eventRepository,
    DisposalGuideRepository? disposalGuideRepository,
    ContaminationWarningRepository? contaminationWarningRepository,
  }) : _diyRepository = diyRepository ?? DiyRepository(),
       _centreRepository = centreRepository ?? CentreRepository(),
       _eventRepository = eventRepository ?? EventRepository(),
       _disposalGuideRepository =
           disposalGuideRepository ?? DisposalGuideRepository(),
       _contaminationWarningRepository =
           contaminationWarningRepository ?? ContaminationWarningRepository();

  final DiyRepository _diyRepository;
  final CentreRepository _centreRepository;
  final EventRepository _eventRepository;
  final DisposalGuideRepository _disposalGuideRepository;
  final ContaminationWarningRepository _contaminationWarningRepository;

  Future<RecommendationResult> recommend(WasteItem wasteItem) async {
    final guides = await _loadGuides();
    final centres = await _loadCentres();
    final events = await _loadEvents();
    final disposalGuides = await _loadDisposalGuides();
    final warnings = await _loadWarnings();

    final matchedGuides = _rankBySpecificity<DiyGuide>(
      wasteItem: wasteItem,
      items: guides,
      objectTags: (guide) => guide.objectTags,
      materialTags: (guide) => guide.materialTags,
      categoryTags: (guide) => guide.categoryTags,
    );

    final matchedCentres = centres
        .where((centre) => centre.acceptsCategory(wasteItem.category))
        .toList();

    final matchedEvents = _rankBySpecificity<SustainabilityEvent>(
      wasteItem: wasteItem,
      items: events,
      objectTags: (event) => event.materialKeywords,
      materialTags: (event) => event.materialKeywords,
      categoryTags: (event) => event.categoryTags,
    );

    final matchedDisposalGuides = _rankBySpecificity<DisposalGuide>(
      wasteItem: wasteItem,
      items: disposalGuides,
      objectTags: (guide) => guide.objectTags,
      materialTags: (guide) => guide.materialTags,
      categoryTags: (guide) => guide.categoryTags,
    );

    final matchedWarnings = _rankBySpecificity<ContaminationWarning>(
      wasteItem: wasteItem,
      items: warnings,
      objectTags: (warning) => warning.objectTags,
      materialTags: (warning) => warning.materialTags,
      categoryTags: (warning) => warning.categoryTags,
    );

    return RecommendationResult(
      wasteItem: wasteItem,
      guides: matchedGuides,
      centres: matchedCentres,
      events: matchedEvents,
      disposalNote: matchedDisposalGuides.isEmpty
          ? ''
          : matchedDisposalGuides.first.instruction,
      contaminationWarning: matchedWarnings.isEmpty
          ? ''
          : matchedWarnings.first.warning,
    );
  }

  Future<List<DiyGuide>> _loadGuides() async {
    final guides = await _diyRepository.fetchActiveGuides();
    return guides.isEmpty ? mockDiyGuides : guides;
  }

  Future<List<RecyclingCentre>> _loadCentres() async {
    final centres = await _centreRepository.fetchSelangorCentres();
    return centres.isEmpty ? mockCentres : centres;
  }

  Future<List<SustainabilityEvent>> _loadEvents() async {
    final events = await _eventRepository.fetchActiveEvents();
    return events.isEmpty ? mockEvents : events;
  }

  Future<List<DisposalGuide>> _loadDisposalGuides() async {
    final guides = await _disposalGuideRepository.fetchActiveGuides();
    return guides.isEmpty ? mockDisposalGuides : guides;
  }

  Future<List<ContaminationWarning>> _loadWarnings() async {
    final warnings = await _contaminationWarningRepository
        .fetchActiveWarnings();
    return warnings.isEmpty ? mockContaminationWarnings : warnings;
  }

  List<T> _rankBySpecificity<T>({
    required WasteItem wasteItem,
    required List<T> items,
    required List<String> Function(T item) objectTags,
    required List<String> Function(T item) materialTags,
    required List<String> Function(T item) categoryTags,
  }) {
    final scoredItems = items
        .map(
          (item) => (
            _specificityScore(
              wasteItem: wasteItem,
              objectTags: objectTags(item),
              materialTags: materialTags(item),
              categoryTags: categoryTags(item),
            ),
            item,
          ),
        )
        .where((entry) => entry.$1 > 0)
        .toList();

    scoredItems.sort((a, b) => b.$1.compareTo(a.$1));
    return scoredItems.map((entry) => entry.$2).toList();
  }

  int _specificityScore({
    required WasteItem wasteItem,
    required List<String> objectTags,
    required List<String> materialTags,
    required List<String> categoryTags,
  }) {
    var score = 0;
    if (_containsAny(wasteItem.object, objectTags)) score += 30;
    if (_containsAny(wasteItem.material, materialTags)) score += 20;
    if (_matchesCategory(wasteItem.category, categoryTags)) score += 10;
    return score;
  }

  bool _containsAny(String input, List<String> tags) {
    final normalizedInput = input.toLowerCase();
    return tags
        .where((tag) => tag.trim().isNotEmpty)
        .any((tag) => normalizedInput.contains(tag.toLowerCase()));
  }

  bool _matchesCategory(String category, List<String> categoryTags) {
    final normalizedCategory = category.toLowerCase();
    return categoryTags.any((tag) => tag.toLowerCase() == normalizedCategory);
  }
}
