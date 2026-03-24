class Season {
  String id;
  String name;

  Season(this.id, this.name);

  Season.fromJson(Map<String, dynamic> json)
    : id = json['id'] ?? '',
      name = json['name'] ?? '';

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
