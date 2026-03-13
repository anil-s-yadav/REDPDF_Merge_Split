import 'dart:convert';

class PdfFile {
  final String name;
  final String date;
  final String size;
  final String? path;
  final int? pages;
  final bool isMerge;

  const PdfFile({
    required this.name,
    required this.date,
    required this.size,
    this.path,
    this.pages,
    this.isMerge = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date,
        'size': size,
        'path': path,
        'pages': pages,
        'isMerge': isMerge,
      };

  static PdfFile fromJson(Map<String, dynamic> json) => PdfFile(
        name: (json['name'] as String?) ?? 'Unknown.pdf',
        date: (json['date'] as String?) ?? '',
        size: (json['size'] as String?) ?? '',
        path: json['path'] as String?,
        pages: json['pages'] as int?,
        isMerge: (json['isMerge'] as bool?) ?? true,
      );
}

class PdfJobResult {
  final bool isSplit;
  final String? inputPath;
  final String? outputPath; // merge output, or zip output
  final List<String> outputPaths; // split outputs
  final String? zipPath;

  const PdfJobResult({
    required this.isSplit,
    this.inputPath,
    this.outputPath,
    this.outputPaths = const [],
    this.zipPath,
  });

  Map<String, dynamic> toJson() => {
        'isSplit': isSplit,
        'inputPath': inputPath,
        'outputPath': outputPath,
        'outputPaths': outputPaths,
        'zipPath': zipPath,
      };

  static PdfJobResult fromJson(Map<String, dynamic> json) => PdfJobResult(
        isSplit: (json['isSplit'] as bool?) ?? false,
        inputPath: json['inputPath'] as String?,
        outputPath: json['outputPath'] as String?,
        outputPaths: ((json['outputPaths'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        zipPath: json['zipPath'] as String?,
      );

  static String encodeList(List<PdfFile> files) =>
      jsonEncode(files.map((e) => e.toJson()).toList());

  static List<PdfFile> decodeFileList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => PdfFile.fromJson(m.cast<String, dynamic>()))
        .toList();
  }
}

class PdfPasswordRequired implements Exception {
  final String path;
  final String name;

  const PdfPasswordRequired({required this.path, required this.name});

  @override
  String toString() => 'PdfPasswordRequired(name: $name, path: $path)';
}


class PageRange {
  final int from; // 1-based inclusive
  final int to; // 1-based inclusive

  const PageRange(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRange &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}
