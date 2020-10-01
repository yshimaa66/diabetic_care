/*





// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';

// For using PlatformException
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_adel/widgets/progress.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:countdown_flutter/countdown_flutter.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:flutter_adel/widgets/progress.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  TextEditingController phoneController = TextEditingController();
  String countryCode="+20";
  bool bluetoothon=false;
  bool showtimer=false;
  bool showsmssent=false;
  int blutoothsignal;
  bool _connected = false;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;

  int _deviceState;

  bool isDisconnecting = false;

  Map<String, Color> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[700],
    'offTextColor': Colors.red[700],
    'neutralTextColor': Colors.blue,
  };

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;

  bool _isButtonUnavailable = false;

  TwilioFlutter twilioFlutter;

  final _scaffoldkey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();


    twilioFlutter = TwilioFlutter(
        accountSid: 'ACeab05687db67584558df7ba453e1b7c1',
        authToken: '79e395c433731c8dd142e7a66d051c61',
        twilioNumber: '+18189182255');

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }


  void sendSms() async {

    twilioFlutter.sendSMS(
        toNumber: widget.countryCode + widget.phoneController.text,
        messageBody: "Hi, it's ShO_O");
  }

  void getSms() async {
    var data = await twilioFlutter.getSmsList();
    print(data);

    await twilioFlutter.getSMS('***************************');
  }


  handlestillwanthelp(BuildContext context){

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Still want help ?"),
            content:
            new Text("We are about to send SMS to that number, so you still need help ?"),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog

              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top:30.0),
                  child: Countdown(
                    duration: Duration(seconds: 20),
                    onFinish: () {


                        setState(() {

                          handlestillwanthelp(context);
                          widget.showsmssent=true;

                        });



                    },
                    builder: (BuildContext ctx, Duration remaining) {
                      return Text('${remaining.inSeconds}',style: TextStyle(fontSize: 100,fontWeight: FontWeight.bold,color: Colors.blue),);
                    },
                  ),
                ),
              ),

              Row(
                children: <Widget>[
                  new RaisedButton(
                    color: Colors.red,
                    child: new Text("I'm Okay now",style: TextStyle(color: Colors.white),),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  new RaisedButton(
                    color: Colors.blue,
                    child: new Text("Yes, go",style: TextStyle(color: Colors.white),),
                    onPressed: () {
                      //performIgnore();
                      sendSms();
                      Navigator.pop(context);
                    },
                  ),


                ],
              ),



            ],
          );
        });
  }

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {


    Widget _buildDropdownItem(Country country) => Container(
      child: Row(
        children: <Widget>[
          CountryPickerUtils.getDefaultFlagImage(country),
          SizedBox(
            width: 3.0,
          ),
          Text("${country.isoCode}",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),),
        ],
      ),
    );

    return Scaffold(
        key: _scaffoldKey,
        body: Builder(
          builder: (context) =>(
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: RefreshIndicator(
              onRefresh: () async {
                await getPairedDevices().then((_) {
                show('Device list refreshed');
                 });
                },

              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  child: ListView(
                    children: <Widget>[
                      _isButtonUnavailable &&
                          _bluetoothState == BluetoothState.STATE_ON ?
                        circularProgress()
                      :
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Enable Bluetooth',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Switch(
                              value: _bluetoothState.isEnabled,
                              onChanged: (bool value) {
                                future() async {
                                  if (value) {
                                    await FlutterBluetoothSerial.instance
                                        .requestEnable();
                                  } else {
                                    await FlutterBluetoothSerial.instance
                                        .requestDisable();
                                  }

                                  await getPairedDevices();
                                  _isButtonUnavailable = false;

                                  if (widget._connected) {
                                    _disconnect();
                                  }
                                }

                                future().then((_) {
                                  setState(() {});
                                });
                              },
                            )
                          ],
                        ),
                      ),
                      Stack(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  "PAIRED DEVICES",
                                  style: TextStyle(fontSize: 12, color: Colors.blue),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      'Device:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    DropdownButton(
                                      items: _getDeviceItems(),
                                      onChanged: (value) =>
                                          setState(() => _device = value),
                                      value: _devicesList.isNotEmpty ? _device : null,
                                    ),
                                    IconButton(
                                      onPressed: _isButtonUnavailable
                                          ? null
                                          : widget._connected ? _disconnect : _connect,
                                      icon:
                                      Icon(Icons.bluetooth_connected),
                                      color: widget._connected ? Colors.blue : Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[


                                Container(

                                  child: Row(

                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    mainAxisSize: MainAxisSize.max,

                                    children: <Widget>[

                                      Container(
                                        width: 130.0,
                                        child: CountryPickerDropdown(
                                          initialValue: 'eg',
                                          itemBuilder: _buildDropdownItem,
                                          onValuePicked: (Country country) {
                                            print("${country.name}");

                                            widget.countryCode = "+"+country.phoneCode;

                                          },
                                        ),
                                      ),

                                      Container(
                                        width: 150.0,
                                        child: TextField(
                                          controller: widget.phoneController,
                                          decoration: InputDecoration(
                                              hintText: "Phone number",
                                              hintStyle: TextStyle(fontSize: 15.0),
                                              border: InputBorder.none
                                          ),
                                          keyboardType: TextInputType.number,),


                                      ),
                                    ],
                                  ),
                                  decoration: new BoxDecoration(
                                    color: Colors.white70,
                                    border: Border.all(
                                        color: Colors.blue,
                                        width: 2.0
                                    ),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(300.0)  //                 <--- border radius here
                                    ),

                                  ),

                                ),




                                widget.showsmssent?Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.check_circle,color: Colors.green,size: 15,),
                                    SizedBox(width: 5,),
                                    Text('SMS Sent Successfully'
                                      ,style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold,color: Colors.green),),
                                  ],
                                ):Text(""),

                                Padding(
                                  padding: const EdgeInsets.only(top:20.0),
                                  child: Container(
                                    child: FlatButton(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0)),
                                      onPressed: (){


                                       if(widget.phoneController.text=="") {

                                          Scaffold.of(context).showSnackBar(new SnackBar(
                                              content: new Text('You need to enter a phone number')));

                                        }

                                        else if(!widget._connected){

                                          Scaffold.of(context).showSnackBar(new SnackBar(
                                              content: new Text('No device connected')));


                                        }else{

                                          setState(() {

                                            handlestillwanthelp(context);

                                          });


                                        }

                                      },
                                      child: Column(
                                        children: <Widget>[
                                          Icon(Icons.send,color: Colors.black ,),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          ),
                                          Text('Send Sms',style: TextStyle(color: Colors.black),),
                                        ],
                                      ),
                                    ),
                                    decoration: new BoxDecoration(
                                      color: Colors.white70,
                                      border: Border.all(
                                          color: Colors.blue,
                                          width: 2.0
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(100.0)  //                 <--- border radius here
                                      ),

                                    ),
                                  ),
                                ),

                            Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Text(
                                      "NOTE: If you cannot find the device in the list, \n please pair the device by going to the bluetooth settings",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: IconButton(
                                        icon: Icon(Icons.settings),
                                        iconSize: 20,
                                        onPressed: () {
                                          FlutterBluetoothSerial.instance.openSettings();
                                        },
                                      ),
                                    ),


                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ))
        ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            widget._connected = true;
          });

          connection.input.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        show('Device connected');

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

//// void _onDataReceived(Uint8List data) {
////   // Allocate buffer for parsed data
////   int backspacesCounter = 0;
////   data.forEach((byte) {
////     if (byte == 8 || byte == 127) {
////       backspacesCounter++;
////     }
////   });
////   Uint8List buffer = Uint8List(data.length - backspacesCounter);
////   int bufferIndex = buffer.length;
//
////   // Apply backspace control character
////   backspacesCounter = 0;
////   for (int i = data.length - 1; i >= 0; i--) {
////     if (data[i] == 8 || data[i] == 127) {
////       backspacesCounter++;
////     } else {
////       if (backspacesCounter > 0) {
////         backspacesCounter--;
////       } else {
////         buffer[--bufferIndex] = data[i];
////       }
////     }
//   }
//// }

  // Method to disconnect bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });

    await connection.close();
    show('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        widget._connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1" + "\r\n"));
    await connection.output.allSent;
    show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("0" + "\r\n"));
    await connection.output.allSent;
    show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  Future show(
      String message, {
        Duration duration: const Duration(seconds: 3),
      }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}














/*import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:countdown_flutter/countdown_flutter.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:flutter_adel/widgets/progress.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {


  TextEditingController phoneController = TextEditingController();
  String countryCode="+20";
  bool bluetoothon=false;
  bool showtimer=false;
  bool showsmssent=false;
  int blutoothsignal;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  bool isloading=false;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  TwilioFlutter twilioFlutter;

  final _scaffoldkey = GlobalKey<ScaffoldState>();

  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  Future<void> initState() {

    twilioFlutter = TwilioFlutter(
        accountSid: 'ACeab05687db67584558df7ba453e1b7c1',
        authToken: '79e395c433731c8dd142e7a66d051c61',
        twilioNumber: '+18189182255');


    /*FlutterBlue.instance.state.listen((state) {
      if (state == BluetoothState.off) {

      setState(() {

        widget.bluetoothon=false;

      });


      } else if (state == BluetoothState.on) {


        setState(() {

          widget.bluetoothon=true;

        });



      }
    });*/

    handlebluetoothprocees();

    super.initState();
  }

  handlebluetoothprocees() async {

   setState(() {
     widget.isloading=true;
   });

    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();


    for (BluetoothDevice device in widget.devicesList) {

      if(device.name.toLowerCase()==("Mony").toLowerCase()){

        widget.flutterBlue.stopScan();
        try {
          await device.connect();
        } catch (e) {
          if (e.code != 'already_connected') {
            throw e;
          }
        } finally {
          _services = await device.discoverServices();
        }
        setState(() {
          _connectedDevice = device;

          print(_connectedDevice);

          Scaffold.of(context).showSnackBar(new SnackBar(
              content: new Text('Connected to HC-05 device successfully')));


        });


      }


    }

    for (BluetoothService service in _services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        var sub = characteristic.value.listen((value) {
          setState(() {
            widget.readValues[characteristic.uuid] = value;
            widget.blutoothsignal=int.parse(value.toString());

            Scaffold.of(context).showSnackBar(new SnackBar(
                content: new Text('Reading signals ....')));

            if(widget.blutoothsignal==1){

              Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text('Got the desired signal')));

            }

          });
        });

        await characteristic.read();
        sub.cancel();
      }
    }

   setState(() {
     widget.isloading=false;
   });

  }

  void sendSms() async {

      twilioFlutter.sendSMS(
          toNumber: widget.countryCode + widget.phoneController.text,
          messageBody: "Hi, it's ShO_O");
  }

  void getSms() async {
    var data = await twilioFlutter.getSmsList();
    print(data);

    await twilioFlutter.getSMS('***************************');
  }



  handlebluetooth(BuildContext context){

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Bluetooth off"),
          content:
          new Text("You need to turn bluetooth on"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog

            /*new RaisedButton(
              color: Colors.red,
              child: new Text("Cancel",style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.pop(context);
              },
            ),*/

            new RaisedButton(
              color: Colors.blue,
              child: new Text("Ok",style: TextStyle(color: Colors.white),),
              onPressed: () {
                //performIgnore();
                Navigator.pop(context);
              },
            ),


          ],
        );
          });
  }


  handlestillwanthelp(BuildContext context){

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Still want help ?"),
            content:
            new Text("We are about to send SMS to that number, so you still need help ?"),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog

              new RaisedButton(
              color: Colors.red,
              child: new Text("I'm Okay now",style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

              new RaisedButton(
                color: Colors.blue,
                child: new Text("Yes, go",style: TextStyle(color: Colors.white),),
                onPressed: () {
                  //performIgnore();
                  sendSms();
                  Navigator.pop(context);
                },
              ),


            ],
          );
        });
  }

  /*ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    if (e.code != 'already_connected') {
                      throw e;
                    }
                  } finally {
                    _services = await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }
*/

  /*List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.blue,
              child: Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  widget.readValues[characteristic.uuid] = value;
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }*/

  /*ListView _buildConnectDeviceView() {
    List<Container> containers = new List<Container>();

    for (BluetoothService service in _services) {
      List<Widget> characteristicsWidget = new List<Widget>();

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(characteristic.uuid.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ..._buildReadWriteNotifyButton(characteristic),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('Value: ' +
                        widget.readValues[characteristic.uuid].toString()),
                  ],
                ),
                Divider(),
              ],
            ),
          ),
        );
      }
      containers.add(
        Container(
          child: ExpansionTile(
              title: Text(service.uuid.toString()),
              children: characteristicsWidget),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }*/

  /*ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }*/

  @override
  Widget build(BuildContext context) {

    Widget _buildDropdownItem(Country country) => Container(
      child: Row(
        children: <Widget>[
          CountryPickerUtils.getDefaultFlagImage(country),
          SizedBox(
            width: 3.0,
          ),
          Text("${country.isoCode}",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),),
        ],
      ),
    );


    return Scaffold(
      key: _scaffoldkey,
      body: Builder(
        builder: (context) =>
        Center(
          child: widget.isloading?circularProgress():Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Container(

                    child: Row(

                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.max,

                      children: <Widget>[

                        Icon(Icons.phone, color: Colors.blue, size: 20.0,),

                        Container(
                          width: 100.0,
                          child: CountryPickerDropdown(
                            initialValue: 'eg',
                            itemBuilder: _buildDropdownItem,
                            onValuePicked: (Country country) {
                              print("${country.name}");

                              widget.countryCode = "+"+country.phoneCode;

                            },
                          ),
                        ),

                        Container(
                          width: 150.0,
                          child: TextField(
                            controller: widget.phoneController,
                            decoration: InputDecoration(
                                hintText: "Phone number",
                                hintStyle: TextStyle(fontSize: 15.0),
                                border: InputBorder.none
                            ),
                            keyboardType: TextInputType.number,),


                        ),
                      ],
                    ),
                 decoration: new BoxDecoration(
                  color: Colors.white70,
                  border: Border.all(
                      color: Colors.blue,
                      width: 2.0
                  ),
                  borderRadius: BorderRadius.all(
                      Radius.circular(300.0)  //                 <--- border radius here
                  ),

                ),

                  ),


              widget.showtimer?Padding(
                padding: const EdgeInsets.only(top:30.0),
                child: Countdown(
                  duration: Duration(seconds: 20),
                  onFinish: () {
                    if(widget.blutoothsignal==1){

                      setState(() {

                        widget.showtimer=false;
                        handlestillwanthelp(context);
                        widget.showsmssent=true;

                      });

                    }else{

                      setState(() {

                        handlebluetooth(context);
                        widget.showtimer=false;

                      });


                    }
                  },
                  builder: (BuildContext ctx, Duration remaining) {
                    return Text('${remaining.inSeconds}',style: TextStyle(fontSize: 100,fontWeight: FontWeight.bold,color: Colors.blue),);
                  },
                ),
              ):Text(""),


              widget.showsmssent?Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.check_circle,color: Colors.green,size: 20,),
                  SizedBox(width: 5,),
                  Text('SMS Sent Successfully'
                    ,style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Colors.green),),
                ],
              ):Text(""),

              Padding(
               padding: const EdgeInsets.only(top:100.0),
               child: Container(
                    child: FlatButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0)),
                      onPressed: (){


                        if(_connectedDevice!=null){

                          Scaffold.of(context).showSnackBar(new SnackBar(
                              content: new Text('Connected to HC-05 device successfully')));


                        }
                        else{ if(widget.phoneController.text=="") {

                          Scaffold.of(context).showSnackBar(new SnackBar(
                              content: new Text('You need to enter a phone number')));

                        }

                        else if(widget.blutoothsignal!=1){

                          Scaffold.of(context).showSnackBar(new SnackBar(
                              content: new Text('No signal, try again')));


                        }else{

                          setState(() {

                            widget.showtimer=true;

                          });


                        }}

                      },
                      child: Column(
                        children: <Widget>[
                          Icon(Icons.send,color: Colors.black ,),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                          ),
                          Text('Send Sms',style: TextStyle(color: Colors.black),),
                        ],
                      ),
                    ),
                    decoration: new BoxDecoration(
                      color: Colors.white70,
                      border: Border.all(
                          color: Colors.blue,
                          width: 2.0
                      ),
                      borderRadius: BorderRadius.all(
                          Radius.circular(100.0)  //                 <--- border radius here
                      ),

                    ),
                  ),
             ),

            ],
          ),
        ),
      ),
    );
  }
}
*/











 */