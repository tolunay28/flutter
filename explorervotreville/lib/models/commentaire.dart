class Commentaire {
  final int? id;
  final int lieuId; // FK vers lieux.id
  final String texte;
  final double note;
  final DateTime date;

  Commentaire({
    this.id,
    required this.lieuId,
    required this.texte,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'lieuId': lieuId,
    'texte': texte,
    'note': note,
    'date': date.millisecondsSinceEpoch,
  };

  factory Commentaire.fromMap(Map<String, dynamic> map) {
    return Commentaire(
      id: map['id'] as int,
      lieuId: map['lieuId'] as int,
      texte: map['texte'] as String,
      note: (map['note'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  } // permet de stocker un int pour la date lorsqu'on va l'utiliser on va le retransformer en date

  Commentaire copyWith({int? id}) => Commentaire(
    id: id ?? this.id,
    lieuId: lieuId,
    texte: texte,
    note: note,
    date: date,
  );
}
