## *serialport* - Nim bindings for libserialport, the cross-platform serial
## communication library.
##
## This file is part of the `Nim I/O <http://nimio.us>`_ package collection.
## See the file LICENSE included in this distribution for licensing details.
## GitHub pull requests are encouraged. (c) 2015 Headcrash Industries LLC.

{.deadCodeElim: on.}

when defined(linux):
  const dllname = "libserialport.so"
elif defined(macosx):
  const dllname = "libserialport.dylib"
elif defined(windows):
  const dllname = "libserialport.dll"
else:
  {.error: "io-serialport does not support this platform".}


type
  SpReturn* {.pure.} = enum
    ## Return values.
    errSup = - 4,
      ## The requested operation is not supported by this system or device.
    errMem = - 3,
      ## A memory allocation failed while executing the operation.
    errFail = - 2,
      ## A system error occurred while executing the operation.
    errArg = - 1,
      ## Invalid arguments were passed to the function.
    ok = 0
      ## Operation completed successfully.


  SpMode* {.pure.} = enum
    ## Port access modes.
    read = 1, ## Open port for read access.
    write = 2, ## Open port for write access.
    readWrite = 3 ## Open port for read and write access.


  SpEvent* {.pure.} = enum
    ## Port events.
    rxReady = 1, ## Data received and ready to read.
    txReady = 2, ## Ready to transmit new data.
    error = 4 ## Error occurred.


  SpBuffer* {.pure.} = enum
    ## Buffer selection.
    input = 1, ## Input buffer.
    output = 2, ## Output buffer.
    both = 3 ## Both buffers.


  SpParity* {.pure.} = enum
    ## Parity settings.
    invalid = - 1, ## Special value to indicate setting should be left alone.
    none = 0, ## No parity.
    odd = 1, ## Odd parity.
    even = 2, ## Even parity.
    mark = 3, ## Mark parity.
    space = 4 ## Space parity.


  SpRts* {.pure.} = enum
    ## RTS pin behaviour.
    invalid = - 1, ## Special value to indicate setting should be left alone.
    off = 0, ## RTS off.
    on = 1, ## RTS on.
    flowControl = 2 ## RTS used for flow control.


  SpCts* {.pure.} = enum
    ## CTS pin behaviour.
    invalid = - 1, ## Special value to indicate setting should be left alone.
    ignore = 0, ## CTS ignored.
    flowControl = 1 ## CTS used for flow control.


  SpDtr* {.pure.} = enum
    ## DTR pin behaviour.
    invalid = - 1, ## Special value to indicate setting should be left alone.
    off = 0, ## DTR off.
    on = 1, ## DTR on.
    flowControl = 2## DTR used for flow control.


  SpDsr* {.pure.} = enum
    ## DSR pin behaviour.
    invalid = - 1, ## Special value to indicate setting should be left alone.
    ignore = 0, ## DSR ignored.
    flowControl = 1 ## DSR used for flow control.


  SpXonXoff* {.pure.} = enum
    ## XON/XOFF flow control behaviour.
    invalid = - 1, ## Special value to indicate setting should be left alone.
    disabled = 0, ## XON/XOFF disabled.
    inputOnly = 1, ## XON/XOFF enabled for input only.
    outputOnly = 2, ## XON/XOFF enabled for output only.
    inputOutput = 3 ## XON/XOFF enabled for input and output.


  SpFlowControl* {.pure.} = enum
    ## Standard flow control combinations.
    none = 0, ## No flow control.
    xonXoff = 1, ## Software flow control using XON/XOFF characters.
    rtsCts = 2, ## Hardware flow control using RTS/CTS signals.
    dtrDsr = 3 ## Hardware flow control using DTR/DSR signals.


  SpSignal* {.pure.} = enum
    ## Input signals.
    cts = 1, ## Clear to send.
    dsr = 2, ## Data set ready.
    dcd = 4, ## Data carrier detect.
    ri = 8 ## Ring indicator.


  SpTransport* {.pure.} = enum
    ## Transport types.
    native, ## Native platform serial port.
    usb, ## USB serial port adapter.
    bluetooth ## Bluetooth serial port adapter.


type
  SpPort* = object
    ## An opaque structure representing a serial port.

  SpPortList* {.unchecked.} = array[10_000, ptr SpPort]
    ## A list of pointers to serial port structures.

  SpPortConfig* = object
    ## An opaque structure representing the configuration for a serial port.

  SpEventSet* = object
    ## A set of handles to wait on for events.
    handles*: pointer
      ## Array of OS-specific handles.
    masks*: ptr SpEvent
      ## Array of bitmasks indicating which events apply for each handle.
    count*: cuint
      ## Number of handles.


# Port enumeration

proc spGetPortByName*(portname: cstring; portPtr: ptr ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_port_by_name".}
  ## Obtain a pointer to a new SpPort structure representing the named port.
  ##
  ## portPtr
  ##   Will contain the pointer to the structure
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of `SpPort <#SpPort>`_ and pass a
  ## pointer to this to receive the result.
  ##
  ## The result should be freed after use by calling `spFreePort <#spFreePort>`_.
  ##
  ## If any error is returned, the variable pointed to by port_ptr will be set
  ## to `nil`. Otherwise, it will be set to point to the newly allocated port.


proc spFreePort*(port: ptr SpPort)
  {.cdecl, dynlib: dllname, importc: "sp_free_port".}
  ## Free a port structure obtained from spGetPortByName() or
  ## `spCopyPort <#spCopyPort>`_.
  ##
  ## port
  ##   Pointer to the port structure to free


proc spListPorts*(listPtr: ptr ptr SpPortList): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_list_ports".}
  ## List the serial ports available on the system.
  ##
  ## listPtr
  ##   Will hold a pointer to the list of ports
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The result obtained is an array of pointers to SpPort structures,
  ## terminated by a `nil`. The user should allocate a variable of type
  ## `SpPort <#SpPort>`_ and pass a pointer to this to receive the result.
  ##
  ## The result should be freed after use by calling
  ## `spFreePortList <#spFreePortList>`_. If a port from the list is to be used
  ## after freeing the list, it must be copied first using
  ## `spCopyPort <#spCopyPort>`_.
  ##
  ## If any error is returned, the variable pointed to by `listPtr` will be set
  ## to `nil`. Otherwise, it will be set to point to the newly allocated array.


proc spCopyPort*(port: ptr SpPort; copyPtr: ptr ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_copy_port".}
  ## Make a new copy of a SpPort structure.
  ##
  ## port
  ##   The port structure to copy
  ## copyPtr
  ##   Will hold a pointer to the copy
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The copy should be freed after use by calling `spFreePort <#spFreePort>`_.
  ## If any error is returned, the variable pointed to by copy_ptr will be set
  ## to `nil`. Otherwise, it will be set to point to the newly allocated copy.


proc spFreePortList*(ports: ptr SpPortList)
  {.cdecl, dynlib: dllname, importc: "sp_free_port_list".}
  ## Free a port list obtained from `spListPorts <#spListPorts>`_.
  ##
  ## port
  ##   The port list to free.
  ##
  ## This will also free all the SpPort structures referred to from the list;
  ## any that are to be retained must be copied first using
  ## `spCopyPort <#spCopyPort>`_.


# Opening, closing and querying ports

proc spOpen*(port: ptr SpPort; flags: SpMode): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_open".}
  ## Open the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## flags
  ##   Flags to use when opening the serial port
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spClose*(port: ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_close".}
  ## Close the specified serial port.
  ##
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetPortName*(port: ptr SpPort): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_port_name".}
  ## Get the name of a port.
  ##
  ## The name returned is whatever is normally used to refer to a port on the
  ## current operating system; e.g. for Windows it will usually be a "COMn"
  ## device name, and for Unix it will be a device path beginning with "/dev/".
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - The port name
  ##   - `nil` if an invalid port is passed
  ##
  ## The name string is part of the port structure and may not be used after the
  ##  port structure has been freed.


proc spGetPortDescription*(port: ptr SpPort): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_port_description".}
  ## Get a description for a port, to present to end user.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - The port description
  ##   - `nil` if an invalid port is passed
  ##
  ## The description string is part of the port structure and may not be used
  ## after the port structure has been freed.


proc spGetPortTransport*(port: ptr SpPort): SpTransport
  {.cdecl, dynlib: dllname, importc: "sp_get_port_transport".}
  ## Get the transport typeused by a port.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   The port transport type


proc spGetPortUsbBusAddress*(port: ptr SpPort; usbBus: ptr cint;
  usbAddress: ptr cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_port_usb_bus_address".}
  ## Get the USB bus number and address on bus of a USB serial adapter port.
  ##
  ## port
  ##   Pointer to port structure
  ## usbBus
  ##   Pointer to variable to store USB bus
  ## usbAddress
  ##   Pointer to variable to store USB address
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc sp_get_port_usb_vid_pid*(port: ptr SpPort; usbVid: ptr cint;
  usbPid: ptr cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_port_usb_vid_pid".}
  ## Get the USB Vendor ID and Product ID of a USB serial adapter port.
  ##
  ## port
  ##   Pointer to port structure
  ## usbVid
  ##   Pointer to variable to store USB VID
  ## usbPid
  ##   Pointer to variable to store USB PID
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetPortUsbManufacturer*(port: ptr SpPort): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_port_usb_manufacturer".}
  ## Get the USB manufacturer string of a USB serial adapter port.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - The port manufacturer string
  ##   - `nil` if an invalid port is passed
  ##
  ## The manufacturer string is part of the port structure and may not be used
  ## after the port structure has been freed.


proc spGetPortUsbProduct*(port: ptr SpPort): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_port_usb_product".}
  ## Get the USB product string of a USB serial adapter port.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - The port product string
  ##   - `nil` if an invalid port is passed
  ##
  ## The product string is part of the port structure and may not be used after
  ## the port structure has been freed.


proc spGetPortUsbSerial*(port: ptr SpPort): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_port_usb_serial".}
  ## Get the USB serial number string of a USB serial adapter port.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - The port serial number
  ##   - `nil` if an invalid port is passed
  ##
  ## The serial number string is part of the port structure and may not be used
  ## after the port structure has been freed.


proc spGetPortBluetoothAddress*(port: ptr SpPort): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_port_bluetooth_address".}
  ## Get the MAC address of a Bluetooth serial adapter port.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   The port MAC address, or `nil` if an invalid port is passed.
  ##
  ## The MAC address string is part of the port structure and may not be used
  ## after the port structure has been freed.


proc spGetPortHandle*(port: ptr SpPort; resultPtr: pointer): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_port_handle".}
  ## Get the operating system handle for a port.
  ##
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The type of the handle depends on the operating system. On Unix based
  ## systems, the handle is a file descriptor of type `int`. On Windows, the
  ## handle is of type `HANDLE`. The user should allocate a variable of the
  ## appropriate typeand pass a pointer to this to receive the result.
  ##
  ## To obtain a valid handle, the port must first be opened by calling
  ## `spOpen <#spOpen>`_ using the same port structure. After the port is closed
  ## or the port structure freed, the handle may no longer be valid.
  ##
  ## Warning: This feature is provided so that programs may make use of
  ## OS-specific functionality where desired. Doing so obviously comes at a cost
  ## in portability. It also cannot be guaranteed that direct usage of the OS
  ## handle will not conflict with the library's own usage of the port.
  ## Be careful.


# Configuration

proc spNewConfig*(config_ptr: ptr ptr SpPortConfig): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_new_config".}
  ## Allocate a port configuration structure.
  ##
  ##
  ## configPtr
  ##   Pointer to variable to receive result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of type `SpConfig <#SpConfig>`_ and
  ## pass a pointer to this to receive the result. The variable will be updated
  ## to point to the new configuration structure. The structure is opaque and
  ## must be accessed via the functions provided.
  ##
  ## All parameters in the structure will be initialised to special values which
  ## are ignored by `spSetConfig <#spSetConfig>`_. The structure should be freed
  ## after use by calling `spFreeConfig <#spFreeConfig>`_.


proc spFreeConfig*(config: ptr SpPortConfig)
  {.cdecl, dynlib: dllname, importc: "sp_free_config".}
  ## Free a port configuration structure.
  ##
  ## config
  ##   Pointer to configuration structure


proc spGetConfig*(port: ptr SpPort; config: ptr SpPortConfig): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_config".}
  ## Get the current configuration of the specified serial port.
  ##
  ## port
  ##   The port to set the config for
  ## config
  ##   The configuration to set
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a configuration structure using
  ## `spNewConfig <#spNewConfig>`_ and pass this as the config parameter. The
  ## configuration structure will be updated with the port configuration.
  ##
  ## Any parameters that are configured with settings not recognised or
  ## supported by libserialport, will be set to special values that are
  ## ignored by `spSetConfig <#spSetConfig>`_.


proc spSetConfig*(port: ptr SpPort; config: ptr SpPortConfig): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config".}
  ## Set the configuration for the specified serial port.
  ##
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## For each parameter in the configuration, there is a special value (usually
  ## -1, but see the documentation for each field). These values will be ignored
  ## and the corresponding setting left unchanged on the port.


proc spSetBaudrate*(port: ptr SpPort; baudrate: cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_baudrate".}
  ## Set the baud rate for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## baudrate
  ##   Baud rate in bits per second
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigBaudrate*(config: ptr SpPortConfig; baudratePtr: ptr cint):
  SpReturn {.cdecl, dynlib: dllname, importc: "sp_get_config_baudrate".}
  ## Get the baud rate from a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## baudratePtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of typeint and pass a pointer to this
  ## to receive the result.


proc spSetConfigBaudrate*(config: ptr SpPortConfig; baudrate: cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_baudrate".}
  ## Set the baud rate in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## baudrate
  ##   Baud rate in bits per second, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetBits*(port: ptr SpPort; bits: cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_bits".}
  ## Set the data bits for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## bits
  ##   Number of data bits
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigBits*(config: ptr SpPortConfig; bits_ptr: ptr cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_config_bits".}
  ## Get the data bits from a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## bitsPtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of typeint and pass a pointer to this
  ## to receive the result.


proc spSetConfigBits*(config: ptr SpPortConfig; bits: cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_bits".}
  ## Set the data bits in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## bits
  ##   Number of data bits, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetParity*(port: ptr SpPort; parity: SpParity): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_parity".}
  ## Set the parity setting for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## parity
  ##   Parity setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigParity*(config: ptr SpPortConfig; parityPtr: ptr SpParity):
  SpReturn {.cdecl, dynlib: dllname, importc: "sp_get_config_parity".}
  ## Get the parity setting from a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## parityPtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of typeenum SpParity and pass a pointer
  ## to this to receive the result.


proc spSetConfigParity*(config: ptr SpPortConfig; parity: SpParity): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_parity".}
  ## Set the parity setting in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## parity
  ##   Parity setting, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetStopbits*(port: ptr SpPort; stopbits: cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_stopbits".}
  ## Set the stop bits for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## stopbits
  ##   Number of stop bits
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   -  a negative error code otherwise


proc spGetConfigStopbits*(config: ptr SpPortConfig; stopbitsPtr: ptr cint):
  SpReturn {.cdecl, dynlib: dllname, importc: "sp_get_config_stopbits".}
  ## Get the stop bits from a port configuration.
  ##
  ## The user should allocate a variable of typeint and pass a pointer to this
  ## to receive the result.
  ##
  ## config
  ##   Pointer to configuration structure
  ## stopbitsPtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetConfigStopbits*(config: ptr SpPortConfig; stopbits: cint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_stopbits".}
  ## Set the stop bits in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## stopbits
  ##   Number of stop bits, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetRts*(port: ptr SpPort; rts: SpRts): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_rts".}
  ## Set the RTS pin behaviour for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## rts
  ##   RTS pin mode
  ## result
  ##   -`SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigRts*(config: ptr SpPortConfig; rtsPtr: ptr SpRts): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_config_rts".}
  ## Get the RTS pin behaviour from a port configuration.
  ##
  ## The user should allocate a variable of typeenum SpRts and pass a pointer to
  ## this to receive the result.
  ##
  ## config
  ##   Pointer to configuration structure
  ## rtsPtr
  ##   Pointer to variable to store result.
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetConfigRts*(config: ptr SpPortConfig; rts: SpRts): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_rts".}
  ## Set the RTS pin behaviour in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## rts
  ##   RTS pin mode, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetCts*(port: ptr SpPort; cts: SpCts): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_cts".}
  ## Set the CTS pin behaviour for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## cts
  ##   CTS pin mode.
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigCts*(config: ptr SpPortConfig; ctsPtr: ptr SpCts): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_config_cts".}
  ## Get the CTS pin behaviour from a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## ctsPtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of typeenum SpCts and pass a pointer to
  ## this to receive the result.


proc spSetConfigCts*(config: ptr SpPortConfig; cts: SpCts): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_cts".}
  ## Set the CTS pin behaviour in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## cts
  ##   CTS pin mode, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise.


proc spSetDtr*(port: ptr SpPort; dtr: SpDtr): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_dtr".}
  ## Set the DTR pin behaviour for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## dtr
  ##   DTR pin mode.
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigDtr*(config: ptr SpPortConfig; dtrPtr: ptr SpDtr): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_config_dtr".}
  ## Get the DTR pin behaviour from a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## dtrPtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of typeenum SpDtr and pass a pointer to
  ## this to receive the result.


proc spSetConfigDtr*(config: ptr SpPortConfig; dtr: SpDtr): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_dtr".}
  ## Set the DTR pin behaviour in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## dtr
  ##   DTR pin mode, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetDsr*(port: ptr SpPort; dsr: SpDsr): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_dsr".}
  ## Set the DSR pin behaviour for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## dsr
  ##   DSR pin mode
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigDsr*(config: ptr SpPortConfig; dsr_ptr: ptr SpDsr): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_config_dsr".}
  ## Get the DSR pin behaviour from a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## dsrPtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of typeenum SpDsr and pass a pointer to
  ## this to receive the result.


proc spSetConfigDsr*(config: ptr SpPortConfig; dsr: SpDsr): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_dsr".}
  ## Set the DSR pin behaviour in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## dsr
  ##   DSR pin mode, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetXonXoff*(port: ptr SpPort; xonXoff: SpXonXoff): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_xon_xoff".}
  ## Set the XON/XOFF configuration for the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## xonXoff
  ##   XON/XOFF mode
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spGetConfigXonXoff*(config: ptr SpPortConfig; xonXoffPtr: ptr SpXonXoff):
  SpReturn {.cdecl, dynlib: dllname, importc: "sp_get_config_xon_xoff".}
  ## Get the XON/XOFF configuration from a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## xonXoffPtr
  ##   Pointer to variable to store result
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of typeenum SpXonXoff and pass a
  ## pointer to this to receive the result.


proc spSetConfigXonXoff*(config: ptr SpPortConfig; xonXoff: SpXonXoff): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_xon_xoff".}
  ## Set the XON/XOFF configuration in a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## xonXoff
  ##   XON/XOFF mode, or -1 to retain current setting
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spSetConfigFlowcontrol*(config: ptr SpPortConfig;
  flowcontrol: SpFlowControl): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_config_flowcontrol".}
  ## Set the flow control typein a port configuration.
  ##
  ## config
  ##   Pointer to configuration structure
  ## flowcontrol
  ##   Flow control setting to use
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## This function is a wrapper that sets the RTS, CTS, DTR, DSR and XON/XOFF
  ## settings as necessary for the specified flow control type. For more
  ## fine-grained control of these settings, use their individual configuration
  ## functions.


proc spSetFlowcontrol*(port: ptr SpPort; flowcontrol: SpFlowControl): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_set_flowcontrol".}
  ## Set the flow control typefor the specified serial port.
  ##
  ## port
  ##   Pointer to port structure
  ## flowcontrol
  ##   Flow control setting to use
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## This function is a wrapper that sets the RTS, CTS, DTR, DSR and XON/XOFF
  ## settings as necessary for the specified flow control type. For more
  ## fine-grained control of these settings, use their individual configuration
  ## functions.


# Reading, writing, and flushing data

proc spBlockingRead*(port: ptr SpPort; buf: pointer; count: csize;
  timeout: cuint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_blocking_read".}
  ## Read bytes from the specified serial port, blocking until complete.
  ##
  ## port
  ##   Pointer to port structure
  ## buf
  ##   Buffer in which to store the bytes read
  ## count
  ##   Requested number of bytes to read
  ## timeout
  ##   Timeout in milliseconds, or zero to wait indefinitely
  ## result
  ##   - The number of bytes read on success
  ##   - a negative error code on failure
  ##
  ## If the number of bytes returned is less than that requested, the timeout
  ## was reached before the requested number of bytes was available. If timeout
  ## is zero, the function will always return either the requested number of
  ## bytes or a negative error code.
  ##
  ## Warning: If your program runs on Unix, defines its own signal handlers, and
  ## needs to abort blocking reads when these are called, then you should not
  ## use this function. It repeats system calls that return with EINTR. To be
  ## able to abort a read from a signal handler, you should implement your own
  ## blocking read using `spNonblockingRead <#spNonblockingRead>`_ together with
  ## a blocking method that makes sense for your program. E.g. you can obtain
  ## the file descriptor for an open port using
  ## `spGetPortHandle <#spGetPortHandle>`_and use this to call select() or
  ## pselect(), with appropriate arrangements to return if a signal is received.


proc spNonblockingRead*(port: ptr SpPort; buf: pointer; count: csize): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_nonblocking_read".}
  ## Read bytes from the specified serial port, without blocking.
  ##
  ## port
  ##   Pointer to port structure
  ## buf
  ##   Buffer in which to store the bytes read
  ## count
  ##   Maximum number of bytes to read
  ## result
  ##   - The number of bytes read on success
  ##   - a negative error code.
  ##
  ## The number of bytes returned may be any number from zero to the maximum
  ## that was requested.


proc spBlockingWrite*(port: ptr SpPort; buf: pointer; count: csize;
  timeout: cuint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_blocking_write".}
  ## Write bytes to the specified serial port, blocking until complete.
  ##
  ## port
  ##   Pointer to port structure
  ## buf
  ##   Buffer containing the bytes to write
  ## count
  ##   Requested number of bytes to write
  ## timeout
  ##   Timeout in milliseconds, or zero to wait indefinitely
  ## result
  ##   - The number of bytes written on success
  ##   - a negative error code
  ##
  ## If the number of bytes returned is less than that requested, the timeout
  ## was reached before the requested number of bytes was written. If timeout is
  ## zero, the function will always return either the requested number of bytes
  ## or a negative error code. In the event of an error there is no way to
  ## determine how many bytes were sent before the error occurred.
  ##
  ## Note that this function only ensures that the accepted bytes have been
  ## written to the OS; they may be held in driver or hardware buffers and not
  ## yet physically transmitted. To check whether all written bytes have
  ## actually been transmitted, use the sp_output_waiting() function. To wait
  ## until all written bytes have actually been transmitted, use the
  ## `spDrain <#spDrain>`_ function.
  ##
  ## Warning: If your program runs on Unix, defines its own signal handlers, and
  ## needs to abort blocking writes when these are called, then you should not
  ## use this function. It repeats system calls that return with EINTR. To be
  ## able to abort a write from a signal handler, you should implement your own
  ## blocking write using `spNonblockingWrite <#spNonblockingWrite>`_together
  ## with a blocking method that makes sense for your program. E.g. you can
  ## obtain the file descriptor for an open port using
  ## `spGetPortHandle <#spGetPortHandle>`_ and use this to call select() or
  ## pselect(), with appropriate arrangements to return if a signal is received.


proc spNonblockingWrite*(port: ptr SpPort; buf: pointer; count: csize): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_nonblocking_write".}
  ## Write bytes to the specified serial port, without blocking.
  ##
  ## port
  ##   Pointer to port structure
  ## buf
  ##   Buffer containing the bytes to write
  ## count
  ##   Maximum number of bytes to write
  ## result
  ##   - The number of bytes written on success
  ##   - or a negative error code
  ##
  ## The number of bytes returned may be any number from zero to the maximum
  ## that was requested.
  ##
  ## Note that this function only ensures that the accepted bytes have been
  ## written to the OS; they may be held in driver or hardware buffers and not
  ## yet physically transmitted. To check whether all written bytes have
  ## actually been transmitted, use the `spOutputWaiting <#spOutputWaiting>`_
  ## function. To wait until all written bytes have actually been transmitted,
  ## use the `spDrain <#spDrain>`_ function.


proc spInputWaiting*(port: ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_input_waiting".}
  ## Get the number of bytes waiting in the input buffer.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - Number of bytes waiting on success
  ##   - a negative error code otherwise


proc spOutputWaiting*(port: ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_output_waiting".}
  ## Get the number of bytes waiting in the output buffer.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - Number of bytes waiting on success
  ##   - a negative error code otherwise


proc spFlush*(port: ptr SpPort; buffers: SpBuffer): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_flush".}
  ## Flush serial port buffers. Data in the selected buffer(s) is discarded.
  ##
  ## port
  ##   Pointer to port structure
  ## buffers
  ##   Which buffer(s) to flush
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spDrain*(port: ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_drain".}
  ## Wait for buffered data to be transmitted.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## If your program runs on Unix, defines its own signal handlers, and needs
  ## to abort draining the output buffer when when these are called, then you
  ## should not use this function. It repeats system calls that return with
  ## EINTR. To be able to abort a drain from a signal handler, you would need
  ## to implement your own blocking drain by polling the result of
  ## `spOutputWaiting <#spOutputWaiting>`_.


# Waiting for events

proc spNewEventSet*(resultPtr: ptr ptr SpEventSet): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_new_event_set".}
  ## Allocate storage for a set of events.
  ##
  ## resultPtr
  ##   Will contain the pointer to the allocated storage
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The user should allocate a variable of type `SpEventSet <#SpEventSet>`_,
  ## then pass a pointer to this variable to receive the result. The result
  ## should be freed after use by calling `spFreeEventSet <#spFreeEventSet>`_.


proc spAddPortEvents*(eventSet: ptr SpEventSet; port: ptr SpPort;
  mask: SpEvent): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_add_port_events".}
  ## Add events to a struct SpEventSet for a given port.
  ##
  ## eventSet
  ##   Event set to update
  ## port
  ##   Pointer to port structure
  ## mask
  ##   Bitmask of events to be waited for
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise
  ##
  ## The port must first be opened by calling `spOpen <#spOpen>`_ using the same
  ## port structure. After the port is closed or the port structure freed, the
  ## results may no longer be valid.


proc spWait*(eventSet: ptr SpEventSet; timeout: cuint): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_wait".}
  ## Wait for any of a set of events to occur.
  ##
  ## eventSet
  ##   Event set to wait on
  ## timeout
  ##   Timeout in milliseconds, or zero to wait indefinitely
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spFreeEventSet*(event_set: ptr SpEventSet)
  {.cdecl, dynlib: dllname, importc: "sp_free_event_set".}
  ## Free a structure allocated by `spNewEventSet <#spNewEventSet>`_.


# Port signalling operations

proc spGetSignals*(port: ptr SpPort; signalMask: ptr SpSignal): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_get_signals".}
  ## Get the status of the control signals for the specified port.
  ##
  ## The user should allocate a variable of type `SpSignal <#SpSignal>`_ and
  ## pass a pointer to this variable to receive the result. The result is a
  ## bitmask in which individual signals can be checked by bitwise OR with
  ## values of the SpSignal enum.
  ##
  ## port
  ##   Pointer to port structure
  ## signalMask
  ##   Pointer to variable to receive result.
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spStartBreak*(port: ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_start_break".}
  ## Put the port transmit line into the break state.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


proc spEndBreak*(port: ptr SpPort): SpReturn
  {.cdecl, dynlib: dllname, importc: "sp_end_break".}
  ## Take the port transmit line out of the break state.
  ##
  ## port
  ##   Pointer to port structure
  ## result
  ##   - `SpReturn.ok <#SpReturn>`_ upon success
  ##   - a negative error code otherwise


# Obtaining error information

proc spLastErrorCode*(): cint
  {.cdecl, dynlib: dllname, importc: "sp_last_error_code".}
  ## Get the error code for a failed operation.
  ##
  ## result
  ##   The system's numeric code for the error that caused the last operation to
  ##   fail.
  ##
  ## In order to obtain the correct result, this function should be called
  ## straight after the failure, before executing any other system operations.


proc spLastErrorMessage*(): cstring
  {.cdecl, dynlib: dllname, importc: "sp_last_error_message".}
  ## Get the error message for a failed operation.
  ##
  ## result
  ##   The system's message for the error that caused the last operation to
  ##   fail. This string may be allocated by the function, and should be freed
  ##   after use by calling `spFreeErrorMessage <#spFreeErrorMessage>`_.
  ##
  ## In order to obtain the correct result, this function should be called
  ## straight after the failure, before executing other system operations.


proc spFreeErrorMessage*(message: cstring)
  {.cdecl, dynlib: dllname, importc: "sp_free_error_message".}
  ## Free an error message returned by `spLastErrorMessage <#spLastErrorMessage>`_.
  ##
  ## message
  ##   The message string to free


proc spSetDebugHandler*(handler: proc (format: cstring) {.varargs.})
  {.cdecl, dynlib: dllname, importc: "sp_set_debug_handler".}
  ## Set the handler function for library debugging messages.
  ##
  ## format
  ##   printf() style format string
  ##
  ## Debugging messages are generated by the library during each operation,
  ## to help in diagnosing problems. The handler will be called for each
  ## message. The handler can be set to `nil` to ignore all debug messages.
  ##
  ## The handler function should accept a format string and variable length
  ## argument list, in the same manner as e.g. printf().
  ##
  ## The default handler is `spDefaultDebugHandler <#spDefaultDebugHandler>`_.


proc spDefaultDebugHandler*(format: cstring)
  {.varargs, cdecl, dynlib: dllname, importc: "sp_default_debug_handler".}
  ## Default handler function for library debugging messages.
  ##
  ## format
  ##   printf() style format string
  ##
  ## This function prints debug messages to the standard error stream if the
  ## environment variable LIBSERIALPORT_DEBUG is set. Otherwise, they are
  ## ignored.


# Version number querying functions, definitions, and macros
#
# This set of API calls returns two different version numbers related to
# libserialport. The "package version" is the release version number of the
# libserialport tarball in the usual "major.minor.micro" format, e.g. "0.1.0".
#
# The "library version" is independent of that; it is the libtool version number
# in the "current:revision:age" format, e.g. "2:0:0".
# See http://www.gnu.org/software/libtool/manual/libtool.html#Libtool-versioning
# for details.
#
# Both version numbers (and/or individual components of them) can be retrieved
# via the API calls at runtime, and/or they can be checked at
# compile/preprocessor time using the respective macros.

const ## Package version (can be used for conditional compilation).
  spPackageVersionMajor* = 0
    ## The libserialport package 'major' version number.
  spPackageVersionMinor* = 2
    ## The libserialport package 'minor' version number.
  spPackageVersionMicro* = 0
    ## The libserialport package 'micro' version number.
  spPackageVersionString* = "0.2.0"
    ## The libserialport package version ("major.minor.micro") as string.


const ## Library/libtool version (can be used for conditional compilation).
  spLibVersionCurrent* = 0
    ## The libserialport libtool 'current' version number.
  spLibVersionRevision* = 0
    ## The libserialport libtool 'revision' version number.
  spLibVersionAge* = 0
    ## The libserialport libtool 'age' version number.
  spLibVersionString* = "0.0.0"
    ## The libserialport libtool version ("current:revision:age") as string.


proc spGetMajorPackageVersion*(): cint
  {.cdecl, dynlib: dllname, importc: "sp_get_major_package_version".}
  ## Get the major libserialport package version number.
  ##
  ## result
  ##   The major package version number


proc spGetMinorPackageVersion*(): cint
  {.cdecl, dynlib: dllname, importc: "sp_get_minor_package_version".}
  ## Get the minor libserialport package version number.
  ##
  ## result
  ##   The minor package version number


proc spGetMicroPackageVersion*(): cint
  {.cdecl, dynlib: dllname, importc: "sp_get_micro_package_version".}
  ## Get the micro libserialport package version number.
  ##
  ## result
  ##   The micro package version number


proc spGetPackageVersionString*(): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_package_version_string".}
  ## Get the libserialport package version number as a string.
  ##
  ## result
  ##   The package version number string
  ##
  ## The returned string is static and thus should NOT be free'd by the caller.

proc spGetCurrentLibVersion*(): cint
  {.cdecl, dynlib: dllname, importc: "sp_get_current_lib_version".}
  ## Get the "current" part of the libserialport library version number.
  ##
  ## result
  ##   The "current" library version number

proc spGetRevisionLibVersion*(): cint
  {.cdecl, dynlib: dllname, importc: "sp_get_revision_lib_version".}
  ## Get the "revision" part of the libserialport library version number.
  ##
  ## result
  ##   The "revision" library version number


proc spGetAgeLibVersion*(): cint
  {.cdecl, dynlib: dllname, importc: "sp_get_age_lib_version".}
  ## Get the "age" part of the libserialport library version number.
  ##
  ## result
  ##   The "age" library version number

proc spGetLibVersionString*(): cstring
  {.cdecl, dynlib: dllname, importc: "sp_get_lib_version_string".}
  ## Get the libserialport library version number as a string.
  ##
  ## result
  ##   The library version number string
  ##
  ## The returned string is static and thus should NOT be free'd by the caller.
