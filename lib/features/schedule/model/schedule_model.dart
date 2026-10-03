class ScheduleModel {
  final String dateText;
  final String progressText;
  final String sanitaryPickups;
  final String scrapPickups;
  final String wasteType;
  final double progressPercent;
  final List<dynamic> pickups;

  const ScheduleModel({
    this.dateText = 'Wed, 30th Sep',
    this.progressText = '0 of 0 completed',
    this.sanitaryPickups = '0/0',
    this.scrapPickups = '0/0',
    this.wasteType = 'Sanitary & Scrap waste',
    this.progressPercent = 0.0,
    this.pickups = const [],
  });
}
