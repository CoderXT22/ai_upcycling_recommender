import 'diy_guide.dart';
import 'recycling_centre.dart';
import 'sustainability_event.dart';
import 'waste_item.dart';

class RecommendationResult {
  const RecommendationResult({
    required this.wasteItem,
    required this.guides,
    required this.centres,
    required this.events,
    required this.disposalNote,
    required this.contaminationWarning,
  });

  final WasteItem wasteItem;
  final List<DiyGuide> guides;
  final List<RecyclingCentre> centres;
  final List<SustainabilityEvent> events;
  final String disposalNote;
  final String contaminationWarning;
}
