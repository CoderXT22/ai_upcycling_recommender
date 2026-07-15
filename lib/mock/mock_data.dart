import '../models/community_post.dart';
import '../models/contamination_warning.dart';
import '../models/diy_guide.dart';
import '../models/disposal_guide.dart';
import '../models/education_article.dart';
import '../models/recycling_centre.dart';
import '../models/sustainability_event.dart';

const mockDiyGuides = [
  DiyGuide(
    id: 'cardboard-desk-organizer',
    title: 'Cardboard Desk Organizer',
    description: 'Turn cardboard boxes into a tidy organizer for study items.',
    materialTags: ['paper', 'cardboard'],
    materialsNeeded: ['Cardboard box', 'Glue', 'Paint', 'Ruler'],
    steps: [
      'Cut cardboard into equal side panels.',
      'Assemble compartments using glue.',
      'Paint or decorate the outer surface.',
      'Let it dry before using it on your desk.',
    ],
    difficultyLevel: 'Easy',
    estimatedTime: '45 min',
    savedCount: 95,
  ),
  DiyGuide(
    id: 'glass-jar-terrarium',
    title: 'Glass Jar Terrarium',
    description: 'Reuse empty glass jars as mini indoor planters.',
    materialTags: ['glass'],
    materialsNeeded: [
      'Glass jar',
      'Pebbles',
      'Charcoal',
      'Moss',
      'Small plants',
    ],
    steps: [
      'Clean and dry the jar.',
      'Layer pebbles, charcoal, and soil.',
      'Place moss or small plants inside.',
      'Mist lightly and keep near indirect light.',
    ],
    difficultyLevel: 'Medium',
    estimatedTime: '1.5 hrs',
    savedCount: 173,
  ),
  DiyGuide(
    id: 'old-shirt-tote',
    title: 'Old T-Shirt Tote Bag',
    description: 'Convert an old shirt into a reusable shopping tote.',
    materialTags: ['fabric'],
    materialsNeeded: ['Old t-shirt', 'Scissors', 'Needle', 'Thread'],
    steps: [
      'Cut off the sleeves and neckline.',
      'Turn the shirt inside out.',
      'Stitch or knot the bottom edge.',
      'Turn it back and use it as a tote.',
    ],
    difficultyLevel: 'Easy',
    estimatedTime: '30 min',
    savedCount: 121,
  ),
];

const mockCentres = [
  RecyclingCentre(
    id: 'pj-eco-centre',
    name: 'PJ Eco Recycling Centre',
    centreType: 'recycling',
    address: 'Petaling Jaya, Selangor',
    state: 'Selangor',
    area: 'Petaling Jaya',
    acceptedCategories: ['plastic', 'paper', 'metal', 'glass'],
    acceptedMaterials: ['plastic', 'paper', 'metal', 'glass'],
    operatingHours: '9:00 AM - 5:00 PM',
    officialLink: 'https://example.com/pj-eco-centre',
    distance: '3.2 km',
    status: 'accepting',
    lastVerifiedAt: 'Jun 2026',
    lastUpdated: 'Jun 2026',
  ),
  RecyclingCentre(
    id: 'shah-alam-ewaste',
    name: 'Shah Alam E-Waste Drop-Off',
    centreType: 'recycling',
    address: 'Shah Alam, Selangor',
    state: 'Selangor',
    area: 'Shah Alam',
    acceptedCategories: ['electronic_waste', 'metal'],
    acceptedMaterials: ['electronic waste', 'metal'],
    operatingHours: '10:00 AM - 6:00 PM',
    officialLink: 'https://example.com/shah-alam-ewaste',
    distance: '7.8 km',
    status: 'accepting',
    lastVerifiedAt: 'Jun 2026',
    lastUpdated: 'Jun 2026',
  ),
  RecyclingCentre(
    id: 'klang-donation-hub',
    name: 'Klang Reuse Donation Hub',
    centreType: 'donation',
    address: 'Klang, Selangor',
    state: 'Selangor',
    area: 'Klang',
    acceptedCategories: ['fabric', 'paper', 'plastic'],
    acceptedMaterials: ['fabric', 'paper', 'plastic'],
    operatingHours: '10:00 AM - 4:00 PM',
    officialLink: 'https://example.com/klang-donation-hub',
    distance: '12.4 km',
    status: 'limited',
    lastVerifiedAt: 'May 2026',
    lastUpdated: 'May 2026',
  ),
];

const mockEvents = [
  SustainabilityEvent(
    id: 'bottle-drive',
    title: '100 Bottles Coffee Drive',
    organizer: 'GreenBean Cafe',
    description: 'Collect 100 plastic bottles and get a free coffee voucher.',
    benefit: 'Free coffee voucher for eligible bottle collection.',
    date: 'May 30, 2026',
    locationName: 'Subang Jaya',
    requiredMaterials: ['Clean plastic bottles'],
    categoryTags: ['plastic'],
    materialKeywords: ['plastic', 'bottle'],
    officialLink: 'https://example.com/bottle-drive',
    joinedCount: 234,
  ),
  SustainabilityEvent(
    id: 'ewaste-day',
    title: 'E-Waste Collection Day',
    organizer: 'KL City Council',
    description: 'Bring old electronics for responsible recycling.',
    benefit: 'Safe disposal for household e-waste.',
    date: 'Jun 15, 2026',
    locationName: 'KLCC Park',
    requiredMaterials: ['Small electronics', 'Chargers', 'Cables'],
    categoryTags: ['electronic_waste'],
    materialKeywords: ['electronic', 'charger', 'cable'],
    officialLink: 'https://example.com/ewaste-day',
    joinedCount: 507,
  ),
  SustainabilityEvent(
    id: 'clothes-voucher',
    title: 'Old Clothes Voucher Drive',
    organizer: 'HNM Recycling',
    description: 'Drop reusable clothes and redeem selected store vouchers.',
    benefit: 'Voucher redemption for accepted reusable clothes.',
    date: 'Jul 8, 2026',
    locationName: 'Petaling Jaya',
    requiredMaterials: ['Clean old clothes'],
    categoryTags: ['fabric'],
    materialKeywords: ['clothes', 'fabric'],
    officialLink: 'https://example.com/clothes-drive',
    joinedCount: 188,
  ),
];

const mockDisposalGuides = [
  DisposalGuide(
    id: 'clean-plastic-recycling',
    title: 'Clean plastic recycling',
    categoryTags: ['plastic'],
    materialTags: ['plastic', 'pet plastic'],
    objectTags: ['bottle', 'container'],
    instruction:
        'Rinse and dry the plastic item before recycling. If it is oily, dirty, or not accepted by the centre, dispose of it as general waste.',
  ),
  DisposalGuide(
    id: 'fabric-reuse-donation',
    title: 'Fabric reuse or donation',
    categoryTags: ['fabric'],
    materialTags: ['fabric', 'cotton', 'denim'],
    objectTags: ['shirt', 'clothes', 'jeans'],
    instruction:
        'Donate clean and usable fabric items where accepted. If the item is wet, mouldy, or heavily stained, dispose of it as general waste.',
  ),
  DisposalGuide(
    id: 'ewaste-dropoff',
    title: 'E-waste drop-off',
    categoryTags: ['electronic_waste'],
    materialTags: ['electronic', 'electronic parts'],
    objectTags: ['charger', 'phone', 'cable', 'battery'],
    instruction:
        'Do not throw e-waste into normal rubbish bins. Bring it to an e-waste collection point or approved recycling centre.',
  ),
];

const mockContaminationWarnings = [
  ContaminationWarning(
    id: 'dirty-plastic-contamination',
    title: 'Dirty plastic contamination',
    categoryTags: ['plastic'],
    materialTags: ['plastic', 'pet plastic'],
    objectTags: ['bottle', 'container'],
    warning:
        'Plastic with food or drink residue may contaminate other recyclable materials.',
  ),
  ContaminationWarning(
    id: 'wet-fabric-warning',
    title: 'Wet fabric warning',
    categoryTags: ['fabric'],
    materialTags: ['fabric', 'cotton', 'denim'],
    objectTags: ['shirt', 'clothes', 'jeans'],
    warning:
        'Wet, mouldy, or heavily stained fabric is usually not suitable for donation and may contaminate reusable clothing collections.',
  ),
  ContaminationWarning(
    id: 'battery-ewaste-warning',
    title: 'Battery and e-waste warning',
    categoryTags: ['electronic_waste'],
    materialTags: ['electronic', 'electronic parts'],
    objectTags: ['battery', 'phone', 'charger'],
    severity: 'high',
    warning:
        'Electronic waste may contain hazardous components and should not be mixed with general household waste.',
  ),
];

const mockPosts = [
  CommunityPost(
    id: 'planter-bottles',
    userId: 'sample-user',
    authorName: 'Sarah K.',
    caption: 'Made this planter from old plastic bottles!',
    createdAtText: '2h ago',
    likeCount: 24,
    commentCount: 5,
    colorLabel: 'Bottle planter',
  ),
  CommunityPost(
    id: 'cat-house',
    userId: 'sample-user',
    authorName: 'Ahmad R.',
    caption: 'Cardboard cat house for my fur baby',
    createdAtText: '5h ago',
    likeCount: 42,
    commentCount: 8,
    colorLabel: 'Cardboard shelter',
  ),
];

const mockArticles = [
  EducationArticle(
    id: 'wishcycling',
    title: 'What is Wish-Cycling?',
    summary:
        'Learn why placing uncertain items into recycling bins can cause contamination.',
    category: 'Recycling',
    readTime: '4 min read',
    sourceTitle: 'EcoLoop sample content',
    sourceType: 'Guide',
  ),
  EducationArticle(
    id: 'fabric-reuse',
    title: 'Simple Ways to Reuse Old Fabric',
    summary:
        'Before discarding clothes, try repair, donation, or simple upcycling.',
    category: 'Upcycling',
    readTime: '5 min read',
    sourceTitle: 'EcoLoop sample content',
    sourceType: 'Guide',
  ),
  EducationArticle(
    id: 'plastic-codes',
    title: 'Understanding Plastic Labels',
    summary: 'A quick guide to reading common plastic recycling symbols.',
    category: 'Waste Sorting',
    readTime: '3 min read',
    sourceTitle: 'EcoLoop sample content',
    sourceType: 'Guide',
  ),
];
