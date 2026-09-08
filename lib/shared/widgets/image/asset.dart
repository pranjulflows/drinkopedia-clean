import 'dart:io';

enum AssetType { png, svg,file,network,bytes}


class Asset {
  String path;
  AssetType type;
  File? file;
  Asset({required this.path, required this.type,this.file});
}
