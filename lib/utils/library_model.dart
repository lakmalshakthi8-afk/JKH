// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class LibraryModel {
  final DateTime date;
  final List<String?> images;
  final List<String?> results;
  final List<String?> probabilities;
  final String? supplier;
  final List<String?> weight;

  LibraryModel(
    this.date,
    this.images,
    this.results,
    this.probabilities,
    this.supplier,
    this.weight,
  );

  LibraryModel copyWith({
    DateTime? date,
    List<String?>? images,
    List<String?>? results,
    List<String?>? probabilities,
    String? supplier,
    List<String?>? weight,
  }) {
    return LibraryModel(
      date ?? this.date,
      images ?? this.images,
      results ?? this.results,
      probabilities ?? this.probabilities,
      supplier ?? this.supplier,
      weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date.millisecondsSinceEpoch,
      'images': images,
      'results': results,
      'probabilities': probabilities,
      'supplier': supplier,
      'weight': weight,
    };
  }

  factory LibraryModel.fromMap(Map<String, dynamic> map) {
    return LibraryModel(
      DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      (map['images'] as List<dynamic>?)?.map((e) => e as String?).toList() ??
          [],
      (map['results'] as List<dynamic>?)?.map((e) => e as String?).toList() ??
          [],
      (map['probabilities'] as List<dynamic>?)
              ?.map((e) => e as String?)
              .toList() ??
          [],
      map['supplier'] as String,
      (map['weight'] as List<dynamic>?)?.map((e) => e as String?).toList() ??
          [],
    );
  }

  String toJson() => json.encode(toMap());

  factory LibraryModel.fromJson(String source) =>
      LibraryModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LibraryModel(date: $date, images: $images, results: $results, supplier: $supplier, weight:$weight)';
  }

  @override
  bool operator ==(covariant LibraryModel other) {
    if (identical(this, other)) return true;

    return other.date == date &&
        listEquals(other.images, images) &&
        listEquals(other.results, results) &&
        other.supplier == supplier;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        images.hashCode ^
        results.hashCode ^
        supplier.hashCode;
  }
}

class SupplierModel {
  final String name;
  final String code;
  final String item;

  SupplierModel(
    this.name,
    this.code,
    this.item,
  );

  SupplierModel copyWith({
    String? name,
    String? code,
    String? item,
  }) {
    return SupplierModel(
      name ?? this.name,
      code ?? this.code,
      item ?? this.item,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'item': item,
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      map['name'] as String,
      map['code'] as String,
      map['item'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SupplierModel.fromJson(String source) =>
      SupplierModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SupplierModel(name: $name, code: $code, item: $item)';

  @override
  bool operator ==(covariant SupplierModel other) {
    if (identical(this, other)) return true;

    return other.name == name && other.code == code && other.item == item;
  }

  @override
  int get hashCode => name.hashCode ^ code.hashCode ^ item.hashCode;
}
