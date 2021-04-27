class Aya {
  int id;
  String date;
  String aya;

  Aya({this.date, this.aya, this.id});

  Map<String, Object> toMap() {
    var map = <String, Object>{
      'date': date,
      'aya': aya,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  Aya.fromMap(Map<String, Object> map) {
    id = map['id'];
    date = map['date'];
    aya = map['aya'];
  }
}
