import '../models/community_post.dart';
import '../models/diy_guide.dart';
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
    address: 'Petaling Jaya, Selangor',
    acceptedMaterials: ['plastic', 'paper', 'metal', 'glass'],
    operatingHours: '9:00 AM - 5:00 PM',
    distance: '3.2 km',
    status: 'Accepting',
    lastUpdated: 'Jun 2026',
  ),
  RecyclingCentre(
    id: 'shah-alam-ewaste',
    name: 'Shah Alam E-Waste Drop-Off',
    address: 'Shah Alam, Selangor',
    acceptedMaterials: ['electronic waste', 'metal'],
    operatingHours: '10:00 AM - 6:00 PM',
    distance: '7.8 km',
    status: 'Accepting',
    lastUpdated: 'Jun 2026',
  ),
  RecyclingCentre(
    id: 'klang-donation-hub',
    name: 'Klang Reuse Donation Hub',
    address: 'Klang, Selangor',
    acceptedMaterials: ['fabric', 'paper', 'plastic'],
    operatingHours: '10:00 AM - 4:00 PM',
    distance: '12.4 km',
    status: 'Limited slots',
    lastUpdated: 'May 2026',
  ),
];

const mockEvents = [
  SustainabilityEvent(
    id: 'bottle-drive',
    title: '100 Bottles Coffee Drive',
    organizer: 'GreenBean Cafe',
    description: 'Collect 100 plastic bottles and get a free coffee voucher.',
    date: 'May 30, 2026',
    location: 'Subang Jaya',
    requiredMaterials: 'Clean plastic bottles',
    officialLink: 'https://example.com/bottle-drive',
    joinedCount: 234,
  ),
  SustainabilityEvent(
    id: 'ewaste-day',
    title: 'E-Waste Collection Day',
    organizer: 'KL City Council',
    description: 'Bring old electronics for responsible recycling.',
    date: 'Jun 15, 2026',
    location: 'KLCC Park',
    requiredMaterials: 'Small electronics, chargers, cables',
    officialLink: 'https://example.com/ewaste-day',
    joinedCount: 507,
  ),
  SustainabilityEvent(
    id: 'clothes-voucher',
    title: 'Old Clothes Voucher Drive',
    organizer: 'HNM Recycling',
    description: 'Drop reusable clothes and redeem selected store vouchers.',
    date: 'Jul 8, 2026',
    location: 'Petaling Jaya',
    requiredMaterials: 'Clean old clothes',
    officialLink: 'https://example.com/clothes-drive',
    joinedCount: 188,
  ),
];

const mockPosts = [
  CommunityPost(
    id: 'planter-bottles',
    authorName: 'Sarah K.',
    caption: 'Made this planter from old plastic bottles!',
    timeAgo: '2h ago',
    likeCount: 24,
    commentCount: 5,
    colorLabel: 'Bottle planter',
  ),
  CommunityPost(
    id: 'cat-house',
    authorName: 'Ahmad R.',
    caption: 'Cardboard cat house for my fur baby',
    timeAgo: '5h ago',
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
  ),
  EducationArticle(
    id: 'fabric-reuse',
    title: 'Simple Ways to Reuse Old Fabric',
    summary:
        'Before discarding clothes, try repair, donation, or simple upcycling.',
    category: 'Upcycling',
    readTime: '5 min read',
  ),
  EducationArticle(
    id: 'plastic-codes',
    title: 'Understanding Plastic Labels',
    summary: 'A quick guide to reading common plastic recycling symbols.',
    category: 'Waste Sorting',
    readTime: '3 min read',
  ),
];
