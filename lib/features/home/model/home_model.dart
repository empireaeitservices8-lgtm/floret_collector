class HomeSummaryModel {
  final String userName;
  final String locationArea;
  final String remainingCovers;
  final String weight;
  final String collectedAmount;
  final String sanitaryPickups;
  final String routeDescription;

  const HomeSummaryModel({
    this.userName = '',
    this.locationArea = 'N/A',
    this.remainingCovers = '0/0',
    this.weight = '0.0 kg',
    this.collectedAmount = '₹0',
    this.sanitaryPickups = '0/0',
    this.routeDescription = 'Organic & domestic bio-waste',
  });
}
