//
//  ContentView.swift
//  ScanningDataCamera
//
//  Created by Runhua Huang on 2022/6/8.
//

import SwiftUI
import VisionKit

struct ContentView: View {
    
    @State private var showCameraScannerView = false
    @State private var isDeviceCapacity = false
    @State private var showDeviceNotCapacityAlert = false
    @State private var scanResults: String = ""
    
    var body: some View {
        VStack {
            Text(scanResults)
                .padding()
            
            Button {
                if isDeviceCapacity {
                    self.showCameraScannerView = true
                } else {
                    self.showDeviceNotCapacityAlert = true
                }
            } label: {
                Text("Tap to Scan Documents")
                    .foregroundColor(.white)
                    .frame(width: 300, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showCameraScannerView) {
            CameraScanner(startScanning: $showCameraScannerView, scanResult: $scanResults)
        }
        .alert("Scanner Unavailable", isPresented: $showDeviceNotCapacityAlert, actions: {})
        .onAppear {
            isDeviceCapacity = (DataScannerViewController.isSupported &&
                                DataScannerViewController.isAvailable)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//if isDeviceCapacity {
//            self.showCameraScannerView = true
//        } else {
//            self.showDeviceNotCapacityAlert = true
//        }
