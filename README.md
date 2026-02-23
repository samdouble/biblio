[![CI](https://github.com/samdouble/biblio/actions/workflows/checks.yml/badge.svg)](https://github.com/samdouble/biblio/actions/workflows/checks.yml)

[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=ffffff)](https://flutter.dev/)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![iOS](https://img.shields.io/badge/iOS-000000?&logo=apple&logoColor=white)](https://developer.apple.com/ios/)

# biblio

A cross-platform mobile app to keep track of your books.

## Development

### Set up environment variables

Create an `.env` file at the root of the project:

```
BIBLIO_API_URL=
DIGITALOCEAN_WEBSECURE_TOKEN=
```

### Install Flutter SDK and its dependencies

Follow the [official documentation](https://docs.flutter.dev/get-started/quick).

On macOS, that means installing:
- Flutter SDK
- XCode
- CocoaPods

For managing multiple Flutter SDK versions, you can use FVM.

```bash
brew tap leoafarias/fvm
brew install fvm
```

Run `fvm flutter doctor` to verify that everything is installed correctly.
Make sure you have the correct version of Flutter installed by running these commands from the root of the project:

```bash
fvm use 3.27.4
fvm flutter --version
```

### Run the app

If you are using a hardware device, make sure Developer Mode is enabled on your device and that you have USB debugging enabled.

In VSCode/Cursor, search for `Flutter: Select Device` and select your device. Then, in the `Run & Debug` pane, select `biblio` and click the green play button.

Shortly after, you should see the app running on your device.
