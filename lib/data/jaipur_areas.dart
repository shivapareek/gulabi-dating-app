import 'dart:math';

/// Jaipur localities with approximate coordinates, used for distance filters
/// instead of live GPS (safer for users, works without location permission).
const Map<String, List<double>> jaipurAreas = {
  'C-Scheme': [26.9045, 75.8016],
  'Malviya Nagar': [26.8549, 75.8243],
  'Vaishali Nagar': [26.9124, 75.7435],
  'Mansarovar': [26.8505, 75.7628],
  'Raja Park': [26.8986, 75.8295],
  'Jagatpura': [26.8221, 75.8622],
  'Tonk Road': [26.8530, 75.8040],
  'Sodala': [26.9030, 75.7720],
  'Bani Park': [26.9295, 75.7890],
  'Civil Lines': [26.9056, 75.7860],
  'Shyam Nagar': [26.8890, 75.7610],
  'Pratap Nagar': [26.8000, 75.8240],
  'Sitapura': [26.7780, 75.8410],
  'Jhotwara': [26.9530, 75.7400],
  'Vidhyadhar Nagar': [26.9590, 75.7780],
  'Adarsh Nagar': [26.9020, 75.8350],
  'Walled City': [26.9239, 75.8267],
  'Amer': [26.9855, 75.8513],
  'Durgapura': [26.8510, 75.7880],
  'Gopalpura': [26.8740, 75.7790],
  'Ajmer Road': [26.8960, 75.7300],
  'Sanganer': [26.8200, 75.7920],
};

double distanceKm(String a, String b) {
  final p = jaipurAreas[a], q = jaipurAreas[b];
  if (p == null || q == null) return 0;
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(q[0] - p[0]), dLon = rad(q[1] - p[1]);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(p[0])) * cos(rad(q[0])) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * r * asin(sqrt(h));
}

const allInterests = [
  'Travel', 'Food', 'Music', 'Movies', 'Fitness', 'Yoga', 'Cricket',
  'Photography', 'Reading', 'Dancing', 'Cafe hopping', 'Art', 'Fashion',
  'Gaming', 'Trekking', 'Cooking', 'Startups', 'Spirituality', 'Pets',
  'Road trips', 'Poetry', 'Shopping', 'Bollywood', 'Netflix',
];

const allPrompts = [
  'My ideal Sunday in Jaipur',
  'Best kachori in town is at',
  'I will fall for you if',
  'A perfect first date',
  'My love language is',
  'Two truths and a lie',
];
