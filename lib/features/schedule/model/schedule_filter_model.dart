enum PickupTypeFilter {
  all,
  sanitary,
  scrap;

  String get label {
    switch (this) {
      case PickupTypeFilter.all:
        return 'Select all';
      case PickupTypeFilter.sanitary:
        return 'Sanitary pickups';
      case PickupTypeFilter.scrap:
        return 'Scrap pickups';
    }
  }

  String get wasteTypeLabel {
    switch (this) {
      case PickupTypeFilter.all:
        return 'Sanitary & Scrap waste';
      case PickupTypeFilter.sanitary:
        return 'Sanitary waste';
      case PickupTypeFilter.scrap:
        return 'Scrap waste';
    }
  }
}

enum CollectionStatusFilter {
  all,
  pending,
  completed;

  String get label {
    switch (this) {
      case CollectionStatusFilter.all:
        return 'Select all';
      case CollectionStatusFilter.pending:
        return 'Only pending pickups';
      case CollectionStatusFilter.completed:
        return 'Only completed pickups';
    }
  }
}

class ScheduleFilterModel {
  final PickupTypeFilter pickupType;
  final CollectionStatusFilter collectionStatus;

  const ScheduleFilterModel({
    this.pickupType = PickupTypeFilter.all,
    this.collectionStatus = CollectionStatusFilter.all,
  });

  bool get isDefault =>
      pickupType == PickupTypeFilter.all &&
      collectionStatus == CollectionStatusFilter.all;

  ScheduleFilterModel copyWith({
    PickupTypeFilter? pickupType,
    CollectionStatusFilter? collectionStatus,
  }) {
    return ScheduleFilterModel(
      pickupType: pickupType ?? this.pickupType,
      collectionStatus: collectionStatus ?? this.collectionStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleFilterModel &&
          runtimeType == other.runtimeType &&
          pickupType == other.pickupType &&
          collectionStatus == other.collectionStatus;

  @override
  int get hashCode => pickupType.hashCode ^ collectionStatus.hashCode;
}
