class AmneziaSettings {
  AmneziaSettings({
    required this.jc,
    required this.jmin,
    required this.jmax,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
  });

  final int jc;
  final int jmin;
  final int jmax;
  final int s1;
  final int s2;
  final int s3;
  final int s4;
  final int h1;
  final int h2;
  final int h3;
  final int h4;

  Map<String, dynamic> toJson() => {
    'jc': jc,
    'jmin': jmin,
    'jmax': jmax,
    's1': s1,
    's2': s2,
    's3': s3,
    's4': s4,
    'h1': h1,
    'h2': h2,
    'h3': h3,
    'h4': h4,
  };
}
