## *serialport* - Nim bindings for libserialport, the cross-platform serial
## communication library.
##
## This file is part of the `Nim I/O <http://nimio.us>`_ package collection.
## See the file LICENSE included in this distribution for licensing details.
## GitHub pull requests are encouraged. (c) 2015 Headcrash Industries LLC.

import libserialport


# The following program is a basic example of using `libusb` to enumerate
# available serial ports.

var ports: ptr SpPortList


# enumerate ports
let listPortsResult = spListPorts(addr ports)
case listPortsResult
of SpReturn.errSup:
  echo "Failed to enumerate ports: Operation not supported on this system"
of SpReturn.errMem:
  echo "Failed to enumerate ports: Memory allocation failed"
of SpReturn.errFail:
  echo "Failed to enumerate ports: System error"
of SpReturn.errArg:
  echo "Failed to enumerate ports: Invalid arguments"
of SpReturn.ok:
  for i in 0..high(ports[]):
    let port = ports[i]
    if port == nil:
      break
    echo "Details for port #", i
    let name = spGetPortName(port)
    if name != nil:
      echo "  Name: ", name
    let description = spGetPortDescription(port)
    if description != nil:
      echo "  Description: ", description
    let transport = spGetPortTransport(port)
    case transport
    of SpTransport.native:
      echo "  Transport: native"
    of SpTransport.usb:
      echo "  Transport: usb"
      var bus, address: cint
      if spGetPortUsbBusAddress(port, addr bus, addr address) == SpReturn.ok:
        echo "    Bus: ", bus, ", Address: ", address
      let manufacturer = spGetPortUsbManufacturer(port)
      if manufacturer != nil:
        echo "    Manufacturer: ", manufacturer
      let product = spGetPortUsbProduct(port)
      if product != nil:
        echo "    Product: ", product
      let serial = spGetPortUsbSerial(port)
      if serial != nil:
        echo "    Serial: ", spGetPortUsbSerial(port)
    of SpTransport.bluetooth:
      echo "  Transport: bluetooth"
      let address = spGetPortBluetoothAddress(port)
      if address != nil:
        echo "    Address: ", address
    else:
      echo "  Transport: unknown (", ord(transport), ")"
  spFreePortList(ports)
else:
  echo "Failed to enumerate ports: Unknown error (", ord(listPortsResult), ")"
