class SplashModel {
  final bool isReady;
  final String? version;
  final bool isAuthenticated;

  const SplashModel({
    this.isReady = false,
    this.version,
    this.isAuthenticated = false,
  });

  SplashModel copyWith({
    bool? isReady,
    String? version,
    bool? isAuthenticated,
  }) {
    return SplashModel(
      isReady: isReady ?? this.isReady,
      version: version ?? this.version,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
