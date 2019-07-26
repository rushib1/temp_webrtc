package com.example.temp_webrtc;

import android.app.Service;
import android.content.Intent;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.google.firebase.auth.FirebaseAuth;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "sample.flutter.dev/sample";

    @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        switch (call.method) {
                            case "method":
                                FirebaseAuth myFirebaseRef = new FirebaseAuth("FirebaseURL");
                                result.success(true);
                                return;
                            default:
                                result.notImplemented();
                        }
                    }
                });
  }
}
//
//public class ChildEventListener extends Service {
//    @Override
//    public IBinder onBind(Intent intent) {
//        return null;
//    }
//    @Override
//    public int onStartCommand(Intent intent, int flags, int startId) {
//        //Adding a childevent listener to firebase
//        Firebase myFirebaseRef = new Firebase("FirebaseURL");
//        myFirebaseRef.child("FIREBASE_LOCATION").addValueEventListener(new ValueEventListener() {
//
//            @Override
//            public void onDataChange(DataSnapshot snapshot) {
//                //Do something using DataSnapshot say call Notification
//            }
//
//            @Override
//            public void onCancelled(FirebaseError error) {
//                Log.e("The read failed: ", error.getMessage());
//            }
//        });
//
//    }
//
//    @Override
//    public void onCancelled(FirebaseError firebaseError) {
//        Log.e("The read failed: ", firebaseError.getMessage());
//    }
//});
//
//        return START_STICKY;
//        }
//
//        }
