import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_incall_manager/incall.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:temp_webrtc/channel.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_incall_manager/flutter_incall_manager.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  MediaStream _localStream;
  

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetUserMediaSample();
  }
}

class GetUserMediaSample extends StatefulWidget {
  static String tag = 'get_usermedia_sample';

  @override
  _GetUserMediaSampleState createState() => new _GetUserMediaSampleState();
}

class _GetUserMediaSampleState extends State<GetUserMediaSample> {
  MediaStream _localStream;
  GlobalKey<ScaffoldState> s = GlobalKey<ScaffoldState>();
  List<String> candids = [];
  RTCPeerConnection _localRenderer;
  List<MediaStream> _tempo;
  final _remoteContainer = new RTCVideoRenderer();
  final _localcontainer = new RTCVideoRenderer();
  bool _inCalling = false;
  bool gotAnswer = false;
  FlutterSound flutterSound = new FlutterSound();
  IOWebSocketChannel channel;
  IncallManager incall = new IncallManager();

  static bool isPhone = true;

  int a = isPhone ? 420 : 401;
  int b = isPhone ? 401 : 420;

  Map<String, dynamic> configuration = {
        "iceServers": [
          {"url": "stun:stun.l.google.com:19302"},
        ],
        "sdpSemantics": "unified-plan"
      };

      final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> mediaConstraints = {
        "audio": {
          "channelCount": "2",
          "sampleRate": "48000"
        },
        "video": false
        // "video": {
        //   "mandatory": {
        //     "minWidth":
        //     '640', // Provide your own width, height and frame rate here
        //     "minHeight": '480',
        //     "minFrameRate": '30',
        //   },
        //   "facingMode": "user",
        //   "optional": [],
        // }
      };

  @override
  initState() {
    super.initState();
    // dat();
    // kat();
    initializeSocket();
  }

  initializeSocket() async {
    await _remoteContainer.initialize();
      await _localcontainer.initialize();
    channel = IOWebSocketChannel.connect('ws://192.168.31.192:8080/echo?id=$a');
    channel.stream.listen((data) async {
      data = json.decode(data);
      switch(data['type']) {
        case "offer": {
          _localRenderer = await createPeerConnection(configuration, _config);
          MediaStream m = await navigator.getUserMedia(mediaConstraints);
          _localcontainer.srcObject = m;
          _localRenderer.addStream(m);
          _localRenderer.onIceCandidate = (RTCIceCandidate candidate) {
            channel.sink.add(json.encode({
              "type": "candidate",
              "id": "$b",
              "message": {
                "candidate": {
                  "candidate": candidate.candidate,
                  "sdpMid": candidate.sdpMid,
                  "sdpMlineIndex": candidate.sdpMlineIndex
                }
              }
            }));
          };
          _localRenderer.onAddStream = (MediaStream m) {
            _remoteContainer.srcObject = m;
            setState(() {
              
            });
          };
          
          _localRenderer.setRemoteDescription(RTCSessionDescription(data['message']['sdp'], data['message']['type']));
          _localRenderer.createAnswer(_constraints).then((RTCSessionDescription desc) {
            _localRenderer.setLocalDescription(desc);
            channel.sink.add(json.encode({
              "type": "answer",
              "id": "$b",
              "message": {
                "type": desc.type,
                "sdp": desc.sdp
              }
            }));
          }); 
          break;
        }
        case "answer": {
          _localRenderer.setRemoteDescription(RTCSessionDescription(
            data['message']['sdp'], 
            data['message']['type']
          ));
          gotAnswer = true;
          sender();
          flutterSound.startPlayer(null);
          break;
        }
        case "candidate": {
          if (_localRenderer != null) {
            RTCIceCandidate candidate = new RTCIceCandidate(
                  data['message']['candidate']['candidate'].toString(),
                  data['message']['candidate']['sdpMid'].toString(),
                  int.parse(data['message']['candidate']['sdpMLineIndex'] ?? "0"));
            _localRenderer?.addCandidate(candidate);
          }
        }
      }
      setState(() {
        
      });
    });
  }

  sender() {
    candids.forEach((s) {
      channel.sink.add(s);
    });
  }

  initiateCall() async {
    _localRenderer = await createPeerConnection(configuration, _config);
    MediaStream m = await navigator.getUserMedia(mediaConstraints);
    
    _localcontainer.srcObject = m;
    _localRenderer.addStream(m);
    _localRenderer.onIceGatheringState = (RTCIceGatheringState ice) {
      if (ice == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        _localRenderer.getLocalDescription().then((RTCSessionDescription desc) {
          channel.sink.add(
            json.encode({
              "type": "offer",
              "id": "$b",
              "message": {
                "type": desc.type,
                "sdp": desc.sdp,
              }
            })
          );
        });
      }
    };
    _localRenderer.onIceCandidate = (RTCIceCandidate candidate) {  
      if (gotAnswer) {
        channel.sink.add(
          json.encode({
            "type": "candidate",
            "id": "$b",
            "message": {
              "candidate": {
                "candidate": candidate.candidate,
                "sdpMid": candidate.sdpMid,
                "sdpMlineIndex": candidate.sdpMlineIndex
              }
            }
          })
        );
      } else {
        candids.add(json.encode({
            "type": "candidate",
            "id": "$b",
            "message": {
              "candidate": {
                "candidate": candidate.candidate,
                "sdpMid": candidate.sdpMid,
                "sdpMlineIndex": candidate.sdpMlineIndex
              }
            }
          }));
      }
    };
    _localRenderer.onAddStream = (MediaStream m) {
      incall.setForceSpeakerphoneOn(true);
        _remoteContainer.srcObject = m;
      setState(() {
        
      });
    };
    _localRenderer.onAddTrack = (MediaStream s, MediaStreamTrack t) {
      print(s);
      print(t);
    };
    _localRenderer.createOffer({}).then((RTCSessionDescription desc) {
      _localRenderer.setLocalDescription(desc);
      
    });
  }

  kat() async {

      final Map<String, dynamic> mediaConstraints = {
        "audio": true,
        "video": {
          "mandatory": {
            "minWidth":
            '640', // Provide your own width, height and frame rate here
            "minHeight": '480',
            "minFrameRate": '30',
          },
          "facingMode": "user",
          "optional": [],
        }
      };

      final Map<String, dynamic> offer_sdp_constraints = {
        "mandatory": {
          "OfferToReceiveAudio": true,
          "OfferToReceiveVideo": true,
        },
        "optional": [],
      };

      final Map<String, dynamic> loopback_constraints = {
        "mandatory": {},
        "optional": [
          {"DtlsSrtpKeyAgreement": false},
        ],
      };

      
      _localRenderer = await createPeerConnection(configuration, {});
      MediaStream _localStream = await navigator.getUserMedia(mediaConstraints);
      _localcontainer.srcObject = _localStream;
      _localRenderer.onAddStream = (MediaStream s) {
        _remoteContainer.srcObject = s;
      };
      await _localRenderer.addStream(_localStream);
      RTCSessionDescription rt = await _localRenderer.createOffer(offer_sdp_constraints);
      _localRenderer.setLocalDescription(rt);
      print(await http.post("http://192.168.31.192:8080/s", body: {
        "id": "150",
        "val": json.encode({
          "sdp": rt.sdp,
          "type": rt.type
        })
      }));
      // _remoteRenderer.onAddTrack = (a, b) {
      //   _localRenderero.srcObject = 
      // };
      // Future.delayed(Duration(seconds: 2), () {
      //   croc();
      // });
      setState(() { 
        
      });
    }

  // dat() async {
  //   final Map<String, dynamic> mediaConstraints = {
  //       "audio": true,
  //       "video": {
  //         "mandatory": {
  //           "minWidth":
  //           '640', // Provide your own width, height and frame rate here
  //           "minHeight": '480',
  //           "minFrameRate": '30',
  //         },
  //         "facingMode": "user",
  //         "optional": [],
  //       }
  //     };

  //     final Map<String, dynamic> offer_sdp_constraints = {
  //       "mandatory": {
  //         "OfferToReceiveAudio": true,
  //         "OfferToReceiveVideo": true,
  //       },
  //       "optional": [],
  //     };

  //     // final Map<String, dynamic> offer_sdp_constraints = {
  //     //   "mandatory": {
  //     //     "OfferToReceiveAudio": true,
  //     //     "OfferToReceiveVideo": true,
  //     //   },
  //     //   "optional": [],
  //     // };

  //     // final Map<String, dynamic> loopback_constraints = {
  //     //   "mandatory": {},
  //     //   "optional": [
  //     //     {"DtlsSrtpKeyAgreement": false},
  //     //   ],
  //     // };
  //     Map<String, dynamic> configuration = {
  //       "iceServers": [
  //         {"url": "stun:stun.l.google.com:19302"},
  //       ]
  //     };
  //   _remoteRenderer = await createPeerConnection(configuration, {});
  //   MediaStream _localStream = await navigator.getUserMedia(mediaConstraints);
  //   http.Response fat = await http.get("http://192.168.31.192:8080/d?id=150");
  //   dynamic val = json.decode(fat.body);
  //   _remoteRenderer.setRemoteDescription(RTCSessionDescription(val['sdp'], val['type']));
  //   _remoteRenderer.createAnswer({
  //   'mandatory': {
  //     'OfferToReceiveAudio': true,
  //     'OfferToReceiveVideo': true,
  //   },
  //   'optional': [],
  // }).then((RTCSessionDescription d) async {
  //   _remoteRenderer.setLocalDescription(d);
  //   await http.post("http://192.168.31.192:8080/s", body: {
  //     "id": "143",
  //     "val": json.encode({
  //       "sdp": d.sdp,
  //       "type": d.type
  //     })
  //   });
  //   _localcontainer.srcObject = _remoteRenderer.getRemoteStreams()[0];
  //   Future.delayed(Duration(seconds: 5), () async {
  //     _remoteRenderer.addStream(_localStream);
  //     _remoteContainer.srcObject = _localStream;
  //   });
  // });
  // }

  // croc() async {
  //   try {
  //   http.Response res = await http.get("http://192.168.31.192:8080/d?id=143");
  //   dynamic val = json.decode(res.body);
  //   _localRenderer.setRemoteDescription(RTCSessionDescription(val['sdp'], val['type']));
  //   print("chlorine" + res.body);
  //   } catch (e) {
  //     s.currentState.showSnackBar(SnackBar(
  //       content: Text(e.toString()),
  //     ));
  //   }
  // }

  @override
  deactivate() {
    super.deactivate();
    if (_inCalling) {
      _hangUp();
    }
  }

  // initRenderers() async {
  //   await _localRenderer.initialize();
  // }

  // Platform messages are asynchronous, so we initialize in an async method.
  _makeCall() async {
    invoke();
    // final Map<String, dynamic> mediaConstraints = {
    //   "audio": true,
    //   "video": false
    // };

    // try {
    //   var stream = await navigator.getUserMedia(mediaConstraints);
    //   _localStream = stream;
    //   _localRenderer.srcObject = _localStream;
    // } catch (e) {
    //   print(e.toString());
    // }
    // if (!mounted) return;

    // setState(() {
    //   _inCalling = true;
    // });
  }

  _hangUp() async {
    // try {
    //   await _localStream.dispose();
    //   _localRenderer.srcObject = null;
    // } catch (e) {
    //   print(e.toString());
    // }
    // setState(() {
    //   _inCalling = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: s,
      appBar: new AppBar(
        title: new Text('GetUserMedia API Test'),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              height: 200,
              width: 100,
              child: Column(
                children: [
                  Container(height: 100, width: 100, child: RTCVideoView(_localcontainer)),
                  Container(height: 100, width: 100, child: RTCVideoView(_remoteContainer))
                ]
              )
            )
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _makeCall,
        tooltip: _inCalling ? 'Hangup' : 'Call',
        child: new Icon(_inCalling ? Icons.call_end : Icons.phone),
      ),
    );
  }
}
