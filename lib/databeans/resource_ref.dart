class ResourceRef {
  final String? name;
  final String? displayName;
  final String? path;
  //是否为全局资源
  bool globalResource = false;

  ResourceRef({
    required this.name,
    required this.displayName,
    required this.path,
    this.globalResource = false,
  });
}
