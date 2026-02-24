[![CI](https://github.com/samdouble/biblio/actions/workflows/checks.yml/badge.svg)](https://github.com/samdouble/biblio/actions/workflows/checks.yml)

**App**
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=ffffff)](https://flutter.dev/)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![iOS](https://img.shields.io/badge/iOS-000000?&logo=apple&logoColor=white)](https://developer.apple.com/ios/)

**Backend**
[![Go](https://img.shields.io/badge/Go-%2300ADD8.svg?&logo=go&logoColor=white)](https://go.dev/)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-%234285F4.svg?logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![DigitalOcean](https://img.shields.io/badge/DigitalOcean-%230167ff.svg?logo=digitalOcean&logoColor=white)](https://www.digitalocean.com/)

# biblio

A cross-platform mobile app to keep track of your books.

## Development

### App

#### Set up environment variables

Create an `.env` file at the root of the project:

```
BIBLIO_API_URL=
DIGITALOCEAN_WEBSECURE_TOKEN=
```

#### Install Flutter SDK and its dependencies

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

#### Run the app

If you are using a hardware device, make sure Developer Mode is enabled on your device and that you have USB debugging enabled.

In VSCode/Cursor, search for `Flutter: Select Device` and select your device. Then, in the `Run & Debug` pane, select `biblio` and click the green play button.

Shortly after, you should see the app running on your device.

### Backend

#### Set up environment variables

Create a `.env` file with the following variables:

```
GOOGLE_BOOKS_API_TOKEN=
MONGO_DBNAME=
MONGO_URL=
```

#### Instantiate the MongoDB replica set

```sh
docker compose up -d
```

Build the Docker image:

```sh
docker build -t biblio-api .
```

Run the Docker container with the book's ISBN as a command line argument:

```sh
docker run --env-file .env --network biblio-api_default -e "MONGO_URL=mongodb://biblio-api-mongo0:27017,biblio-api-mongo1:27017,biblio-api-mongo2:27017/?replicaSet=rs0" biblio-api <isbn>
```
