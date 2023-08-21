class BluetoothDevice{
  final String name;
  final String address;

  BluetoothDevice({required this.name, required this.address});

  @override
  String toString() {
    return address;
  }
}