# Scanning Data with the Camera in SwiftUI
WWDC22 brings brilliant **Live Text** data scanning tools which let users scan text and codes with the camera, similar to the Live Text interface in the Camera app for iOS and iPadOS developers. In this article, I will focus on the new API which called `DataScannerViewController` and share my experience of how to embed this `UIKit` API into your `SwiftUI` code. The following photo shows today's demo.
![](https://github.com/HuangRunHua/ScanningDataCamera/raw/main/intro.jpg)

## Provide a reason for using the camera
Because this demo app can only be running in real world device, so to access users' camera you'd better provide a clear statement of why you need to access their camera.

You provide the reason for using the camera in the Xcode project configuration. Add the NSCameraUsageDescription key to the target's Information Property List in Xcode.

The following steps I provide come from Apple's official document: Scanning data with the camera.
- In the project editor, select the target and click Info.
- Under Custom iOS Target Properties, click the Plus button in any row.
- From the pop-up menu in the Key column, choose Privacy - Camera Usage Description.
- In the Value column, enter the reason, such as "Your camera is used to scan text and codes."

## Creating a Main View
In your `ContentView.swift` file, add following code:
```swift
VStack {
    Text(scanResults)
        .padding()
    Button {
        // Enable Scan Document Action
    } label: {
        Text("Tap to Scan Documents")
            .foregroundColor(.white)
            .frame(width: 300, height: 50)
            .background(Color.blue)
            .cornerRadius(10)
    }
}
```

Where `scanResult` is a `String` variable which represents the camera scan result that will use to illustrate what the camera see during scanning.

```swift
@State private var scanResults: String = ""
```

Button here is used to present the scanning view. When someone taps the button, the device will be ready to scan data. However, not all devices support this function. Or even when the device supports scan data, when the user deny to provide the camera usage permission, things may failed when tapping the button.

In this case, I will provide an alert view which shows a message when the device is not capable for scanning data.
```swift
@State private var showDeviceNotCapacityAlert = false
```

The code above provides a variable to choose whether shows the alert view or not. If `showDeviceNotCapacityAlert` is true, then shows the alert view. Add the following code behind the `VStack` code.
```swift
.alert("Scanner Unavailable", isPresented: $showDeviceNotCapacityAlert, actions: {})
```

Finally when the device is ready for scanning data, we need to present a scanning view, like above code, add the following code to your ContentView.swift file.
```swift
@State private var showCameraScannerView = false
var body: some View {
    VStack {
        ...
    }
    .sheet(isPresented: $showCameraScannerView) {
        // Present the scanning view
    }
    ...
}
```

Now thing what we left is when we tap the button, if the device is not capable for scanning data, an alert view will show. We use isDeviceCapacity to check the whether the device can use this function or not.
```swift
@State private var isDeviceCapacity = false
```

Now add the follow code inside the Button action:
```swift
if isDeviceCapacity {
    self.showCameraScannerView = true
} else {
    self.showDeviceNotCapacityAlert = true
}
```

## Create a Camera Scanner View
Create a new swift file and named it `CameraScanner.swift`. Add the following code here:
```swift
struct CameraScanner: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            Text("Scanning View")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
self.presentationMode.wrappedValue.dismiss()
                        } label: {
                              Text("Cancel")
                        }
                    }
                }
                .interactiveDismissDisabled(true)
        }
    }
}
```

## Handle when the scanner becomes unavailable
When the app is opened by users, we need to check whether the scanner is available or not. Simply add the following code then this app is opened:
```swift
var body: some View {
    VStack {
        ...
    }
    .onAppear {
        isDeviceCapacity = (DataScannerViewController.isSupported && DataScannerViewController.isAvailable)
    }
    ...
}
```
Only if above convenience property that checks both values returns true we can open the scanning view.

## Create a data scanner view controller
To implement a view controller that can be used in a SwiftUI View, first of all we need to use UIViewControllerRepresentable to wrap a UIKit view controller so that it can be used inside SwiftUI. Create a new Swift file named CameraScannerViewController.swift and simply add the following code here:
```swift
import SwiftUI
import UIKit
import VisionKit
struct CameraScannerViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController =  DataScannerViewController(recognizedDataTypes: [.text()],qualityLevel: .fast,recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false, isHighlightingEnabled: true)
        return viewController
    }
    func updateUIViewController(_ viewController: DataScannerViewController, context: Context) {}
}
```

The above code returns a view controller which provides the interface for scanning items in the live video. In this article, I will only focus on scanning text data so the recognizedDataTypes here only contains `.text()` property.

## Handle Delegate protocol
After creating the view controller and before we present it, set its delegate to an object in this app that handles the `DataScannerViewControllerDelegate` protocol callbacks.

In UIKit it's easy to write the following code:
```swift
viewController.delegate = self
```

Luckily, it can be very convenient to handle the `DataScannerViewControllerDelegate` in SwiftUI.

SwiftUI's coordinators are designed to act as delegates for UIKit view controllers. Remember, "delegates" are objects that respond to events that occur elsewhere. For example, UIKit lets us attach a delegate object to its text field view, and that delegate will be notified when the user types anything, when they press return, and so on. This meant that UIKit developers could modify the way their text field behaved without having to create a custom text field type of their own. So add the following code inside the `CameraScannerViewController`:
```swift
func makeCoordinator() -> Coordinator {
    Coordinator(self)
}
class Coordinator: NSObject, DataScannerViewControllerDelegate {
    var parent: CameraScannerViewController
    init(_ parent: CameraScannerViewController) {
        self.parent = parent
    }
}
```
Now we can use the similar code inside `makeUIViewController` just on the top of the return code:
```swift
func makeUIViewController(context: Context) -> DataScannerViewController {
    ...
    viewController.delegate = context.coordinator
    return viewController
}
```

## Begin data scanning
It's time to start the data scanning. Once the user allows access to the camera without restrictions, you can begin scanning for items that appear in the live video by invoking the `startScanning()` method. In this case, when the scanning view is presented we will need the view to perform scanning action.
We need a value to tell the scanning view to scan, add the following code to the `CameraScannerViewController` :
```swift
@Binding var startScanning: Bool
```

When the startScanning's value is set to true, we need to update `UIViewController` and start scanning, add the following code inside `updateUIViewController`:
```swift
func updateUIViewController(_ viewController: DataScannerViewController, context: Context) {
    if startScanning {
        try? viewController.startScanning()
    } else {
        viewController.stopScanning()
    }
}
```

## Respond when we tap an item
When we tap a recognized item in the live video, the view controller invokes the `dataScanner(_:didTapOn:)` delegate method and passes the recognized item. Implement this method to take some action depending on the item the user taps. Use the parameters of the RecognizedItem enum to get details about the item, such as the bounds.

In this case, to handle when we tap a text that the camera recognized, implement the `dataScanner(_:didTapOn:)` method to perform an action that shows the result in the screen. So add the following code inside Coordinator class:
```swift
class Coordinator: NSObject, DataScannerViewControllerDelegate {
    ...
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
            case .text(let text):
                parent.scanResult = text.transcript
            default:
                break
        }
    }
}
```

And add a `Binding` property inside `CameraScannerViewController` :
```swift
@Binding var scanResult: String
```

## Scan Now
It's time to update the `CameraScanner.swift` file. Simply add the following code:
```swift
@Binding var startScanning: Bool
@Binding var scanResult: String
```

And change the `Text("Scanning View")` to the following code:
```swift
var body: some View {
    NavigationView {
        CameraScannerViewController(startScanning: $startScanning, scanResult: $scanResult)
        ...
    }
}
```
Finally, add the following code to `ContentView` : 
```swift
struct ContentView: View {
    ...
    @State private var scanResults: String = ""
    var body: some View {
        VStack {
            ...
        }
        .sheet(isPresented: $showCameraScannerView) {
            CameraScanner(startScanning: $showCameraScannerView, scanResult: $scanResults)
        }
        ...
    }
}
```

`scanResults` is used to pass the value through views. Once the camera scan something, `scanResults` will be updated and then update the `Text` view.
Now run this project and enjoy yourself 😀.
